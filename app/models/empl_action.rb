class EmplAction  < ActiveRecord::Base

	belongs_to :empl_action_type
	belongs_to :employee
	belongs_to :department
	belongs_to :agency
	belongs_to :job
	
	validates_presence_of :action_date, :job, :department, :agency, :empl_action_type
	
	def label; "#{action_date.d0?} #{empl_action_type ? empl_action_type.name : 'UNKNOWN'}"; end
	
	def employee_set_first_last_action
		employee.set_first_last_action if employee
	end
	after_save :employee_set_first_last_action
	after_destroy :employee_set_first_last_action
	
	include DbChangeHooks
	
end