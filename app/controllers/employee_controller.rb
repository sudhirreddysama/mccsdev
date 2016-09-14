class EmployeeController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'employees.last_name',
			:dir1 => 'asc',
			:sort2 => 'employees.first_name',
			:dir2 => 'asc',
			:status => 'all'
		})
		
		@orders = [
			['ID', 'employees.id'],
			['First Name', 'employees.first_name'],
			['Last Name', 'employees.last_name'],
			['SSN', 'employees.ssn'],
			['Hire Date', 'employees.date_hired'],
			['Leave Date', 'employees.leave_date'],
			['Title', 'jobs.name'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name'],
			['Seniority Date', 'employees.seniority_date']
		]

		@date_types = [
			['Hire Date', 'employees.date_hired'],
			['Leave Date', 'employees.leave_date']
		]
		
		cond = get_search_conditions @filter[:search], {
			'employees.id' => :left,
			'employees.first_name' => :like,
			'employees.last_name' => :like,
			'employees.ssn' => :left,
			'employees.ssn_raw' => :left
		}
		
		cond += get_date_cond()		
		
		if @current_user.agency_level?
			cond << 'employees.agency_id = %d' % @current_user.agency_id if @current_user.agency
			cond << 'employees.department_id = %d' % @current_user.department_id if @current_user.department
		else
		
			if @filter[:agency_ids]
				@filter[:agency_ids].map! &:to_i
				cond << 'employees.agency_id in (%s)' % @filter[:agency_ids].join(',')
			end		
			
			if @filter[:department_ids]
				@filter[:department_ids].map! &:to_i
				cond << 'employees.department_id in (%s)' % @filter[:department_ids].join(',')
			end		
		end
		
		if @filter[:job_ids]
			@filter[:job_ids].map! &:to_i
			cond << 'employees.job_id in (%s)' % @filter[:job_ids].join(',')
		end		
		
		cond << 'employees.leave_date is null or date(employees.leave_date) > date(now())' if @filter[:status] == 'current'
		cond << 'employees.leave_date is not null and date(employees.leave_date) <= date(now())' if @filter[:status] == 'prior'
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:job, :agency, :department, :first_action, :last_action],
		}
		
		@export_fields = %w(id first_name last_name job.name agency.name department.name address address2 city state zip phone work_phone email ssn pension_no notes date_hired seniority_date date_of_birth veteran exempt_vol_fire leave_date wage wage_per job_time status classification)
		
		super
	end 
	
	def build_obj
		super
		if !request.post? && params[:from]
			from = FormHire.find params[:from]
			if from
				empl = from.employee
				@obj.agency_id = from.agency_id
				@obj.department_id = from.department_id
				@obj.first_name = from.first_name
				@obj.last_name = from.last_name
				@obj.address = from.address
				@obj.address2 = from.address2
				@obj.city = from.address_city
				@obj.state = from.address_state
				@obj.zip = from.address_zip
				@obj.ssn = from.ssn
				@obj.wage = from.salary.to_s.gsub(/[^0-9.]/, '')
				@obj.wage_per = from.salary_per
        @obj.pension_no=from.retirement_no
				@obj.date_of_birth = from.date_of_birth
				@obj.new_empl_action.agency_id = from.agency_id
				@obj.new_empl_action.department_id = from.department_id
				@obj.new_empl_action.job_id = from.job_id
				@obj.new_empl_action.action_date = from.effective_date
				@obj.new_empl_action.received_date = from.submitted_at ? from.submitted_at.to_date : nil
				@obj.new_empl_action.authorization = '330E'				
				if from.hire_type == 'New Hire'
					@obj.new_empl_action.empl_action_type_id = 30
				elsif from.hire_type == 'Rehire'
					@obj.new_empl_action.empl_action_type_id = 31
				elsif from.hire_type == 'Additional Position'
					@obj.new_empl_action.empl_action_type_id = 42
				end
				@obj.new_empl_action.wage = from.salary.to_s.gsub(/[^0-9.]/, '')
				@obj.new_empl_action.wage_per = from.salary_per

				if empl
					@obj.phone = empl.phone
					@obj.work_phone = empl.work_phone
					@obj.email = empl.email
					@obj.veteran = empl.veteran
					@obj.exempt_vol_fire = empl.exempt_vol_fire
				end
				
				if from.full_or_part_time == 'PT'
					@obj.new_empl_action.job_time = 'P'
				elsif from.full_or_part_time == 'FT'
					@obj.new_empl_action.job_time = 'F'
				end
				@obj.new_empl_action.classification = from.classification_code
				@obj.new_empl_action.status = from.status_code
			end
		end
	end
	
	def action_new
		load_obj
		la = @obj.last_action || {}
		@act = @obj.empl_actions.build({
			:job_id => la.job_id,
			:agency_id => la.agency_id,
			:department_id => la.department_id,
			:wage => la.wage,
			:wage_per => la.wage_per,
			:classification => la.classification,
			:status => la.status,
			:job_time => la.job_time,
			:reference_date => Time.now.to_date,
			:absent => true,
			:leave_date => @obj.leave_date
		})
		if request.post?
			@act.attributes = params[:act]
			if @act.save
				flash[:notice] = 'Record has been saved.'
				redirect_to :action => :view, :id => @obj.id, :id2 => nil
			end
		end
	end
	
	def action_edit
		load_obj
		@act = @obj.empl_actions.find params[:id2]
		if request.post? && @act.update_attributes(params[:act])
			flash[:notice] = 'Record has been saved.'
			redirect_to :action => :view, :id => @obj.id, :id2 => nil
		end
	end
	
	def action_delete
		load_obj
		@act = @obj.empl_actions.find params[:id2]
		if request.post? && @act.destroy
			flash[:notice] = 'Record has been deleted.'
			redirect_to :action => :view, :id => @obj.id, :id2 => nil
		end
	end
	
	def print_overview
		load_obj
		@print_orient = 'landscape'
		render_pdf render_to_string(:layout => false), "#{@obj.label}.pdf"
	end
	
	def print
		@print_orient = 'landscape'
		super
	end
	
	def employee_data
		e = Employee.find_by_id params[:id]
		if e
			atr = {
				:id => e.id,
				:first_name => e.first_name,
				:last_name => e.last_name,
				:job_name => e.job ? e.job.name : '',
				:job_id => e.job_id,
				:address => e.address,
				:address2 => e.address2,
				:city => e.city,
				:state => e.state,
				:zip => e.attributes['zip'],
				:phone => e.phone,
				:ssn => e.ssn,
				:provisional => e.status == 'V',
				:wage => e.wage,
				:wage_per => e.wage_per,
        :pension_no => e.pension_no,
        :date_of_birth => e.date_of_birth ? e.date_of_birth.strftime('%m/%d/%Y') : nil
			}
			render :json => atr.to_json
		else
			render_nothing
		end
	end

	def ssn_ac
		e = Employee.find(:first, {
			:conditions => ['employees.ssn = ?', params[:ssn]],
			:order => 'employees.id desc'
		})
		if e
			atr = {
				:id => e.id,
				:first_name => e.first_name,
				:last_name => e.last_name,
				:job_name => e.job ? e.job.name : '',
				:provisional => e.status == 'V'
			}
			render :json => atr.to_json
		else
			render_nothing
		end
	end
	
	def mismatch
		params[:id] ||= 'name'
		@objs = DB.query('
			select 
				e.ssn ssn, e.id e_id, p.id p_id,
				e.first_name e_first_name, e.last_name e_last_name, 
				p.first_name p_first_name, p.last_name p_last_name,
				e.address e_address, e.address2 e_address2, e.city e_city, e.state e_state, e.zip e_zip,
				p.mailing_address p_address, p.mailing_address2 p_address2, p.mailing_city p_city, p.mailing_state p_state, p.mailing_zip p_zip,
				substring_index(e.first_name, " ", 1) != substring_index(p.first_name, " ", 1) or 
					substring_index(e.last_name, " ", 1) != substring_index(p.last_name, " ", 1) name_mismatch,
				substring_index(e.address, " ", 2) != substring_index(p.mailing_address, " ", 2) or 
					e.city != p.mailing_city or e.zip != p.mailing_zip address_mismatch
			from employees e
			join people p on p.ssn = e.ssn
			where e.leave_date is null or date(e.leave_date) > date(now())
			having ' + (params[:id] == 'name' ? 'name_mismatch' : 'address_mismatch') + '
			order by e.last_name, e.first_name
		')
	end
	
end