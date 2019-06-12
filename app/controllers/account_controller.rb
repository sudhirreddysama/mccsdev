class AccountController < ApplicationController
	
	skip_before_filter :authenticate, :except => :edit
	skip_before_filter :block_agency_users
	layout 'login', :except => [:edit, :switch]
		
	def index
		redirect_after_login and return if @current_user
		if request.post?
			if params[:login]
				@login = params[:login]
				u = User.authenticate @login[:username], @login[:password]
				if u
					session[:current_user_id] = u.id
					if u.reset_password || u.password_set_at.nil? || Time.now > u.password_set_at.advance(:months => 6)
						session[:reset_password] = true
					end
					login_hook u
					session[:switch_user_ids] = ([u.id] + u.switch_user_ids).uniq
					flash[:notice] = session[:reset_password] ? 'Your password has expired. Please enter a new password below.' : 'You have successfully logged in.'
					@current_user = u
					redirect_after_login
					return
				else
					@errors = ['Invalid login.']
				end
			elsif params[:lost]
				@lost = params[:lost]
				if @lost[:username].blank?
					@errors = ['Enter a username or email address.']
					return
				end
				users = User.find :all, :conditions => ['level != "disabled" and (username = ? or email = ?)', @lost[:username], @lost[:username]]
				if !users.empty?
					users.each { |u|
						u.create_activation_key
						Notifier.deliver_lost_password u, url_for(:action => :recover, :id => u.id, :id2 => u.activation_key)
					}
					if users.size > 1
						redirect_to
						flash[:notice] = 'You have multiple accounts in the system. Account recovery emails for each of your accounts has been sent to your email address. Click the recovery links in the emails to recover your account.'
					else
						redirect_to :action => :recover, :id => users.first.id
					end
					return
				else
					@errors = ['Sorry, We don\'t have any user on file with that username or email.']
				end
			end
		end
	end
	
	def formatta
		if request.post?
			user = params[:u]
			pass = params[:p]
			if !user.blank? && !pass.blank?
				p = Person.find(:first, :conditions => ['formatta_user = ? and formatta_pass = sha1(concat(?, formatta_salt))', user, pass])
				if p
					render :json => {
						:first_name => p.first_name,
						:last_name => p.last_name,
						:personnel_area_no => p.personnel_area_no,
						:personnel_area_name => p.personnel_area_name,
						:personnel_division_name => p.personnel_division_name
					}.to_json
					return
				end
			end
		end
		render :nothing => true
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
	
	def password
		@obj = @current_user
		if request.post?
			@obj.attributes = params[:obj]
			@obj.resetting_password = true
			if @obj.save
				flash[:notice] = 'Your password has been updated.'
				session.delete :reset_password
				redirect_after_login
			end
		end
	end
	
	def recover
		if params[:id2]
			if params[:id2].blank?
				@errors = ['Invalid key - user not found.']
			else
				u = User.authenticate_by_activation_key params[:id], params[:id2]
				if u
					session[:current_user_id] = u.id
					session[:reset_password] = true
					login_hook u
					@current_user = u		
					flash[:notice] = 'Account recovery successfull. You have been automatically logged in. Please update your account with a new password.'
					redirect_after_login
					return
				else
					@errors = ['Invalid key - user not found.']
				end
			end
    end
	end
	
	def edit
		@obj = @current_user
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'Your account has been updated.'
			default_redirect
		else 
			render :layout => 'application'
		end
	end
	
	def logout
		reset_session
		flash[:notice] = 'You have successfully logged out.'
		redirect_to :controller => :account, :action => :index
	end
	
	private
	
	def redirect_after_login
		if session[:after_login]
			redirect_to session[:after_login]
			session[:after_login] = nil
		else
			default_redirect
		end
	end
	
	def default_redirect
		if session[:reset_password]
			redirect_to :action => :password
		elsif @current_user.liaison_level? || @current_user.view_only?
			redirect_to :controller => :employee
		#elsif @current_user.only_vacancy
		#	redirect_to :controller => :vacancy
		elsif @current_user.agency_level?
			redirect_to :controller => :agencies
		else
			redirect_to :controller => :exam
		end
	end

	def login_hook u
#		if u.id == 328
#			Notifier.deliver_login_notice u
#		end
	end

end