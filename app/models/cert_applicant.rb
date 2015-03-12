class CertApplicant < ActiveRecord::Base

	belongs_to :applicant
	belongs_to :cert
	belongs_to :cert_code
	belongs_to :person
	
	has_many :documents
	
	def date; 
		cert.certification_date; 
	end
	
	include DbChangeHooks
	
end