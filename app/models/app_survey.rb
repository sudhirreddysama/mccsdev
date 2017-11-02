class AppSurvey < ActiveRecord::Base

	belongs_to :web_applicant
	
	QUESTIONS = [	
		'The on-line application process was easy to use.',
		'I will refer a friend or colleague to the website for Monroe County Civil Service.',
		'The civil service staff was informed and courteous. (If you did not have contact with staff please skip this question)',
		'How did you hear about Monroe County Civil Service?',
		'Any additional comments/compliments/suggestions?',
	]
	
	def validate
		errors.add_to_base 'Please answer at least one question.' if [q1, q2, q3, c1, c2].all?(&:blank?)
	end

end