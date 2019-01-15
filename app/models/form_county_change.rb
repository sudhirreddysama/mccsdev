class FormCountyChange  < ActiveRecord::Base

	belongs_to :agency
	belongs_to :department
	belongs_to :division
	belongs_to :user
#	belongs_to :cert
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	belongs_to :vacancy, :class_name => 'Vacancy', :foreign_key => 'vacancy_no', :primary_key => 'exec_approval_no'
	belongs_to :vacancy_data, :class_name => 'VacancyData', :foreign_key => 'position_no', :primary_key => 'position_no'
	
#	belongs_to :present_title_job, :class_name => 'Job', :foreign_key => 'present_title_id'
#	belongs_to :demotion_title_job, :class_name => 'Job', :foreign_key => 'demotion_title_id'
#	belongs_to :promotion_new_title_job, :class_name => 'Job', :foreign_key => 'promotion_new_title_id'
#	belongs_to :title_change_new_title_job, :class_name => 'Job', :foreign_key => 'title_change_new_title_id'
	
	has_many :documents
#	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'
	
	validates_presence_of(:agency, :department, 
		:name, :county_org_no, :org_no, :cost_center, :position, :position_no, :effective_date, :personnel_no,
		:if => :http_posted
	)
	validates_presence_of(
		:present_provisional,
		:if => Proc.new { |o| o.http_posted && o.present_provisional.nil? }
	)
	validates_presence_of(
		:action_out_of_title_replacing, 
		:if => Proc.new { |o| o.http_posted && o.action_out_of_title }
	)
	validates_presence_of(
		:action_title, :action_position_no, :action_group, :action_step, :action_hourly_rate, :action_job_code, :action_list_no,
		:if => Proc.new { |o| o.http_posted && (o.action_promotion || o.action_out_of_title || o.action_title_change || o.action_reinstatement || o.action_demotion || o.action_miscellaneous) }
	)
	validates_presence_of(
		:action_flsa_exempt,
		:if => Proc.new { |o| 
			o.http_posted && (o.action_promotion || o.action_out_of_title || o.action_title_change || o.action_reinstatement || o.action_demotion || o.action_miscellaneous) && 
			o.action_flsa_exempt.nil?
		}
	)
	validates_presence_of(
		:action_class, :action_status,
		:if => Proc.new { |o| o.http_posted && o.action_status_change }
	)
	validates_presence_of(
		:action_perm_appt_list_no,
		:if => Proc.new { |o| o.http_posted && o.action_perm_appt }
	)
	validates_presence_of(
		:action_2nd_provisional_date,
		:if => Proc.new { |o| o.http_posted && o.action_2nd_provisional }
	)
	validates_presence_of(
		:action_hours,
		:if => Proc.new { |o| o.http_posted && o.action_change_hours }
	)
	validates_presence_of(
		:action_special_inc_step, :action_special_inc_rate,
		:if => Proc.new { |o| o.http_posted && o.action_special_increment }
	)
	validates_presence_of(
		:action_separation_date, :action_separation_code,
		:if => Proc.new { |o| o.http_posted && o.action_separation }
	)
	validates_presence_of(
		:action_separation_provisional,
		:if => Proc.new { |o| o.http_posted && o.action_separation && o.action_separation_provisional.nil? }
	)
	validates_presence_of(
		:action_separation_county_org_no, :action_separation_sap_org_no, :action_separation_cost_center,
		:if => Proc.new { |o| o.http_posted && o.action_separation && o.action_separation_code == '03 Retired' }
	)
	validates_presence_of(
		:org_pe_po_co_org_no, :org_pe_po_sap_org_no, :org_pe_po_cost_center,
		:if => Proc.new { |o| o.http_posted && o.org_move_person_position }
	)
	validates_presence_of(
		:org_po_co_org_no, :org_po_co_org_no_from, :org_po_sap_org_no, :org_po_sap_org_no_from, :org_po_cost_center, :org_po_cost_center_from,
		:if => Proc.new { |o| o.http_posted && o.org_move_position }
	)
	validates_presence_of(
		:org_org_co_org_no, :org_org_sap_org_no, :org_org_cost_center, :org_org_position_no,
		:if => Proc.new { |o| o.http_posted && o.org_organization_change }
	)
	validates_presence_of(
		:org_pos_position_no,
		:if => Proc.new { |o| o.http_posted && o.org_new_position }
	)
	validates_presence_of(
		:org_work_sched_code,
		:if => Proc.new { |o| o.http_posted && o.org_new_work_sched_code }
	)
	validates_presence_of(
		:org_time_admin_code,
		:if => Proc.new { |o| o.http_posted && o.org_new_time_admin_code }
	)
	validates_presence_of(
		:org_fund_cost_center1, :org_fund_order_no1, :org_fund_percent1, :org_fund_fund1, :org_fund_grant1,
		:if => Proc.new { |o| o.http_posted && o.org_position_funding }
	)
	validates_presence_of(
		:leave_reason,
		:if => Proc.new { |o| o.http_posted && (o.leave_no_pay || o.leave_paid) }
	)
	validates_presence_of(
		:leave_start_date, :leave_anticipated_return_date,
		:if => Proc.new { |o| 
			o.http_posted && 
			(o.leave_no_pay || o.leave_paid || o.leave_fmla || o.leave_half_pay_sick || o.leave_military || o.leave_section_72 || o.leave_workers_comp || o.leave_section_207c) 
		}
	)
	validates_presence_of(
		:leave_return_date,
		:if => Proc.new { |o| o.http_posted && o.leave_return }
	)
	
	def employee; nil; end
	
	SEPARATION_CODES = [
		'01 Voluntary resignation',
		'02 Deceased',
		'03 Retired',
		'04 Temporary',
		'05 Failed CS examination',
		'06 Not reachable on CS list',
		'07 Failed probationary period',
		'08 Seasonal',
		'09 Abandoned job',
		'10 Family responsibilities',
		'11 Health',
		'12 Layoff',
		'13 Misconduct',
		'14 Personal reasons',
		'15 Work performance',
		'16 Unable to return from LOA',
		'17 Miscellaneous reasons',
		'18 Lost Election/change in County administration',
		'19 Another job',
		'20 Failed Drug Test',
		'21 Section 72',
		'22 Section 73',
		'23 Declined Position',
		'24 Section 71'
	]
	
	def label; "105 #{name_was}"; end
	
	def form_type; '105C'; end
	
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
		prov = false
 		prov ||= present_provisional
 		prov ||= action_status_change && (action_status == 'PROVISIONAL' || action_status == 'PROVISIONAL-2ND')
 		prov ||= action_2nd_provisional
 		prov ||= action_separation && action_separation_provisional
		prov
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