class FormTitleController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'form_titles.created_at',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'form_titles.id'],
			['Created Date', 'form_titles.created_at'],
			['Effective Date', 'form_titles.effective_date'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name']
		]
		cond = get_search_conditions @filter[:search], {
			'form_titles.id' => :left,
			'agencies.name' => :like,
			'departments.name' => :like,
			'form_titles.present_title' => :like,
			'form_titles.suggested_title' => :like,
			'form_titles.final_title' => :like,
			'form_titles.present_incumbent' => :like
		}
		
		if @current_user.agency_level?
			cond << 'agencies.id = %d' % @current_user.agency_id
			cond << 'departments.id = %d' % @current_user.department_id if @current_user.department_id
		end
		
		@date_types = [
			['Created Date', 'form_titles.created_at'],
			['Effective Date', 'form_titles.effective_date']
		]
		
		cond += get_date_cond
		
		@filter.statuses ||= []		
		if !@filter.statuses.empty?
			s = @filter.statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',')
			cond << 'form_titles.status in (%s)' % s
		end
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department]
		}
		super
	end
	
	def build_obj
		super
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
		end
		if !request.post? && @obj.agency
			@obj.department = Department.find_by_name @obj.agency.name
		end
		@obj.user = @current_user
		@obj.status = 'started'
	end
	
	def memo
		load_obj
		edit
	end
	
	def view
		#@obj.status_notify = @obj.user && @obj.user.email
		if request.post?
			@obj.status_user = @current_user
			@obj.status_date = Time.now.to_date
			@obj.update_attributes params[:obj]
			flash[:notice] = 'Status has been updated.'
			u = @obj.user #@obj.agency ? @obj.agency.get_users(@obj.department) : nil
			u2 = @obj.status_notify.to_s.split(',').reject(&:blank?).collect { |e| {:email_with_name => e.strip} }
			if !u2.empty?
				Notifier.deliver_form_status u2, @obj
			end
			#u2 = @obj.submitter
			#if u2
			#	Notifier.deliver_form_status [u2].reject(&:nil?), @obj
			#end
			redirect_to
		else
			super
		end
	end
	
	def submit
		load_obj
		u = Agency.get_liaison(@obj.agency, @obj.department)
		if u
			Notifier.deliver_form_submitted [u], @obj
		end
		@obj.update_attributes({:status => 'submitted', :submitter_id => @current_user.id, :submitted_at => Time.now})
		redirect_to :action => :view, :id => @obj.id
		flash[:notice] = 'Form has been submitted to HR'
	end
	
	def email_autocomplete
		t = params[:term]
		cond = get_search_conditions params[:term], {'username' => :like, 'name' => :like, 'email' => :like}
		cond << 'level != "disabled"'
		render :json => User.find(:all, :select => 'email', :conditions => get_where(cond), :limit => 10, :group => 'email').collect(&:email).to_json
	end

end