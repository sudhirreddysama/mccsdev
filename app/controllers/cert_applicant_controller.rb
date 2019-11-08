class CertApplicantController < CrudController
	
	def options
		params[:popup] = true
		@nonav = true
		super
	end
	
end