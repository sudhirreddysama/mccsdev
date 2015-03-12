class PublicListNote < ActiveRecord::Base

	belongs_to :applicant, :class_name => 'PublicApplicant', :foreign_key => 'applicant_id'
	
	def date; note_date; end

end