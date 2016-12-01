class FormChangeController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'form_changes.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'form_changes.id'],
			['Created Date', 'form_changes.created_at'],
			['Effective Date', 'form_changes.effective_date'],
			['First Name', 'form_changes.first_name'],
			['Last Name', 'form_changes.last_name'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'form_changes.id' => :left,
			'agencies.name' => :like,
			'departments.name' => :like,
			'form_changes.first_name' => :like,
			'form_changes.last_name' => :like,
      'employees.ssn' => :like,
      'employees.ssn_raw' => :like
		}
		
		if @current_user.agency_level?
			cond << 'agencies.id = %d' % @current_user.agency_id
			cond << 'departments.id = %d' % @current_user.department_id if @current_user.department_id
		end
		
		@date_types = [
			['Created Date', 'form_changes.created_at'],
			['Effective Date', 'form_changes.effective_date']
		]
		
		cond += get_date_cond
		
		@filter.statuses ||= []		
		if !@filter.statuses.empty?
			s = @filter.statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',')
			cond << 'form_changes.status in (%s)' % s
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
			u = @obj.user #@obj.agency ? @obj.agency.get_users(@obj.department) : nil
			u2 = @obj.submitter
			if u2
				Notifier.deliver_form_status [u2].reject(&:nil?), @obj
			end
			if @obj.separation_provisional && @obj.status == 'approved' && old_status != @obj.status
				Notifier.deliver_form_change_separation_provisional_approved @obj
			end
			redirect_to
		else
			build_action
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

	def build_action
		@empl = @obj.employee
		@act = @obj.empl_actions.build
		if @empl
			la = @empl.last_action || {}
			@act.attributes = {
				:employee => @empl,
				:job_id => la.job_id,
				:agency_id => la.agency_id,
				:department_id => la.department_id,
				:wage => la.wage,
				:wage_per => la.wage_per,
				:classification => la.classification,
				:status => la.status,
				:action_date => @obj.effective_date,
				:job_time => la.job_time,
				:reference_date => Time.now.to_date,
				:absent => true,
				:leave_date => @empl.leave_date
			}
		end
		if @obj.change_demotion
			@act.empl_action_type_id = EmplActionType.find_by_name('DEMOTION').id
			@act.job_id = @obj.demotion_title_id
			@act.wage = @obj.demotion_salary.to_s.gsub(/[^0-9.]/, '')
			@act.wage_per = @obj.demotion_salary_per
			@act.classification = Const::JOB_CLASSES.assoc(@obj.demotion_class)[1] rescue nil
			@act.status = Const::JOB_STATUSES.assoc(@obj.demotion_status)[1] rescue nil
			@act.job_time = @obj.demotion_job_time
		end
		if @obj.change_name
			@act.empl_action_type_id = EmplActionType.find_by_name('NAME CHG').id
		end
		if @obj.change_loa
			@act.empl_action_type_id = EmplActionType.find_by_name('LOA').id
		end
		if @obj.change_perm_appt
			@act.empl_action_type_id = EmplActionType.find_by_name('PERM APPT').id
		end
		if @obj.change_promotion
			@act.empl_action_type_id = EmplActionType.find_by_name('PROMOTION').id
			@act.job_id = @obj.promotion_new_title_id
			@act.wage = @obj.promotion_salary.gsub(/[^0-9.]/, '')
			@act.wage_per = @obj.promotion_salary_per
			@act.classification = Const::JOB_CLASSES.assoc(@obj.promotion_class)[1] rescue nil
			@act.status = Const::JOB_STATUSES.assoc(@obj.promotion_status)[1] rescue nil
			@act.job_time = @obj.promotion_job_time
		end
		if @obj.change_salary
			@act.empl_action_type_id = EmplActionType.find_by_name('WAGE CHG').id
			@act.wage = @obj.salary_change_to.to_s.gsub(/[^0-9.]/, '')
			@act.wage_per = @obj.salary_change_to_per
		end
		if @obj.change_second_provisional
			@act.empl_action_type_id = EmplActionType.find_by_name('2ND PROV').id
		end
		if @obj.change_separation
			@act.empl_action_type_id = EmplActionType.find_by_name({
				'Deceased' => 'DECEASED',
				'Layoff' => 'LAYOFF',
				'Program Ended' => 'PROG ENDED',
				'Resignation' => 'RESIGNED',
				'Retirement' => 'RETIRED',
				'Termination' => 'TERMINATED'
			}[@obj.separation_reason]).id rescue nil
			@act.leave_date = @obj.separation_date
		end
		if @obj.change_status	
			if @obj.status_type == 'PT TO FT'
				@act.empl_action_type_id = EmplActionType.find_by_name('PT TO FT').id
				@act.job_time = 'F'
			elsif @obj.status_type == 'FT TO PT'
				@act.empl_action_type_id = EmplActionType.find_by_name('FT TO PT').id
				@act.job_time = 'P'
			else
				@act.empl_action_type_id = EmplActionType.find_by_name('STATUS CHG').id
				@act.status = @obj.status_type
			end
			@act.classification = Const::JOB_CLASSES.assoc(@obj.status_class)[1] rescue nil
			if @act.classification != la.classification
				@act.empl_action_type_id = EmplActionType.find_by_name('CLASS CHG').id
			end
		end
		if @obj.change_suspension
			@act.empl_action_type_id = EmplActionType.find_by_name('SUSPENDED').id
		end
		if @obj.change_title
			@act.empl_action_type_id = EmplActionType.find_by_name('TITLE CHG').id
			@act.job_id = @obj.title_change_new_title_id
			@act.classification = Const::JOB_CLASSES.assoc(@obj.title_change_class)[1] rescue nil
			@act.status = Const::JOB_STATUSES.assoc(@obj.title_change_status)[1] rescue nil
			@act.job_time = @obj.title_change_job_time
		end
		@act.authorization = '105E'
		@act.received_date = @obj.submitted_at ? @obj.submitted_at.to_date : nil 
	end
	
	def action_new
		load_obj
		build_action
		if request.post?
			@act.attributes = params[:act]
			if @act.save
				flash[:notice] = 'Record has been saved.'
				redirect_to :action => :view, :id => @obj.id, :id2 => nil
			end
		end
	end

end