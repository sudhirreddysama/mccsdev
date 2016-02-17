class VacancyController < CrudController

def index
		@filter = get_filter({
			:sort1 => 'vacancies.received_date',
			:dir1 => 'desc',
			:sort2 => 'vacancies.cost_center',
			:dir2 => 'asc'
		})
		@orders = [
			['ID', 'vacancies.id'],
			['Received Date', 'vacancies.received_date'],
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
		if @current_user.agency_level?
			cond << 'agencies.id = %d' % @current_user.agency_id
			cond << 'departments.id = %d' % @current_user.department_id if @current_user.department_id
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
		@exec << '' if @filter.exec_none.to_i == 1
		@exec << 'Approved' if @filter.exec_approved.to_i == 1
		@exec << 'Disapproved' if @filter.exec_disapproved.to_i == 1
		@exec << 'Hold' if @filter.exec_hold.to_i == 1
		cond << 'vacancies.hr_decision in ("' + @hr.join('","') + '")' unless @hr.empty?
		cond << 'vacancies.omb_decision in ("' + @omb.join('","') + '")' unless @omb.empty?
		cond << 'vacancies.exec_decision in ("' + @exec.join('","') + '")' unless @exec.empty?
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:agency, :department, :user]
		}
		@export_fields = Vacancy.column_names + %w{department.name agency.name user.name}
		if params[:print_all]
			@objs = Vacancy.find(:all, @opt)
			render_pdf render_to_string(:action => :print_all, :layout => false), "vacancies.pdf", @opt
		elsif params[:report]
			@objs = Vacancy.find(:all, @opt)
			@objs_grouped = OrderedHash.new
			@objs.each { |o|
				l = "#{o.org_no}\t#{o.organization}\t#{o.cost_center}"
				@objs_grouped[l] ||= []
				@objs_grouped[l] << o
			}
			@print_orient = 'Landscape'
			render_pdf render_to_string(:action => :report, :layout => false), "vacancies-report.pdf", {:flags => '--header-font-size 8 --footer-font-size 8 --footer-right "[page] of [topage]" --header-right "' + Time.now.d0? + '"'}
		else
			super
		end
	end
	
	def build_obj
		super
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
			@obj.received_date = Time.now.to_date
		else
			if !request.post?
				@obj.received_date = Time.now.to_date
			end
		end
		@obj.user = @current_user
	end
	
	def vacancy_org_autocomplete
		cond = get_search_conditions params[:term], {
			'vacancy_orgs.name' => :like,
			'vacancy_orgs.cost_center' => :like,
			'vacancy_orgs.org_no' => :like
		}
		cond << 'vacancy_orgs.cost_center != ""'
		orgs = VacancyOrg.find(:all, :order => 'vacancy_orgs.name', :conditions => get_where(cond), :limit => 15)
		orgs = orgs.collect { |o| 
			{:org_no => o.org_no, :name => o.name, :cost_center => o.cost_center, :label => "#{o.cost_center} - #{o.name}"}
		}
		render :json => orgs.to_json
	end
	
	def get_approval_no
		yr = params[:yr]
		no = DB.query('select lpad(ifnull(max(substr(exec_approval_no, 4) + 0), 0) + 1, 3, "0") no from vacancies where substr(exec_approval_no, 1, 2) = "%s" and id != %d', yr, params[:id].to_i).fetch_hash.no
		render :text => "#{yr}-#{no}"
	end
	
end