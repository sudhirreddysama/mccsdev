class FormCountyChange  < ActiveRecord::Base

	belongs_to :agency
	belongs_to :department
	belongs_to :division
	belongs_to :user
#	belongs_to :cert
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	belongs_to :vacancy
	belongs_to :vacancy_data
	#belongs_to :vacancy_data_new, :class_name => 'VacancyData', :foreign_key => 'vacancy_data_new_id'
	
	#belongs_to :vacancy, :foreign_key => 'vacancy_no', :primary_key => 'exec_approval_no', :conditions => 'vacancies.exec_approval_no != ""'
	
#	belongs_to :present_title_job, :class_name => 'Job', :foreign_key => 'present_title_id'
#	belongs_to :demotion_title_job, :class_name => 'Job', :foreign_key => 'demotion_title_id'
#	belongs_to :promotion_new_title_job, :class_name => 'Job', :foreign_key => 'promotion_new_title_id'
#	belongs_to :title_change_new_title_job, :class_name => 'Job', :foreign_key => 'title_change_new_title_id'
	
	has_many :documents
#	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'
	
	validates_presence_of(:agency, :department, 
		:first_name, :last_name, :county_org_no, :org_no, :cost_center, :position, :position_no, :effective_date, :personnel_no, :vacancy_no,
		:if => :check_validation
	)
	validates_presence_of(
		:present_provisional,
		:if => Proc.new { |o| o.check_validation && o.present_provisional.nil? }
	)
	validates_presence_of(
		:action_out_of_title_replacing, 
		:if => Proc.new { |o| o.check_validation && o.action_out_of_title }
	)
	validates_presence_of(
		:action_title, :action_position_no, :action_group, :action_step, :action_hourly_rate, :action_job_code, :action_list_no,
		:if => Proc.new { |o| o.check_validation && (o.action_promotion || o.action_out_of_title || o.action_title_change || o.action_reinstatement || o.action_demotion || o.action_miscellaneous) }
	)
	validates_presence_of(
		:action_flsa_exempt,
		:if => Proc.new { |o| 
			o.check_validation && (o.action_promotion || o.action_out_of_title || o.action_title_change || o.action_reinstatement || o.action_demotion || o.action_miscellaneous) && 
			o.action_flsa_exempt.nil?
		}
	)
	validates_presence_of(
		:action_class, :action_status,
		:if => Proc.new { |o| o.check_validation && o.action_status_change }
	)
	validates_presence_of(
		:action_perm_appt_list_no,
		:if => Proc.new { |o| o.check_validation && o.action_perm_appt }
	)
	validates_presence_of(
		:action_2nd_provisional_date,
		:if => Proc.new { |o| o.check_validation && o.action_2nd_provisional }
	)
	validates_presence_of(
		:action_hours,
		:if => Proc.new { |o| o.check_validation && o.action_change_hours }
	)
	validates_presence_of(
		:action_special_inc_step, :action_special_inc_rate,
		:if => Proc.new { |o| o.check_validation && o.action_special_increment }
	)
	validates_presence_of(
		:action_separation_date, :action_separation_code,
		:if => Proc.new { |o| o.check_validation && o.action_separation }
	)
	validates_presence_of(
		:action_separation_provisional,
		:if => Proc.new { |o| o.check_validation && o.action_separation && o.action_separation_provisional.nil? }
	)
	#validates_presence_of(
	#	:action_separation_county_org_no, :action_separation_sap_org_no, :action_separation_cost_center,
	#	:if => Proc.new { |o| o.check_validation && o.action_separation && o.action_separation_code == '03 Retired' }
	#)
	validates_presence_of(
		:org_pe_po_co_org_no, :org_pe_po_sap_org_no, :org_pe_po_cost_center,
		:if => Proc.new { |o| o.check_validation && o.org_move_person_position }
	)
	validates_presence_of(
		:org_po_co_org_no, :org_po_co_org_no_from, :org_po_sap_org_no, :org_po_sap_org_no_from, :org_po_cost_center, :org_po_cost_center_from,
		:if => Proc.new { |o| o.check_validation && o.org_move_position }
	)
	validates_presence_of(
		:org_org_co_org_no, :org_org_sap_org_no, :org_org_cost_center, :org_org_position_no,
		:if => Proc.new { |o| o.check_validation && o.org_organization_change }
	)
	validates_presence_of(
		:org_pos_position_no,
		:if => Proc.new { |o| o.check_validation && o.org_new_position }
	)
	validates_presence_of(
		:org_work_sched_code,
		:if => Proc.new { |o| o.check_validation && o.org_new_work_sched_code }
	)
	validates_presence_of(
		:org_time_admin_code,
		:if => Proc.new { |o| o.check_validation && o.org_new_time_admin_code }
	)
	validates_presence_of(
		:org_fund_cost_center1, :org_fund_percent1, :org_fund_fund1, :org_fund_grant1,
		:if => Proc.new { |o| o.check_validation && o.org_position_funding }
	)
	validates_presence_of(
		:leave_reason,
		:if => Proc.new { |o| o.check_validation && (o.leave_no_pay || o.leave_paid) }
	)
	validates_presence_of(
		:leave_start_date, :leave_anticipated_return_date,
		:if => Proc.new { |o| 
			o.check_validation && 
			(o.leave_no_pay || o.leave_paid || o.leave_fmla || o.leave_half_pay_sick || o.leave_military || o.leave_section_72 || o.leave_workers_comp || o.leave_section_207c) 
		}
	)
	validates_presence_of(
		:leave_return_date,
		:if => Proc.new { |o| o.check_validation && o.leave_return }
	)
	validates_presence_of(
		:org_add_in_lieu_of_code,
		:if => Proc.new { |o| o.check_validation && o.org_add_in_lieu_of }
	)
	validates_presence_of(
		:action_union,
		:if => Proc.new { |o| o.check_validation && o.action_union_change }
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
	
	def label; "105 #{first_name_was} #{last_name_was}"; end
	
	def name; "#{first_name} #{last_name}"; end
	
	def name_fml; [first_name, middle_name, last_name].reject(&:blank?) * ' '; end
	
	def form_type; '105C'; end
	
	attr :check_validation, true
	def validate
		if !check_validation
			return
		end
	end
	
	def changes_personnel
		c = []
		c << 'Promotion' if action_promotion
		c << 'Out of Title' if action_out_of_title
		c << 'Title Change' if action_title_change
		c << 'Reinstatement' if action_reinstatement
		c << 'Demotion' if action_demotion
		c << 'Misc. Change' if action_miscellaneous
		c << 'Union Change' if action_union_change
		c << 'Status Change' if action_status_change
		c << 'Perm. Appt.' if action_perm_appt
		c << '2nd Provisional' if action_2nd_provisional
		c << 'Change Hours' if action_change_hours
		c << 'Special Increment' if action_special_increment
		c << 'Separation' if action_separation
		c
	end
	
	def changes_org
		c = []
		c << 'Move Person & Position' if org_move_person_position
		c << 'Move Position' if org_move_position
		c << 'Org. Change' if org_organization_change
		c << 'New Position' if org_new_position
		c << 'Add In Lieu Of' if org_add_in_lieu_of
		c << 'Remove In Lieu Of' if org_remove_in_lieu_of
		c << 'New Work Sched. Code' if org_new_work_sched_code
		c << 'New Time Admin Code' if org_new_time_admin_code
		c << 'Position Funding' if org_position_funding
		c
	end
	
	def changes_leave
		c = []
		c << 'No Pay Leave' if leave_no_pay
		c << 'Paid Leave' if leave_paid
		c << 'FMLA Leave' if leave_fmla
		c << 'Half Pay Sick Leave' if leave_half_pay_sick
		c << 'Military Leave' if leave_military
		c << 'Section 72 Leave' if leave_section_72
		c << 'Work. Comp. Leave' if leave_workers_comp
		c << 'Section 207(c) Leave' if leave_section_207c
		c << 'Return From Leave' if leave_return
		c
	end
	
	def all_changes 
		changes_personnel + changes_org + changes_leave
	end
	
	def is_provisional?
		prov = false
 		prov ||= present_provisional
 		prov ||= action_status_change && ['V', 'V2'].include?(action_status)
 		prov ||= action_2nd_provisional
 		prov ||= action_separation && action_separation_provisional
		prov
	end
	
	def funding_rows_filled
		(1..6).to_a.reverse.find { |i| %w(cost_center order_no percent fund grant).find { |f| !send("org_fund_#{f}#{i}").blank? } } || 0
	end
	
	def self.update_county_form_status_and_notify f, u, attr
		f.status_user = u
		f.status_date = Time.now.to_date
		old_status = f.status
		old_hr_status = f.hr_status
		f.update_attributes attr
		status_changed = old_status != f.status
		hr_status_changed = old_hr_status != f.hr_status
		if status_changed
			emails = [f.user, f.submitter].reject(&:nil?).map(&:email_with_name).uniq
			if !emails.blank?
				Notifier.deliver_county_form_status f, emails, u.email_with_name
			end
		end
		if hr_status_changed
			emails = Notifier.county_form_recipient(f)
			if !emails.blank?
				Notifier.deliver_county_form_hr_status f, emails, u.email_with_name
			end
		end	
	end
	
	include DbChangeHooks
	
end