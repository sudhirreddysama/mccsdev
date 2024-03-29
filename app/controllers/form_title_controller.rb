class FormTitleController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.agency_level? && @current_user.perm_ag_form_titles
		render_nothing and return false
	end
	before_filter :check_access

	def index
		@filter = get_filter({
			:sort1 => 'form_titles.created_at',
			:dir1 => 'desc'
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
			@filter.agency_id = @current_user.agency_id if !@current_user.agency_id.blank?
			@filter.department_id = @current_user.department_id if !@current_user.department_id.blank?
			@filter.division_id = @current_user.division_id if !@current_user.division_id.blank?
		end
		if !@filter.department_id.blank?
			@filter.department_id = @filter.department_id.to_i
			cond << 'form_titles.department_id = %d' % @filter.department_id
		end
		if !@filter.agency_id.blank?
			@filter.agency_id = @filter.agency_id.to_i
			cond << 'form_titles.agency_id = %d' % @filter.agency_id
		end
		if !@filter.division_id.blank?
			@filter.division_id = @filter.division_id.to_i
			cond << 'form_titles.division_id = %d' % @filter.division_id
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
			@obj.division = @current_user.division if @current_user.division
		end
		if !request.post? && @obj.agency
			@obj.department = Department.find_by_name @obj.agency.name
		end
		@obj.user = @current_user
		@obj.status = 'started'
	end
	
	def memo
		load_obj
		@obj.skip_validation = true
		edit
	end
	
	def view
		@obj.status_notify = [@obj.user, @obj.submitter].reject(&:blank?).map(&:email).uniq.join(',')
		if request.post?
			@obj.status_user = @current_user
			@obj.status_date = Time.now.to_date
			old_status = @obj.status
			@obj.update_attributes params[:obj]
			flash[:notice] = 'Status has been updated.'
			#u = @obj.user #@obj.agency ? @obj.agency.get_users(@obj.department) : nil
			u2 = @obj.status_notify.to_s.split(',').reject(&:blank?).collect { |e| {:email_with_name => e.strip} }
			#u2 = @obj.submitter
			if !u2.empty? #u2
				Notifier.deliver_form_status u2, @obj
			end
			redirect_to
		else
			super
		end
	end
	
	
	
	
	
	def submit
		load_obj
		@obj.http_posted = true
		if !@obj.valid?
			flash[:errors] = ['Before this form is submitted the following errors must be resolved.'] + @obj.errors.full_messages
			redirect_to :action => :edit, :id => @obj.id
			return
		end
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