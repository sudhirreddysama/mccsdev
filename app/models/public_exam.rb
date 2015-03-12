class PublicExam < ActiveRecord::Base

	has_many :applicants, :class_name => 'PublicApplicant', :foreign_key => 'exam_id'
	
	has_many :certs, :class_name => 'PublicCert', :foreign_key => 'exam_id'
	
	belongs_to :current_exam, :class_name => 'PublicExam', :foreign_key => :current_exam_id
	belongs_to :original_exam, :class_name => 'PublicExam', :foreign_key => :original_exam_id
	
	has_many :past_exams, :class_name => 'PublicExam', :foreign_key => :current_exam_id
	has_many :later_exams, :class_name => 'PublicExam', :foreign_key => :original_exam_id	
	
	has_many :bulk_messages
	
	has_one :bandscore

end