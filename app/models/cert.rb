class Cert < ActiveRecord::Base

	belongs_to :exam
	belongs_to :department
	belongs_to :agency
	belongs_to :job
	belongs_to :school_district
	belongs_to :county
	belongs_to :town
	belongs_to :village
	belongs_to :fire_district
	belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
	belongs_to :recert_from, :class_name => 'Cert', :foreign_key => 'recert_from_id'
	has_many :recerts, :class_name => 'Cert', :foreign_key => 'recert_from_id'
	
	has_many :cert_applicants, :dependent => :destroy
	has_many :bulk_messages
	
	has_many :documents
	
	has_many :applicants, :through => :cert_applicants
	
	has_many :notices
	
	validates_presence_of :agency, :exam
	validates_presence_of :temp_duration, :if => Proc.new { |c| c.job_type == 'T' && c.agency_submit }
	validates_presence_of :requestor, :number_of_positions, :request_type, :job_time, :job_type, :general_or_residential, :salary_range
	
	def agency_submit
		if Thread.current[:current_user]
			return Thread.current[:current_user].agency_level?
		end
	end
	
	def label; title_was; end
	
	def exam_no; exam ? exam.exam_no : nil; end
	
	def exam_no=v; self.exam = Exam.find_by_exam_no v; end
	
	def status
		n = Time.now.to_date
		if return_date && return_date < n
			if completed_date 
				return finished.blank? ? 'completed' : 'expired'
			else
				return 'overdue'
			end
		elsif !finished.blank?
			return 'finished'
		elsif completed_date && completed_date <= n
			return 'completed'
		elsif certification_date && certification_date <= n
			return 'certified'
		elsif pending_date
			return 'pending'
		else
			return 'requested'
		end
	end
	
	def set_title		
		self.job_id = exam ? exam.job_id : nil
		self.title = [agency ? agency.name : 'UNKONWN AGENCY', department ? department.abbreviation : ' ', job ? job.name : 'UNKNOWN TITLE' ,exam ? exam.exam_no : 'UNKOWN EXAM' ].reject(&:blank?).join(', ')
	end
	before_save :set_title
	
	include DbChangeHooks
	
end