class PublicCert < ActiveRecord::Base

	belongs_to :exam, :class_name => 'PublicExam', :foreign_key => 'exam_id'
	belongs_to :department
	belongs_to :agency
	belongs_to :job
	belongs_to :school_district
	belongs_to :county
	belongs_to :town
	belongs_to :village
	belongs_to :fire_district
	
	has_many :cert_applicants, :class_name => 'PublicCertApplicants', :foreign_key => 'cert_id'

end