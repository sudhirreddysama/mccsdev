class VacancyDataController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.is_agency_county? && @current_user.perm_ag_employees
		render_nothing and return false
	end
	before_filter :check_access, :except => [:autocomplete, :org_autocomplete, :rehire_sap_no_from_ssn]
	
	def options
		@view_only = true
		super
	end
	
	def index
		@filter = get_filter({
			:sort1 => 'vacancy_data.last_name',
			:dir1 => 'asc',
			:sort1 => 'vacancy_data.first_name',
			:dir1 => 'asc'
		})
		@orders = [
			['Last Name', 'vacancy_data.last_name'],
			['First Name', 'vacancy_data.first_name'],
			['Organization', 'vacancy_data.organization'],
			['Org #', 'vacancy_data.org_no'],
			['Cost Center', 'vacancy_data.cost_center'],
			['Position', 'vacancy_data.position'],
			['Position #', 'vacancy_data.position_no'],
			['Job #', 'vacancy_data.job_no'],
			['County Org #', 'vacancy_data.county_org_no'],
			['Personnel #', 'vacancy_data.personnel_no'],
		]
		cond = get_search_conditions @filter[:search], {			
			'vacancy_data.last_name' => :like,			
			'vacancy_data.first_name' => :like,			
			'vacancy_data.organization' => :like,			
			'vacancy_data.org_no' => :like,			
			'vacancy_data.cost_center' => :like,			
			'vacancy_data.position' => :like,			
			'vacancy_data.position_no' => :like,			
			'vacancy_data.job_no' => :like,			
			'vacancy_data.county_org_no' => :like,			
			'vacancy_data.personnel_no' => :like,
		}
		cond << 'status = 0' if @filter.status == 'vacant'
		cond << 'status = 2' if @filter.status == 'occupied'		
		cond << data_cost_center_cond		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super	
	end
	
	def autocomplete
		cond = get_search_conditions(params[:search] || params[:term], {
			'organization' => :like,
			'org_no' => :left,
			'cost_center' => :left,
			'position' => :like,
			'position_no' => :left,
			'last_incumbent' => :like
		})
		cond << 'status != 0' if params[:no_vacant]
		cond << data_cost_center_cond
		opt = {
			:limit => 20,
			:conditions => get_where(cond),
			:order => 'position, last_incumbent'
		}
		data = VacancyData.find(:all, opt)
		render :json => data.collect { |o| 
			o.autocomplete_json_data
		}
	end	
	
	def org_autocomplete
		field = params[:field] || 'org_no'
		render_nothing if !%w{org_no county_org_no cost_center}.include?(field)
		cond = get_search_conditions(params[:search] || params[:term], {
			'organization' => :like,
			field => :like,
		})
		cond << data_cost_center_cond
		cond << "#{field} != ''"
		fld = "#{field}, organization"
		fld += ", county_org_no, cost_center" if field == 'org_no'			
		opt = {
			:limit => 20,
			:conditions => get_where(cond),
			:order => fld,
			:group => fld,
			:select => fld
		}
		data = VacancyData.find(:all, opt)
		render :json => data.collect { |o| 
			h = {:organization => o.organization}
			h[field] = o.send(field)
			if field == 'org_no'
				h['county_org_no'] = o.county_org_no
				h['cost_center'] = o.cost_center
			end
			h
		}
	end	
	
	def pos_autocomplete
		cond = get_search_conditions(params[:search] || params[:term], {
			'position' => :like,
			'position_no' => :like,
		})
		cond << data_cost_center_cond
		opt = {
			:limit => 20,
			:conditions => get_where(cond),
			:order => 'position_no',
			:group => 'position_no',
			:select => 'position_no, position, job_no, salary_group, flsa_exempt'
		}
		data = VacancyData.find(:all, opt)
		render :json => data.collect(&:attributes)
	end	
	
	def rehire_sap_no_from_ssn 
		d = SAP.employee_lookup({:ssn => params.ssn})
		render :json => d.to_json
	end
	
	def vacancy_cost_data
		if params[:position_no].blank?
			render :nothing => true
			return
		end
		cond = []
		cond << DB.escape('vacancy_cost_data.position_no = "%s"', params[:position_no])
		cond << data_cost_center_cond
		opt = {
			:conditions => get_where(cond),
			:order => 'vacancy_cost_data.sequence'
		}
		objs = VacancyCostData.find(:all, opt)
		render :json => objs.collect(&:autocomplete_json_data)
	end
	
	private
	
	def data_cost_center_cond
		department_id = @current_user.agency_level? && @current_user.department_id || params[:department_id]
		agency_id = @current_user.agency_level? && @current_user.agency_id || params[:agency_id]
		department = Department.find_by_id(department_id) if !department_id.blank?
		agency = Agency.find_by_id(agency_id) if !agency_id.blank?
		data_codes = department && department.vacancy_data_codes
		if data_codes.blank?
			data_codes = agency && agency.vacancy_data_codes
		end
		if !data_codes.blank?
			return 'substring(cost_center, 1, 2) in (' + data_codes.split(',').map(&:to_i).join(',') + ')'
		end	
		return nil
	end
	
end