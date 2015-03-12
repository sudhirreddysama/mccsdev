class PublicPerson < ActiveRecord::Base

	belongs_to :school_district
	belongs_to :county
	belongs_to :village
	belongs_to :town
	belongs_to :fire_district
	
	has_many :applicants, :class_name => 'PublicApplicant', :foreign_key => 'person_id'
	has_many :cert_applicants, :class_name => 'PublicCertApplicant', :foreign_key => 'person_id'

end