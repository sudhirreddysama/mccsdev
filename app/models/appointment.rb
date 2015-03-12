class Appointment < ActiveRecord::Base

	belongs_to :employee
	belongs_to :person
	belongs_to :applicant
	belongs_to :exam
	belongs_to :cert
	belongs_to :job
	belongs_to :department
	belongs_to :agency
	
	def label; "Appointment ID #{id}"; end
	
	include DbChangeHooks
	
end