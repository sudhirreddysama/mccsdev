class UserController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'users.username',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'users.id'],
			['Username', 'users.username'],
			['Name', 'users.name'],
			['Initials', 'users.initials'],
			['Level', 'users.level'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name']
		]
		cond = get_search_conditions @filter[:search], {
			'users.id' => :left,
			'users.username' => :like,
			'users.name' => :like,
			'users.level' => :like,
			'users.initials' => :like,
			'agencies.name' => :like, 
			'departments.name' => :like 
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department]
		}
		super
	end
	
	def user_flip
		session[:current_user_id] = params[:id]
		render :text => 'flip'
	end
	
	def bulk_email
		if !@current_user.admin_level?
			render :nothing => true
			return
		end
		@errors = []
		if request.post?
			@mail = params.mail
			@errors << 'Subject is required' if @mail.subject.blank?
			@errors << 'Body is required' if @mail.body.blank?
			@errors << 'From is required' if @mail.from.blank?
			emails = @mail.to.to_s.split(/[\r\n,]/).map(&:strip).reject(&:blank?)
			@errors << 'Recipients is required' if emails.empty?
			if @errors.empty?
				emails.each { |e|
					Notifier.deliver_custom_email e, @mail.subject, @mail.from, @mail.body
				}
				flash[:notice] = 'Email Sent!'
				redirect_to
			end
		else
			to = ''
			if flash[:bulk_email_to_tmp_file]
				f = flash[:bulk_email_to_tmp_file]
				to = IO.read f
				File.delete f
			else 
				emails = [] 
				users = User.find(:all, :conditions => 'level != "disabled"', :include => :agency, :group => 'email', :order => 'agencies.agency_type = "COUNTY" desc')
				to = users.map(&:email_with_name).join("\r")
			end
			@mail = {
				:from => @current_user.email_with_name,
				:subject => '',
				:body => '',
				:to => to
			}
		end
	end

end