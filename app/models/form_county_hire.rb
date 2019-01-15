class FormCountyHire  < ActiveRecord::Base

	belongs_to :agency
	belongs_to :department
	belongs_to :division
	belongs_to :user
#	belongs_to :cert
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	belongs_to :vacancy, :class_name => 'Vacancy', :foreign_key => 'vacancy_no', :primary_key => 'exec_approval_no'
	
#	belongs_to :present_title_job, :class_name => 'Job', :foreign_key => 'present_title_id'
#	belongs_to :demotion_title_job, :class_name => 'Job', :foreign_key => 'demotion_title_id'
#	belongs_to :promotion_new_title_job, :class_name => 'Job', :foreign_key => 'promotion_new_title_id'
#	belongs_to :title_change_new_title_job, :class_name => 'Job', :foreign_key => 'title_change_new_title_id'
	
	has_many :documents
#	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'
	
	validates_presence_of(
		:agency, :department,
		:name, :county_org_no, :org_no, :cost_center, :position, :position_no, :effective_date,
		:vacancy_no, :address,
		:address_city, :address_state, :address_zip,
		:email, :phone, :salary_group, :salary_step, :hourly_rate, :normal_biweekly_hours,
		:classification, :civil_service_status, :job_code, :list_no, :work_schedule_code, :benefits_date, :drug_test_date, :birth_date, :ssn, :time_admin_code,
		:if => :http_posted
	)
	validates_presence_of :flsa_exempt, :if => Proc.new { |o| o.http_posted && o.flsa_exempt.nil? }
	validates_presence_of :physical_required, :if => Proc.new { |o| o.http_posted && o.physical_required.nil? }
	validates_presence_of :physical_date, :if => Proc.new { |o| o.http_posted && o.physical_required }
	
	def employee; nil; end
	
	def label; "330 #{name_was}"; end
	
	def form_type; '330C'; end
	
	attr :check_validation, true
	def validate
		if !check_validation
			return
		end
# 		if change_demotion
# 			errors.add_to_base 'Please enter all required fields for Demotion' if !demotion_title_job || demotion_salary.blank? || demotion_salary_per.blank? || demotion_class.blank? || demotion_status.blank? || demotion_job_time.blank?
# 		end
# 		if change_loa
# 			errors.add_to_base 'Please enter all required fields for Leave of Absence' if loa_reason.blank? || loa_with_pay.nil? || loa_date_from.blank? || loa_date_to.blank?
# 		end
# 		if change_name
# 			errors.add_to_base 'Please enter all required fields for Name Change' if name_change_from.blank? || name_change_to.blank?
# 		end
# 		if change_perm_appt
# 			errors.add_to_base 'Please enter all required fields for Perm. CS Appt.' if perm_appt_list_no.blank? || perm_appt_score.blank?
# 		end
# 		if change_promotion
# 			errors.add_to_base 'Please enter all required fields for Promotion' if !promotion_new_title_job || promotion_salary.blank? || promotion_salary_per.blank? || promotion_class.blank? || promotion_status.blank? || promotion_job_time.blank?
# 		end
# 		if change_salary
# 			errors.add_to_base 'Please enter all required fields for Salary Change' if salary_change_from.blank? || salary_change_to.blank? || salary_change_from_per.blank? || salary_change_to_per.blank?
# 		end
# 		if change_second_provisional
# 			errors.add_to_base 'Please enter all required fields for 2nd Prov. Appt.' if second_provisional_date.blank?
# 		end
# 		if change_separation
# 			errors.add_to_base 'Please enter all required fields for Separation' if separation_date.blank? || separation_reason.blank?
# 		end
# 		if change_status
# 			errors.add_to_base 'Please enter all required fields for Status/Class Change' if status_type.blank? || status_class.blank?
# 		end
# 		if change_suspension
# 			errors.add_to_base 'Please enter all required fields for Suspension' if suspension_reason.blank? || suspension_with_pay.nil?
# 		end
# 		if change_title
# 			errors.add_to_base 'Please enter all required fields for Title Change' if !title_change_new_title_job || title_change_class.blank? || title_change_status.blank? || title_change_job_time.blank?
# 		end
	end
	
	def is_provisional?
		civil_service_status == 'PROVISIONAL' || civil_service_status == 'PROVISIONAL-2ND'
	end

# 	def set_job_text
# 		if present_title_job
# 			self.present_title = present_title_job.name
# 		else		
# 			self.present_title = ''
# 		end
# 		if demotion_title_job
# 			self.demotion_title = demotion_title_job.name
# 		else
# 			self.demotion_title = ''
# 		end
# 		if promotion_new_title_job
# 			self.promotion_new_title = promotion_new_title_job.name
# 		else
# 			self.promotion_new_title = ''
# 		end
# 		if title_change_new_title_job
# 			self.title_change_new_title = title_change_new_title_job.name
# 		else
# 			self.title_change_new_title = ''
# 		end
# 	end
# 	before_save :set_job_text
	
	include DbChangeHooks
	
end