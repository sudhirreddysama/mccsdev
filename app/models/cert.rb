class Cert < ActiveRecord::Base

	belongs_to :exam
	belongs_to :department
	belongs_to :agency
	belongs_to :division
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
	
	def other_open_certs
		return [] if !exam
		et = exam.exam_type
		return [] if !%w(PROM NCP OC).include?(et)
		cond = ['certs.completed_date is null']
		cond << DB.escape('certs.agency_id = %d', agency_id) if agency_id
		cond << DB.escape('certs.department_id = %d', department_id) if department_id
		cond << DB.escape('certs.division_id = %d', division_id) if division_id
		cond << DB.escape('certs.job_id = %d', job_id) if job_id
		cond << DB.escape('certs.id != %d', id) if id
		cond << 'exams.exam_type in ("PROM", "NCP")' if et == 'PROM' || et == 'NCP'
		cond << 'exams.exam_type = "OC"' if et == 'OC'
		return Cert.find(:all, :include => :exam, :conditions => cond.join(' and '), :order => 'certs.id desc')
	end
	
	def other_open_certs_error_attr
		other_open_certs.map { |c| {:id => c.id, :title => c.title, :requested_date => c.requested_date} }
	end
	
	def alt_prom_exams
		return [] if !exam
		return exam.alt_prom_exams(agency, department, division)
	end
	
	def alt_prom_exams_error_attr
		alt_prom_exams.map { |e| {
				:id => e.id, :exam_no => e.exam_no, :title => e.title, :established_date => e.established_date,
				:valid_until => e.valid_until, :applicants_count => e.applicants.length, :exam_type => e.exam_type
			}
		}
	end
	
	def other_open_certs_alt_prom_exams_attr
		{:other_certs => other_open_certs_error_attr, :prom_exams => alt_prom_exams_error_attr}
	end
	
	def autocomplete_json_data
		e = exam
		{
			:id => id,
			:title => title,
			:exam_no => e ? e.exam_no : '',
			:job_type => job_type,
			:job_time => job_time,
			:certification_date => certification_date,
			:requested_date => requested_date
		}
	end
	
	def agency_users_to_notify
		return agency ? agency.get_users(department, division, 'users.show_cert_lists = 1 and users.perm_cert_notices = 1') : []					
	end
	
	def self.cert_overdue_cron
		p "Running Cert Overdue Cron #{Date.today}"
		Cert.find(:all, :conditions => ['return_date = ? and (completed_date is null)', Date.today]).each { |c|
			users = (c.agency_users_to_notify + [Agency.get_liaison(c.agency, c.department)]).compact
			p "Cert Found: #{c.id}, Users: #{users.map(&:username) * ', '}"
			if !users.empty?
				Notifier.deliver_cert_overdue(c, users)
			end
		}
		p 'Done Running Cert Overdue Cron'
	end
	
	include DbChangeHooks
	
end