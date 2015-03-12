class PublicCertApplicant < ActiveRecord::Base

	belongs_to :applicant, :class_name => 'PublicApplicant', :foreign_key => 'applicant_id'
	belongs_to :cert, :class_name => 'PublicCert', :foreign_key => 'cert_id'
	belongs_to :cert_code
	belongs_to :person, :class_name => 'PublicPerson', :foreign_key => 'person_id'
	
	def date
		cert.certification_date; 
	end

end