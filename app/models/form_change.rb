class FormChange  < ActiveRecord::Base

	belongs_to :agency
	belongs_to :department
	belongs_to :user
	belongs_to :employee
	belongs_to :cert
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	belongs_to :present_title_job, :class_name => 'Job', :foreign_key => 'present_title_id'
	belongs_to :demotion_title_job, :class_name => 'Job', :foreign_key => 'demotion_title_id'
	belongs_to :promotion_new_title_job, :class_name => 'Job', :foreign_key => 'promotion_new_title_id'
	belongs_to :title_change_new_title_job, :class_name => 'Job', :foreign_key => 'title_change_new_title_id'
	
	has_many :documents
	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'
	
	validates_presence_of :agency, :department, :first_name, :last_name, :present_title_job, :effective_date, :if => :http_posted
	
	def label; "#105 #{last_name_was}, #{first_name_was}"; end
	
	def form_type; '105'; end
	
	
	def changes_string
		s = []
		s << 'Demotion' if change_demotion
		s << 'Leave of Absence' if change_loa
		s << 'Name Change' if change_name
		s << 'Permananent Civil Service Appointment' if change_perm_appt
		s << 'Promotion' if change_promotion
		s << 'Salary Change' if change_salary
		s << 'Second Provisional Appointment' if change_second_provisional
		s << 'Separation' if change_separation
		s << 'Status' if change_status
		s << 'Suspension' if change_suspension
		s << 'Title Change' if change_title
		return s.join(', ')
	end

	def set_job_text
		if present_title_job
			self.present_title = present_title_job.name
		else		
			self.present_title = ''
		end
		if demotion_title_job
			self.demotion_title = demotion_title_job.name
		else
			self.demotion_title = ''
		end
		if promotion_new_title_job
			self.promotion_new_title = promotion_new_title_job.name
		else
			self.promotion_new_title = ''
		end
		if title_change_new_title_job
			self.title_change_new_title = title_change_new_title_job.name
		else
			self.title_change_new_title = ''
		end
	end
	before_save :set_job_text
	
	include DbChangeHooks
	
end