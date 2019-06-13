class FormCountyChangeController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.is_agency_county? && @current_user.perm_ag_form_changes
		render_nothing and return false
	end
	before_filter :check_access

	def index
		@filter = get_filter({
			:sort1 => 'form_county_changes.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'form_county_changes.id'],
			['Created Date', 'form_county_changes.created_at'],
			['Effective Date', 'form_county_changes.effective_date'],
			['First Name', 'form_county_changes.first_name'],
			['Middle Name', 'form_county_changes.middle_name'],
			['Last Name', 'form_county_changes.last_name'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'form_county_changes.id' => :left,
			'agencies.name' => :like,
			'departments.name' => :like,
			'form_county_changes.first_name' => :like,
			'form_county_changes.last_name' => :like,
			'form_county_changes.middle_name' => :like,
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
		cond << 'form_county_changes.status in (%s)' % @filter.statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',') if !@filter.statuses.empty?
		@filter.hr_statuses ||= []		
		cond << 'form_county_changes.status in (%s)' % @filter.hr_statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',') if !@filter.hr_statuses.empty?
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department]
		}
		super
	end
	
	def edit
		@obj.check_validation = true
		super
  end
  
	def new
		@obj.check_validation = true
		super
  end
	
	def build_obj
		super
		if params[:from_vacancy_id]
			@obj.vacancy = Vacancy.find params[:from_vacancy_id]
			@obj.agency_id = @obj.vacancy.agency_id
			@obj.department_id = @obj.vacancy.department_id
		end
		if params[:from_vacancy_data_id]
			@obj.vacancy_data = VacancyData.find params[:from_vacancy_data_id]
			@obj.agency = @obj.vacancy_data.agency
			@obj.department = @obj.vacancy_data.department
		end
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
			@obj.division = @current_user.division if @current_user.division
		end
		@obj.user = @current_user
		@obj.status = 'started'
		@obj.hr_status = 'dept'
	end
	
	def view
		if request.post?
			FormCountyChange.update_county_form_status_and_notify @obj, @current_user, params[:obj]			
			flash[:notice] = 'Status has been updated.'
			redirect_to
		else
			super
		end
	end
	
	def submit
		load_obj
		FormCountyChange.update_county_form_status_and_notify @obj, @current_user, {:status => 'submitted', :hr_status => 'liaison', :submitter_id => @current_user.id, :submitted_at => Time.now}
		redirect_to :action => :view, :id => @obj.id
		flash[:notice] = 'Form has been submitted to HR'
	end
	
	def print
		@opt = {:margin => '.3in'}
		super
	end
	
	def update_obj_statuses_and_notify attr
	
	end
	
end