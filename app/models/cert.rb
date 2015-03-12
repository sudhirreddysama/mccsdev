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
	
	has_many :cert_applicants, :dependent => :destroy
	has_many :bulk_messages
	
	has_many :documents
	
	has_many :applicants, :through => :cert_applicants
	
	validates_presence_of :agency, :exam
	
	validates_presence_of :months, :general_or_residential, :job_time, :salary_range, :if => :agency_submit
	
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
			return completed_date ? 'expired' : 'overdue'
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
		self.title = [agency ? agency.name : 'UNKONWN AGENCY', department ? department.abbreviation : ' ', job ? job.name : 'UNKNOWN TITLE' ,exam ? exam.exam_no : 'UNKOWN EXAM' ].reject(&:blank?).join(', ')
	end
	before_save :set_title
	
	include DbChangeHooks
	
end