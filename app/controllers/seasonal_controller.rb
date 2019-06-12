class SeasonalController < ApplicationController

	layout 'mc'
	
	skip_before_filter :authenticate
	skip_before_filter :block_agency_users

	def index
		#send_file 'public/test.pdf', :type => 'application/pdf'
		render :text => 'Done', :type => 'text/plain'
		File.open('some_file.txt','w') {|file| file.puts request.body.read }
		#redirect_to 'http://google.com'
	end

end