class FormCountyHireController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'form_county_changes.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'form_county_hires.id'],
			['Created Date', 'form_county_hires.created_at'],
			['Effective Date', 'form_county_hires.effective_date'],
			['Name', 'form_county_hires.name'],
			['Agency Name', 'agencies.name'],
			['Department Name', 'departments.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'form_county_hires.id' => :left,
			'agencies.name' => :like,
			'departments.name' => :like,
			'form_county_hires.name' => :like,
		}
		
		if @current_user.agency_level?
			@filter.agency_id = @current_user.agency_id if !@current_user.agency_id.blank?
			@filter.department_id = @current_user.department_id if !@current_user.department_id.blank?
			@filter.division_id = @current_user.division_id if !@current_user.division_id.blank?
		end
		if !@filter.department_id.blank?
			@filter.department_id = @filter.department_id.to_i
			cond << 'form_county_hires.department_id = %d' % @filter.department_id
		end
		if !@filter.agency_id.blank?
			@filter.agency_id = @filter.agency_id.to_i
			cond << 'form_county_hires.agency_id = %d' % @filter.agency_id
		end
		if !@filter.division_id.blank?
			@filter.division_id = @filter.division_id.to_i
			cond << 'form_county_hires.division_id = %d' % @filter.division_id
		end	
		
		@date_types = [
			['Created Date', 'form_county_hires.created_at'],
			['Effective Date', 'form_county_hires.effective_date']
		]
		
		cond += get_date_cond
		
		@filter.statuses ||= []		
		if !@filter.statuses.empty?
			s = @filter.statuses.collect { |s| "\"#{DB.escape(s)}\"" }.join(',')
			cond << 'form_county_hires.status in (%s)' % s
		end
		
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
	
	def build_obj
		super
		if params[:from_vacancy_id]
			v = Vacancy.find(params[:from_vacancy_id])
			@obj.vacancy_no = v.exec_approval_no
			@obj.org_no = v.org_no
			@obj.cost_center = v.cost_center
			@obj.position = v.position
			@obj.position_no = v.position_no
			@obj.salary_group = v.salary_group
		end
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
				Notifier.deliver_form_change_provisional @obj
			end
			redirect_to
		else
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
	
	def applicant_autocomplete
		# 1. Find by certified list.
		cond = get_search_conditions params[:term], {
			'people.first_name' => :like,
			'people.last_name' => :like,
			'people.ssn' => :like,
			'exams.exam_no' => :like,
			'exams.title' => :like,
		}
		cond << 'app_statuses.eligible in ("I", "A")'
		cond << 'date(now()) between certs.certification_date and certs.return_date'
		agency_id = @current_user.agency_level? && @current_user.agency_id || params[:agency_id]
		department_id = @current_user.agency_level? && @current_user.department_id || params[:department_id]
		division_id = @current_user.agency_level? && @current_user.division_id || params[:division_id]
		cond << 'certs.agency_id = %d' % agency_id.to_i if !agency_id.blank?
		cond << 'certs.department_id = %d' % department_id.to_i if !department_id.blank?
		cond << 'certs.division_id = %d' % division_id.to_i if !division_id.blank?
		objs = Applicant.find(:all, {
			:include => [:app_status, :person, :exam, {:cert_applicants => [:cert, :cert_code]}],
			:conditions => get_where(cond),
			:limit => 20
		})
		data = []
		objs.each { |o|
			p = o.person
			e = o.exam
			o.cert_applicants.each { |ca|
				c = ca.cert
				cc = ca.cert_code
				data << {
					:cert_title => c.title,
					:first_name => p.first_name,
					:last_name => p.last_name,
					:exam_no => e.exam_no,
					:cert_code => cc ? cc.label : '',
					:certification_date => c.certification_date,
					:job_type => c.job_type,
					:job_time => c.job_time,
					:ssn => p.ssn,
					:phone => p.home_phone,
					:email => p.email,
					:residence_different => p.residence_different,
					:mailing_address => p.mailing_address,
					:mailing_city => p.mailing_city,
					:mailing_state => p.mailing_state,
					:mailing_zip => p.mailing_zip,		
					:residence_address => p.residence_address,
					:residence_city => p.residence_city,
					:residence_state => p.residence_state,
					:residence_zip => p.residence_zip,
					:date_of_birth => p.date_of_birth
				}
			}
		}
		render :json => data.to_json
	end

end
















# 		1. Find by certified list.
# 		cond = get_search_conditions params[:term], {
# 			'people.first_name' => :like,
# 			'people.last_name' => :like,
# 			'people.ssn' => :like,
# 			'exams.exam_no' => :like,
# 			'exams.title' => :like,
# 		}
# 		if @current_user.agency_level?
# 			access_cond = []
# 			if @current_user.allow_web_post_review
# 				access_cond << 'users_web_exams.user_id = %d' % @current_user.id
# 			end
# 			sub_cond = []
# 			sub_cond << 'certs.agency_id = %d' % @current_user.agency_id if @current_user.agency_id
# 			sub_cond << 'certs.department_id = %d' % @current_user.department_id if @current_user.department_id
# 			sub_cond << 'certs.division_id = %d' % @current_user.division_id if @current_user.division_id
# 			access_cond << sub_cond.join(' and ')
# 			cond << '(' + access_cond.join(') or (') + ')'
# 		end
# 		objs = Applicant.find(:all, {
# 			:include => [:person, :exam, {:web_exam => :users_web_exams}],
# 			:conditions => get_where(cond),
# 			:limit => 20
# 			:joins => 'left join (select * from cert_applicants ca join certs c on ca.cert_id = c.id and date(now()) between c.certification_date and c.return_date )'
# 		})
# 		data = []
# 		objs.each { |o|
# 		
# 		}
# 	end

#end