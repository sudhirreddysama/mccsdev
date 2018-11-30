class FormCountyChangeController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'form_county_changes.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'form_county_changes.id'],
			['Created Date', 'form_county_changes.created_at'],
			['Effective Date', 'form_county_changes.effective_date'],
			['First Name', 'form_county_changes.name'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'form_county_changes.id' => :left,
			'agencies.name' => :like,
			'departments.name' => :like,
			'form_county_changes.name' => :like,
		}
		
		if @current_user.agency_level?
			@filter.agency_id = @current_user.agency_id if !@current_user.agency_id.blank?
			@filter.department_id = @current_user.department_id if !@current_user.department_id.blank?
			@filter.division_id = @current_user.division_id if !@current_user.division_id.blank?
		end
		if !@filter.department_id.blank?
			@filter.department_id = @filter.department_id.to_i
			cond << 'form_county_changes.department_id = %d' % @filter.department_id
		end
		if !@filter.agency_id.blank?
			@filter.agency_id = @filter.agency_id.to_i
			cond << 'form_county_changes.agency_id = %d' % @filter.agency_id
		end
		if !@filter.division_id.blank?
			@filter.division_id = @filter.division_id.to_i
			cond << 'form_county_changes.division_id = %d' % @filter.division_id
		end	
		
		@date_types = [
			['Created Date', 'form_county_changes.created_at'],
			['Effective Date', 'form_county_changes.effective_date']
		]
		
		cond += get_date_cond
		
		@filter.statuses ||= []		
		if !@filter.statuses.empty?
			s = @filter.statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',')
			cond << 'form_county_changes.status in (%s)' % s
		end
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department, :employee]
		}
		super
	end
	
	def edit
		@obj.check_validation = true
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
	
	def view
		if request.post?
			@obj.status_user = @current_user
			@obj.status_date = Time.now.to_date
			old_status = @obj.status
			@obj.update_attributes params[:obj]
			flash[:notice] = 'Status has been updated.'
			#u = @obj.user #@obj.agency ? @obj.agency.get_users(@obj.department) : nil
			#u2 = @obj.submitter
			#if u2
			#	Notifier.deliver_form_status [u2].reject(&:nil?), @obj
			#end
			#if @obj.is_provisional? && @obj.status == 'approved' && old_status != @obj.status
			#	Notifier.deliver_form_change_provisional @obj
			#end
			redirect_to
		else
			super
		end
	end
	
	def submit
		load_obj
		#u = Agency.get_liaison(@obj.agency, @obj.department)
		#if u
		#	Notifier.deliver_form_submitted [u], @obj
		#end
		@obj.update_attributes({:status => 'submitted', :submitter_id => @current_user.id, :submitted_at => Time.now})
		redirect_to :action => :view, :id => @obj.id
		flash[:notice] = 'Form has been submitted to HR'
	end

end