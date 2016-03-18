class VacancyController < CrudController
	
	def expire_vacancy_requests
		Vacancy.expire_vacancy_requests
	end
	before_filter :expire_vacancy_requests
	
	def index
		if @current_user.agency_level?
			@filter = get_filter({
				:sort1 => 'vacancies.created_at',
				:dir1 => 'desc',
				:sort3 => 'vacancies.organization',
				:dir4 => 'asc'
			})
		else
			@filter = get_filter({
				:sort1 => 'vacancies.received_date',
				:dir1 => 'desc',
				:sort2 => 'departments.name',
				:dir2 => 'asc',
				:sort3 => 'vacancies.organization',
				:dir3 => 'asc'
			})
		end
		if params[:preset_approved]
			@filter.clear.merge!({
				:exec_approved => '1',
				:sort1 => 'vacancies.exec_date',
				:dir1 => 'desc',
				:group => 'div'
			})
			params[:report] = {:info => true} if params[:preset_approved][:report]
		elsif params[:preset_mtg]
			@filter.clear.merge!({
				:exec_submitted => '1',
				:sort1 => 'vacancies.received_date',
				:dir1 => 'asc',
				:group => 'dept',
				:hr_approved => '1',
				:hr_disapproved => '1',
				:hr_hold => '1',
				:omb_approved => '1',
				:omb_disapproved => '1',
				:omb_hold => '1'
			})
			params[:report] = {:mtg => true} if params[:preset_mtg][:report]
		elsif params[:preset_hr]
			@filter.clear.merge!({
				:exec_submitted => '1',
				:sort1 => 'vacancies.received_date',
				:dir1 => 'asc',
				:hr_hold => '1',
				:hr_none => '1'
			})
		elsif params[:preset_omb]
			@filter.clear.merge!({
				:exec_submitted => '1',
				:sort1 => 'vacancies.received_date',
				:dir1 => 'asc',
				:omb_hold => '1',
				:omb_none => '1'
			})			
		end
		@orders = [
			['ID', 'vacancies.id'],
			['Received Date', 'vacancies.received_date'],
			['Created Date', 'vacancies.created_at'],
			['Desired Start Date', 'vacancies.desired_start'],
			['HR Decision Date', 'vacancies.hr_date'],
			['OMB Decision Date', 'vacancies.omb_date'],
			['Exec Decision Date', 'vacancies.exec_date'],
			['Approval Used Date', 'vacancies.hr_approval_used'],
			['Department/Division', 'vacancies.organization'],
			['Position', 'vacancies.position'],
			['Org No.', 'vacancies.org_no'],
			['Cost Center', 'vacancies.cost_center'],
			['Position No.', 'vacancies.position_no'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name']
		]
		cond = get_search_conditions @filter[:search], {
			'vacancies.id' => :left,
			'vacancies.organization' => :like,
			'vacancies.position' => :like,
			'vacancies.last_incumbent' => :like,
			'vacancies.org_no' => :like,
			'vacancies.cost_center' => :like,
			'vacancies.position_no' => :like,
			'users.username' => :like
		}
		if @current_user.agency_level? && !@current_user.allow_vacancy_omb && !@current_user.allow_vacancy_admin
			@filter.agency_id = @current_user.agency_id
			@filter.department_id = @current_user.department_id
			#cond << 'agencies.id = %d' % @current_user.agency_id
			#cond << 'departments.id = %d' % @current_user.department_id if @current_user.department_id
		end
		#if @filter.department_ids
		#	@filter.department_ids.reject(&:blank?).map! &:to_i
		#	cond << 'departments.id in (' + @filter.department_ids.join(',') + ')' unless @filter.department_ids.empty?
		#end
		#if @filter.agency_ids
		#	@filter.agency_ids.reject(&:blank?).map! &:to_i
		#	cond << 'agencies.id in (' + @filter.agency_ids.join(',') + ')' unless @filter.agency_ids.empty?
		#end
		if !@filter.department_id.blank?
			@filter.department_id = @filter.department_id.to_i
			cond << 'vacancies.department_id = %d' % @filter.department_id
		end
		if !@filter.agency_id.blank?
			@filter.agency_id = @filter.agency_id.to_i
			cond << 'vacancies.agency_id = %d' % @filter.agency_id
		end
		@date_types = [
			['Received Date', 'vacancies.received_date'],
			['Received Date', 'vacancies.created_date'],
			['Desired Start Date', 'vacancies.desired_start'],
			['HR Decision Date', 'vacancies.hr_date'],
			['OMB Decision Date', 'vacancies.omb_date'],
			['Exec Decision Date', 'vacancies.exec_date'],
			['Approval Used Date', 'vacancies.hr_approval_used']
		]
		cond += get_date_cond
		@hr = []
		@hr << '' if @filter.hr_none.to_i == 1
		@hr << 'Approved' if @filter.hr_approved.to_i == 1
		@hr << 'Disapproved' if @filter.hr_disapproved.to_i == 1
		@hr << 'Hold' if @filter.hr_hold.to_i == 1
		@omb = []
		@omb << '' if @filter.omb_none.to_i == 1
		@omb << 'Approved' if @filter.omb_approved.to_i == 1
		@omb << 'Disapproved' if @filter.omb_disapproved.to_i == 1
		@omb << 'Hold' if @filter.omb_hold.to_i == 1
		@exec = []
		@exec << 'Started' if @filter.exec_started.to_i == 1
		@exec << 'Submitted' if @filter.exec_submitted.to_i == 1
		@exec << 'Approved' if @filter.exec_approved.to_i == 1
		@exec << 'Disapproved' if @filter.exec_disapproved.to_i == 1
		@exec << 'Filled' if @filter.exec_filled.to_i == 1
		@exec << 'Expired' if @filter.exec_expired.to_i == 1
		cond << 'vacancies.hr_decision in ("' + @hr.join('","') + '")' unless @hr.empty?
		cond << 'vacancies.omb_decision in ("' + @omb.join('","') + '")' unless @omb.empty?
		cond << 'vacancies.exec_decision in ("' + @exec.join('","') + '")' unless @exec.empty?
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department, :user]
		}
		@export_fields = %w{id department.name agency.name user.name created_at received_date organization position salary_group vacancy_date last_incumbent org_no cost_center position_no leaving_county no_weeks hours_week work_covered justification filled_from from_position desired_start job_type dept_no exec_decision exec_approval_no exec_date exec_comments hr_approval_used hr_candidate_hired}
		if !@current_user.agency_level?
			@export_fields += %w{hr_decision hr_date hr_comments omb_code omb_decision omb_date omb_comments omb_grant_percent}
		end
		if params[:print_all]
			@objs = Vacancy.find(:all, @opt)
			render_pdf render_to_string(:action => :print_all, :layout => false), "vacancies.pdf", @opt
		elsif params[:report]
			@filter.report = params[:report]
			@objs = Vacancy.find(:all, @opt)
			@objs_grouped = OrderedHash.new
			if @filter.group == 'dept'
				@objs.each { |o|
					d = report_department_name o
					@objs_grouped[d] ||= []
					@objs_grouped[d] << o
				}
			elsif @filter.group == 'div'
				@objs.each { |o|
					d = report_department_name o
					v = "#{o.organization}\t#{o.org_no}\t#{o.cost_center}"
					@objs_grouped[d] ||= OrderedHash.new
					@objs_grouped[d][v] ||= []
					@objs_grouped[d][v] << o
				}
			else
				@objs_grouped = @objs
			end
			@print_orient = 'Landscape'
			#render :action => :report, :layout => false
			render_pdf render_to_string(:action => :report, :layout => false), "vacancies-report.pdf", {:flags => '--header-font-size 8 --footer-font-size 8 --footer-right "[page] of [topage]" --header-right "' + Time.now.d0? + '"'}
		else
			super
		end
	end
	
	def report_department_name o
		d = [o.agency && o.agency.name, o.department && o.department.name].reject { |l| l.blank? || l == 'MONROE COUNTY' }.join(' - ')
		return d.blank? ? '(NO DEPARTMENT)' : d
	end
	
	def build_obj
		super
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
		end
		@obj.exec_decision = 'Started'
		@obj.user = @current_user
	end
	
	def status_toggle
		load_obj
		if @obj.exec_decision == params[:exec_decision]
			@obj.attributes = {:exec_decision => 'Submitted', :exec_date => nil}
		else
			@obj.attributes = {:exec_decision => params[:exec_decision], :exec_date => Time.now.to_date}
		end
		@obj.exec_approval_no = @obj.exec_decision == 'Approved' ? Vacancy.next_exec_approval_no(@obj.exec_date.year.to_s[2, 2], @obj.id) : nil
		@obj.exec_comments = params[:exec_comments]
		@obj.save
		render :json => {:exec_decision => @obj.exec_decision, :exec_date => @obj.exec_date ? @obj.exec_date.d0? : '', :exec_approval_no => @obj.exec_approval_no || ''}
	end
	
	def submit
		load_obj
		@obj.update_attributes({:exec_decision => 'Submitted', :submitter_id => @current_user.id, :received_date => Time.now.to_date})
		redirect_to :action => :view, :id => @obj.id
		flash[:notice] = 'Request to fill vacancy has been submitted to HR'
	end
	
	def view
		if request.post? && params[:email_id]
			u = User.find params[:email_id]
			flash[:notice] = "Email notification has been send to #{u.name}"
			Notifier.deliver_vacancy_notification @current_user, [u], @obj
			redirect_to
			return
		elsif request.post? && @obj.update_attributes(params[:obj])
			flash[:notice] = 'Status has been updated.'
			redirect_to
			return
		else
			super
		end
	end
	
	def vacancy_autocomplete
		field = params[:field]
		if !(%w(organization org_no cost_center position position_no last_incumbent search).include?(field))
			render_nothing
			return
		end
		cond = []
		if field == 'search'
			cond = get_search_conditions(params[:search], {
				'organization' => :like,
				'org_no' => :left,
				'cost_center' => :left,
				'position' => :like,
				'position_no' => :left,
				'last_incumbent' => :like
			})
		else
			cond += get_search_conditions(params[:organization], {'organization' => :like}) if field != 'cost_center' && field != 'org_no'
			cond += get_search_conditions(params[:org_no], {'org_no' => :left}) if field != 'organization' && field != 'cost_center'
			cond += get_search_conditions(params[:cost_center], {'cost_center' => :left}) if field != 'organization' && field != 'org_no'
			cond += get_search_conditions(params[:position], {'position' => :like}) if field != 'position_no' && field != 'last_incumbent'
			cond += get_search_conditions(params[:position_no], {'position_no' => :left}) if field != 'position' && field != 'last_incumbent'
			cond += get_search_conditions(params[:last_incumbent], {'last_incumbent' => :like}) if field != 'position' && field != 'position_no'
		end
		opt = {
			:limit => 20,
			:conditions => get_where(cond),
			:order => field == 'search' ? 'position, last_incumbent' : field
		}
		if %w(organization org_no cost_center).include?(params[:field])
			opt[:group] = 'organization, org_no, cost_center'
		end
		data = VacancyData.find(:all, opt)
		render :json => data.collect { |o| {
				:organization => o.organization,
				:org_no => o.org_no,
				:cost_center => o.cost_center,
				:position => o.position,
				:position_no => o.position_no,
				:last_incumbent => o.last_incumbent,
				:salary_group => o.salary_group,
				:label => field == 'search' ? "#{o.position} - #{o.last_incumbent.blank? ? '(NO INCUMBENT)' : o.last_incumbent}" : o.send(field)
			}
		}
		
