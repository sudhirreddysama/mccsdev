class PayCertLine < ActiveRecord::Base
	
	belongs_to :pay_cert
	belongs_to :employee
	belongs_to :empl_action

	def error_text typ
		return '---' if typ == 'employee'
		return "#{employee.last_name}, #{employee.first_name}" if typ == 'name'
		return "#{employee.job.name rescue 'UNKNOWN'}" if typ == 'title'
		return "#{employee.wage}" if typ == 'salary_wage'
		return "#{employee.pension_no}" if typ == 'retirement_no'
		return "#{employee.leave_date.d0?}" if typ == 'leave'
		return "---" if typ == 'no_record'
	end

	include DbChangeHooks
	
end