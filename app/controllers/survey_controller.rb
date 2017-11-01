class SurveyController < ApplicationController
	
	layout 'mc'
	
	skip_before_filter :force_ssl
	skip_before_filter :authenticate

	def take
		@app = WebApplicant.find(params[:id], :conditions => ['survey_key = ? and submitted_at is not null', params[:id2]])
		@obj = @app.app_survey
		if !@obj
			@obj = @app.build_app_survey params[:obj]
			if request.post? && @obj.save
				flash[:notice] = 'Thank you for taking our survey!'
				redirect_to
			end
		end
	end

end