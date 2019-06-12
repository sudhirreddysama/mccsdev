class FormCountyHire  < ActiveRecord::Base

	belongs_to :agency
	belongs_to :department
	belongs_to :division
	belongs_to :user
#	belongs_to :cert
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	belongs_to :vacancy
	belongs_to :applicant
	belongs_to :cert
	belongs_to :position_data, :class_name => 'VacancyData', :foreign_key => 'position_no', :primary_key => 'position_no'
	
#	belongs_to :present_title_job, :class_name => 'Job', :foreign_key => 'present_title_id'
#	belongs_to :demotion_title_job, :class_name => 'Job', :foreign_key => 'demotion_title_id'
#	belongs_to :promotion_new_title_job, :class_name => 'Job', :foreign_key => 'promotion_new_title_id'
#	belongs_to :title_change_new_title_job, :class_name => 'Job', :foreign_key => 'title_change_new_title_id'
	
	has_many :documents
#	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'
	
	validates_presence_of(
		:agency, :department,
		:first_name, :last_name, :county_org_no, :org_no, :cost_center, :position, :position_no, :effective_date,
		:vacancy_no, :address,
		:address_city, :address_state, :address_zip,
		:email, :phone, :phone2, :salary_group, :salary_step, :normal_biweekly_hours,
		:classification, :civil_service_status, :job_code, :list_no, :work_schedule_code, :ssn, :gender, #:time_admin_code,
		:hourly_rate, :biweekly_rate,
		:if => :check_validation
	)
	#validates_presence_of :flsa_exempt, :if => Proc.new { |o| o.http_posted && o.flsa_exempt.nil? }
	validates_presence_of :physical_required, :if => Proc.new { |o| o.check_validation && o.physical_required.nil? }
	#validates_presence_of :physical_date, :if => Proc.new { |o| o.http_posted && o.physical_required }

	
	
	def employee; nil; end
	
	def label; "330 #{first_name_was} #{last_name_was}"; end
	
	def name; "#{first_name} #{last_name}"; end
	
	def name_fml; [first_name, middle_name, last_name].reject(&:blank?) * ' '; end
	
	def form_type; '330C'; end
	
	attr :check_validation, true
	def validate
		if !check_validation
			return
		end
	end
	
	def is_provisional?
		['V', 'V2'].include?(civil_service_status)
	end
	
	def funding_rows_filled
		(1..6).to_a.reverse.find { |i| %w(cost_center order_no percent fund grant).find { |f| !send("gp_#{f}#{i}").blank? } } || 0
	end
	
	include DbChangeHooks
	
end