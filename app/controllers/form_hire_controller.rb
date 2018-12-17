class FormHireController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'form_hires.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'form_hires.id'],
			['Created Date', 'form_hires.created_at'],
			['Effective Date', 'form_hires.effective_date'],
			['First Name', 'form_hires.first_name'],
			['Last Name', 'form_hires.last_name'],
			['Agency Name', 'agencies.name'],
			['Title', 'form_hires.title']
		]
		cond = get_search_conditions @filter[:search], {
			'form_hires.id' => :left,
			'agencies.name' => :like,
			'form_hires.title' => :like,
			'form_hires.first_name' => :like,
			'form_hires.last_name' => :like,
      'employees.ssn' => :like,
      'employees.ssn_raw' => :like,
      'form_hires.ssn' => :like

		}
		
		if @current_user.agency_level?
			@filter.agency_id = @current_user.agency_id if !@current_user.agency_id.blank?
			@filter.department_id = @current_user.department_id if !@current_user.department_id.blank?
			@filter.division_id = @current_user.division_id if !@current_user.division_id.blank?
		end
		if !@filter.department_id.blank?
			@filter.department_id = @filter.department_id.to_i
			cond << 'form_hires.department_id = %d' % @filter.department_id
		end
		if !@filter.agency_id.blank?
			@filter.agency_id = @filter.agency_id.to_i
			cond << 'form_hires.agency_id = %d' % @filter.agency_id
		end
		if !@filter.division_id.blank?
			@filter.division_id = @filter.division_id.to_i
			cond << 'form_hires.division_id = %d' % @filter.division_id
		end	
		
		@date_types = [
			['Created Date', 'form_hires.created_at'],
			['Effective Date', 'form_hires.effective_date']
		]
		
		cond += get_date_cond
		
		@filter.statuses ||= []		
		if !@filter.statuses.empty?
			s = @filter.statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',')
			cond << 'form_hires.status in (%s)' % s
		end
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department, :employee]
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
			if @obj.is_provisional? && @obj.status == 'approved' && old_status != @obj.status
				Notifier.deliver_form_hire_provisional @obj
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
			c_code = @obj.classification_code
			s_code = @obj.status_code
			@act.attributes = {
				:employee => @empl,
				:job_id => @obj.job_id,
				:agency_id => @obj.agency_id,
				:department_id => @obj.department_id,
				:wage => @obj.salary.to_s.gsub(/[^0-9.]/, ''),
				:wage_per => @obj.salary_per,
				:classification => c_code || la.classification,
				:status => s_code || la.status,
				:job_time => @obj.full_or_part_time.to_s[0,1],
				:action_date => @obj.effective_date,
				:reference_date => Time.now.to_date,
				:absent => true,
				#:leave_date => @empl.leave_date, # No leave date from "new hire" form.
				:empl_action_type_id => 31
			}
		end
		@act.authorization = '330E'
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