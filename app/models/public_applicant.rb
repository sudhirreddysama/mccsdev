class PublicApplicant < ActiveRecord::Base

	belongs_to :person, :class_name => 'PublicPerson', :foreign_key => 'person_id'
	belongs_to :exam, :class_name => 'PublicExam', :foreign_key => 'exam_id'
	belongs_to :app_status
		
	belongs_to :agency
	belongs_to :department
		
	has_many :list_notes, :class_name => 'PublicListNote', :foreign_key => 'applicant_id'

	has_many :cert_applicants, :class_name => 'PublicCertApplicant', :foreign_key => 'applicant_id'

end