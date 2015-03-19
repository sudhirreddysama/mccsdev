class FacebookController < ApplicationController

	def get_oauth
		@oauth = Koala::Facebook::OAuth.new('1549656988650169', 'cca686f8fc318d3dc81a5432c11176b9', url_for(:action => :oauth))
	end

	def index
		get_oauth
		redirect_to @oauth.url_for_oauth_code
	end
	
	def oauth
		get_oauth
		access_token = @oauth.get_access_token(code)
		graph = Koala::Facebook::API.new(access_token)
		System.find(:first).update_attribute(:facebook_code, params[:code])
		render :text => 'Facebook Authorization Successful'
	end

end