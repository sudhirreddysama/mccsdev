class AppSurvey < ActiveRecord::Base

	belongs_to :web_applicant
	
	def validate
		errors.add_to_base 'Please answer at least one question.' if [q1, q2, q3, c1, c2].all?(&:blank?)
	end

end