# 		cond = get_search_conditions params[:term], {
# 			'vacancy_orgs.name' => :like,
# 			'vacancy_orgs.cost_center' => :left,
# 			'vacancy_orgs.org_no' => :left
# 		}
# 		cond << 'vacancy_orgs.cost_center != ""'
# 		if params[:id] == 'org_no'
# 			order = 'vacancy_orgs.org_no'
# 		elsif params[:id] == 'cost_center'
# 			order = 'vacancy_orgs.cost_center'
# 		else
# 			order = 'vacancy_orgs.name'
# 		end		
# 		orgs = VacancyOrg.find(:all, :order => order, :conditions => get_where(cond), :limit => 15)
# 		orgs = orgs.collect { |o| 
# 			if params[:id] == 'org_no'
# 				label = "#{o.org_no} - #{o.name} (#{o.cost_center})"
# 			elsif params[:id] == 'cost_center'
# 				label = "#{o.cost_center} - #{o.name} (#{o.org_no})"
# 			else
# 				label = "#{o.name} (#{o.org_no} / #{o.cost_center})"
# 			end
# 			{:org_no => o.org_no, :name => o.name, :cost_center => o.cost_center, :label => label}
# 		}
# 		render :json => orgs.to_json
	end
	
	def get_approval_no
		render :text => Vacancy.next_exec_approval_no(params[:yr], params[:id])
	end
	
end