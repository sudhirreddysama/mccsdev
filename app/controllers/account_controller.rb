class AccountController < ApplicationController
	
	skip_before_filter :authenticate, :except => :edit
	layout 'login', :except => [:edit, :switch]
		
	def index
		redirect_after_login and return if @current_user
		if request.post?
			@login = params[:login]
			u = User.authenticate @login[:username], @login[:password]
			if u
				session[:current_user_id] = u.id
				session[:switch_user_ids] = ([u.id] + u.switch_user_ids).uniq
				flash[:notice] = 'You have successfully logged in.'
				@current_user = u
				redirect_after_login
				return
			else
				@errors = ['Invalid login.']
			end
		end
	end
	
	def switch
		if request.post?
			@login = params[:login]
			u = User.authenticate @login[:username], @login[:password]
			if u
				session[:current_user_id] = u.id
				session[:switch_user_ids] ||= []
				session[:switch_user_ids] = (session[:switch_user_ids] + [u.id] + u.switch_user_ids).uniq
				flash[:notice] = "You have successfully logged in as #{u.username}."
				@current_user = u
				default_redirect
				return
			else
				@errors = ['Invalid login.']
			end
		end
		render :action => :index, :layout => 'application'
	end
	
	def switchto
		if session[:switch_user_ids].find(params[:id].to_i)
			u = User.find params[:id]
			session[:current_user_id] = u.id
			session[:switch_user_ids] = (session[:switch_user_ids] + [u.id] + u.switch_user_ids).uniq
			flash[:notice] = "You have successfully switched to user #{u.username}."
			@current_user = u			
			redirect_to :back
		end
	end
	
	def edit
		@obj = @current_user
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'Your account has been updated.'
			redirect_after_login
		else 
			render :layout => 'application'
		end
	end
	
	def logout
		session[:current_user_id] = nil
		flash[:notice] = 'You have successfully logged out.'
		redirect_to :controller => :account, :action => :index
	end
	
	def redirect_after_login
		if session[:after_login]
			redirect_to session[:after_login]
			session[:after_login] = nil
		else
			default_redirect
		end
	end
	
	def default_redirect
		if @current_user.liaison_level? || @current_user.view_only?
			redirect_to :controller => :employee
		elsif @current_user.agency_level?
			redirect_to :controller => :agencies
		else
			redirect_to :controller => :exam
		end
	end

end