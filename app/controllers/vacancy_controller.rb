class VacancyController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.is_agency_county? && @current_user.perm_ag_vacancies?
		render_nothing and return false
	end
	before_filter :check_access, :except => :autocomplete
	
	def expire_vacancy_requests
		Vacancy.expire_vacancy_requests
	end
	before_filter :expire_vacancy_requests
	
	def notify
		render(:nothing => true) && return if !@current_user.admin_level?
		if request.post?
			@email = params.email
			@errors = []
			@errors << 'Subject is required' if @email.subject.blank?
			@errors << 'Body is required' if @email.body.blank?
			@errors << 'From is required' if @email.from.blank?
			recipients = @email.recipients.to_s.split(/[\r,\n]/).reject(&:blank?)
			@errors << 'Recipients is required' if recipients.empty?
			if @errors.empty?
				recipients.each { |to|
					Notifier.deliver_custom_email to, @email.subject, @email.from, @email.body
				}
				flash[:notice] = 'Email has been sent.'
				redirect_to
			end
		else
			emails = []
			DB.query('select u.email from users u
				left join vacancies v on u.id in (v.submitter_id, v.user_id)
				where u.level != "disabled" and (v.id is not null or u.only_vacancy = 1 or u.allow_vacancy_omb = 1 or u.allow_vacancy_admin = 1 or u.vacancy_emails = 1)
				group by u.email'
			).each_hash { |h|
				emails << h.email
			}
			logger.info emails
			
			tt = TopText.find_by_path('/vacancy%')
			@email = {
				:subject => tt ? tt.name : 'Request to Fill Vacancy Information',
				:from => @current_user.email,
				:body => tt ? tt.text : '',
				:recipients => emails.join("\r")
			}
		end
	end
	
	def index
		if @current_user.agency_level?
			@filter = get_filter({
				:sort1 => 'vacancies.created_at',
				:dir1 => 'desc',
				:sort2 => 'vacancies.organization',
				:dir2 => 'asc'
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
				:sort1 => 'departments.name',
				:dir1 => 'asc',
				:sort2 => 'vacancies.received_date',
				:dir2 => 'asc',
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
				#:omb_hold => '1',
				:omb_none => '1'
			})			
		end
		@orders = [
			['ID', 'vacancies.id'],
			['Received Date', 'vacancies.received_date'],
			['Created Date', 'vacancies.created_at'],
			['Desired Start Date', 'vacancies.desired_start'],
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
			'users.username' => :like,
			'vacancies.exec_approval_no' => :like
		}
		if @current_user.agency_level? && !@current_user.allow_vacancy_omb && !@current_user.allow_vacancy_admin
			@filter.agency_id = @current_user.agency_id
			@filter.department_id = @current_user.department_id
			@filter.division_id = @current_user.division_id unless @current_user.division_id.blank?
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
		if !@filter.division_id.blank?
			@filter.division_id = @filter.division_id.to_i
			cond << 'vacancies.division_id = %d' % @filter.division_id
		end
		@date_types = [
			['Received Date', 'vacancies.received_date'],
			['Created Date', 'vacancies.created_at'],
			['Desired Start Date', 'vacancies.desired_start'],
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
		if params[:from_vacancy_data_id]
			@from_vacancy_data = VacancyData.find params[:from_vacancy_data_id]
			@obj.agency = @from_vacancy_data.agency
			@obj.department = @from_vacancy_data.department
		end
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
			@obj.division = @current_user.division if @current_user.division
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
		cond << 'status != 0' if params[:no_vacant]
		cond << data_cost_center_cond
		opt = {
			:limit => 20,
			:conditions => get_where(cond),
			:order => field == 'search' ? 'position, last_incumbent' : field
		}
		if %w(organization org_no cost_center).include?(params[:field])
			opt[:group] = 'organization, org_no, cost_center'
		end
		data = VacancyData.find(:all, opt)
		render :json => data.collect { |o|
			o.autocomplete_json_data(field)
		}
	end
	
	# Different than above. This is used on OTHER forms to reference a Vacancy object.
	def autocomplete
		cond = get_search_conditions(params[:term], {
			'vacancies.exec_approval_no' => :like,
			'vacancies.org_no' => :like,
			'vacancies.cost_center' => :like,
			'vacancies.position_no' => :like,
			'vacancies.position' => :like,
			'vacancies.last_incumbent' => :like
		})
		cond << 'vacancies.exec_decision = "Approved"'
		user_limited = @current_user.agency_level? && !@current_user.allow_vacancy_omb && !@current_user.allow_vacancy_admin
		agency_id = user_limited && @current_user.agency_id || params[:agency_id]
		department_id = user_limited && @current_user.department_id || params[:department_id]
		division_id = user_limited && @current_user.division_id || params[:division_id]
		cond << 'vacancies.agency_id = %d' % agency_id.to_i if !agency_id.blank?
		cond << 'vacancies.department_id = %d' % department_id.to_i if !department_id.blank?
		cond << 'vacancies.division_id = %d' % division_id.to_i if !division_id.blank?
		objs = @model.find(:all, :include => :vacancy_data, :conditions => get_where(cond), :limit => 10, :order => 'vacancies.id desc').map { |o|
			o.autocomplete_json_data
		}
		render :json => objs.to_json
	end
	
	def get_approval_no
		render :text => Vacancy.next_exec_approval_no(params[:yr], params[:id])
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