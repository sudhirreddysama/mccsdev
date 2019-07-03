class CertController < CrudController
	
	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.agency_level? && @current_user.show_cert_lists
		render_nothing and return false
	end
	before_filter :check_access, :except => :autocomplete
	
	def options
		super
		if @current_user.agency_level?
			if !params[:popup]			
				#@view_only = true
				@allow_new = true
				@no_clone = true
			else
				@view_only = true
			end
		end
	end

	def index
		@filter = get_filter({
			:sort1 => 'certs.id',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'certs.id'],
			['Cert. Title', 'certs.title'],
			['Exam No.', 'exams.exam_no'],
			['Department', 'departments.name'],
			['Agency', 'agencies.name'],
			['Exam Title', 'exams.title'],
			['Requested Date', 'certs.requested_date'],
			['Certification Date', 'certs.certification_date'],
			['Return Date', 'certs.return_date']
		]
		cond = get_search_conditions @filter[:search], {
			'certs.id' => :left,
			'certs.title' => :like,
			'exams.exam_no' => :like,
			'departments.name' => :like,
			'agencies.name' => :like,
			'exams.title' => :like
		}

		if @current_user.agency_level?
			@filter.agency_id = @current_user.agency_id if !@current_user.agency_id.blank?
			@filter.department_id = @current_user.department_id if !@current_user.department_id.blank?
			@filter.division_id = @current_user.division_id if !@current_user.division_id.blank?
		end
		if !@filter.department_id.blank?
			@filter.department_id = @filter.department_id.to_i
			cond << 'certs.department_id = %d' % @filter.department_id
		end
		if !@filter.agency_id.blank?
			@filter.agency_id = @filter.agency_id.to_i
			cond << 'certs.agency_id = %d' % @filter.agency_id
		end
		if !@filter.division_id.blank?
			@filter.division_id = @filter.division_id.to_i
			cond << 'certs.division_id = %d' % @filter.division_id
		end	
		
		@filter.statuses ||= []
		
		if !@filter.statuses.empty?
			sub_c = []
			if @filter.statuses.include?('requested')
				sub_c << 'certs.certification_date is null and certs.pending_date is null'
			end
			if @filter.statuses.include?('pending')
				sub_c << '(certs.certification_date is null or certs.certification_date > date(now())) and certs.pending_date <= date(now())'
			end
			if @filter.statuses.include?('certified')
        sub_c << 'certs.certification_date <= date(now()) and certs.return_date >= date(now()) and (certs.completed_date is null or certs.completed_date > date(now()))'
			end			
			if @filter.statuses.include?('expired')
				#sub_c << 'certs.return_date < date(now()) and certs.completed_date is not null'
				sub_c << 'certs.return_date < date(now()) and certs.completed_date is not null and ifnull(certs.finished, "") != ""'
			end
			if @filter.statuses.include?('overdue')
				sub_c << 'certs.return_date < date(now()) and certs.completed_date is null'
			end
			if @filter.statuses.include?('completed')
				#sub_c << 'certs.return_date >= date(now()) and certs.completed_date <= date(now()) and ifnull(certs.finished, "") = ""'
				sub_c << 'certs.completed_date <= date(now()) and ifnull(certs.finished, "") = ""'
			end
			if @filter.statuses.include?('finished')
				sub_c << 'certs.return_date >= date(now()) and ifnull(certs.finished, "") != ""'
			end
			cond << get_where_or(sub_c)
    end
    if params[:popup]
      sub_c = []
      # Disable for now?
      #sub_c << 'certs.certification_date <= date(now()) and certs.return_date >= date(now()) and (certs.completed_date is null or certs.completed_date > date(now()))'
      cond << get_where_or(sub_c)
    end

      @opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:exam, :department, :agency]
		}
		super
	end
	
	def autocomplete
		cond = get_search_conditions(params.search || params.term, {
			'certs.id' => :left,
			'certs.title' => :like,
			'exams.exam_no' => :like,
			'exams.title' => :like
		})
		agency_id = @current_user.agency_level? && @current_user.agency_id || params[:agency_id]
		department_id = @current_user.agency_level? && @current_user.department_id || params[:department_id]
		division_id = @current_user.agency_level? && @current_user.division_id || params[:division_id]
		cond << 'certs.agency_id = %d' % agency_id.to_i if !agency_id.blank?
		cond << 'certs.department_id = %d' % department_id.to_i if !department_id.blank?
		cond << 'certs.division_id = %d' % division_id.to_i if !division_id.blank?
		opt = {
			:limit => 20,
			:conditions => get_where(cond),
			:order => 'certs.id desc',
			:include => :exam
		}
		data = Cert.find(:all, opt)
		render :json => data.collect { |o| 
			o.autocomplete_json_data
		}
	end		
	
	def print
		@opt = {:flags => '--footer-right "[page] of [topage]" --header-right "ID# ' + @obj.id.to_s + '"'}
		super
	end
	
	def excel
		load_obj
		@objs = @obj.cert_applicants.find(:all, {
			:include => [{:applicant => [:person, :exam, :app_status]}, :cert_code],
			:order => 'applicants.final_score desc, applicants.tiebreaker desc'
		})		
		book = Spreadsheet::Workbook.new
		@sheet = book.create_worksheet
		@export_fields = %w{person.last_name person.first_name applicant.final_score app_status.name cert_code.label cert_applicant.action_date.d0? cert_applicant.comments cert_applicant.salary_per}
		@export_fields += %w{person.home_phone person.email person.mailing_address person.mailing_address2 person.mailing_city person.mailing_state person.mailing_zip exam.valid_until}		
		
		if @current_user.staff_level?
			@export_fields += %w{applicant.approved applicant.pos applicant.rank person.ssn person.work_phone person.fax person.cell_phone applicant.raw_score applicant.base_score applicant.veterans_credits applicant.other_credits}
			@export_fields += %w{person.residence_different person.residence_address person.residence_city person.residence_state person.residence_zip}
			@export_fields += %w{person.town.name person.village.name person.fire_district.name person.school_district.name}
			@export_fields += %w{person.race}
		end
		@sheet.row(0).concat(['cert_pos'] + @export_fields)
		@objs.each_with_index { |o, i|
			render_excel_row o, i
		}
		data = StringIO.new
		book.write data
		send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'		
	end
	
	def render_excel_row o, i
		cert_applicant = o
		applicant = o.applicant
		person = applicant.person
		exam = applicant.exam
		app_status = applicant.app_status
		cert_code = o.cert_code
		@sheet[i + 1, 0] = i + 1
		@export_fields.each_with_index { |f, j|
			@sheet[i + 1, j + 1] = instance_eval(f) rescue nil
		}
	end	
	
	def build_obj
		super
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
			@obj.division = @current_user.division if @current_user.division
			@obj.requested_date = Time.now.to_date
			@obj.requestor = @current_user.name
		end
		if !request.post? && @obj.agency
			@obj.department = Department.find_by_name @obj.agency.name
		end
		@obj.job_id = @obj.exam ? @obj.exam.job_id : nil
	end
	
	def check_open_certs
		# Build a fake object to check open certs against it
		build_obj
		@obj.id = params.id
		render :json => @obj.other_open_certs_error_attr.to_json
	end

	def cert_upload
		load_obj
		@ca = @obj.cert_applicants.find(params[:id2])
		@doc = Document.new :cert_applicant => @ca, :uploaded_file => params[:upload]
		if @doc.save
			render :layout => false
		else
			render_nothing
		end
	end
	
	def document_delete
		load_obj
		@ca = @obj.cert_applicants.find(params[:id2])
		@doc = @ca.documents.find params[:id3]
		@doc.destroy
		render_nothing
	end
	
	def ca_download
		load_obj
		@ca = @obj.cert_applicants.find(params[:id2])
		@doc = @ca.documents.find params[:id3]
		send_file @doc.path, :filename => @doc.filename
	end

	def set_action
		load_obj
		@ca = @obj.cert_applicants.find(params[:id2])
		@ca.cert_code_id = params[:act]
		@ca.save
		check_other_certs
		render_nothing
  end
  
  def set_action_all
    load_obj
    @ca = @obj.cert_applicants.find(:all)
    @ca.each_with_index { |o, i|
    	if !o.cert_code
				o.update_attribute :cert_code_id, params[:act]
			end
    }
    render_nothing
  end

	
	def set_status
		load_obj
		@ca = @obj.cert_applicants.find(params[:id2])
		@ca.applicant.app_status_id = params[:sta]
		@ca.applicant.save
		check_other_certs
		render_nothing
	end	
	
	
	
	
	def check_other_certs
		if @ca.applicant.app_status && @ca.applicant.app_status.appointed && @obj.completed_date.nil?
			#CertApplicant.appointed_from_other_cert_cron @ca.id
		end
	end
	
	def other_certs
		load_obj
		params[:popup] = true
		@nonav = true		
		@ca = @obj.cert_applicants.find(params[:id2])
		cond = []
		#cond << 'certs.id != %d' % @obj.id
		if @obj.exam.continuous && @obj.exam.current_exam_id
			cond << ('exams.current_exam_id = %d' % @obj.exam.current_exam_id)
		else
			cond << ('exams.id = %d' % @obj.exam_id)
		end			
		cond << 'applicants.person_id = %d' % @ca.applicant.person_id
		@objs = CertApplicant.find(:all, {
			:include => [{:cert => :exam}, :applicant, :cert_code], 
			:conditions => get_where(cond),
			:order => 'certs.id desc'
		})
	end

	def set_comments
		load_obj
		ca = @obj.cert_applicants.find(params[:id2])
		ca.update_attribute :comments, params[:cmt]
		render_nothing
	end
	
	def set_salary_per
		load_obj
		ca = @obj.cert_applicants.find(params[:id2])
		ca.update_attribute :salary_per, params[:salary_per]
		render_nothing
	end
	
	def set_date
		load_obj
		@ca = @obj.cert_applicants.find(params[:id2])
		@ca.update_attribute :action_date, params[:dte]
		check_other_certs
		render_nothing
	end	
	
	def complete_list
		load_obj
		err = @obj.cert_applicants.find(:first, :include => :cert_code, :conditions => 'cert_codes.id is null')
		if err
			flash[:errors] = ['Could not complete list. You must select an action for each candidate. If no action was taken select "NO ACTION"']
		else
			@obj.completed_by = @current_user
			@obj.completed_date = Time.now.to_date
			@obj.save
			u = Agency.get_liaison(@obj.agency, @obj.department)
			if u
				Notifier.deliver_cert_complete [u], @obj
			end
			flash[:notice] = 'Certified list has been completed and submitted to HR.'
		end
		redirect_to :action => :view, :id => @obj.id
	end

	def import_applicants
		load_obj
		@select = (params[:select] && !params[:do_reset]) ? params[:select] : {:only_active => '1'}
		
		@select[:town_ids].map! &:to_i if @select[:town_ids]
		@select[:village_ids].map! &:to_i if @select[:village_ids]
		@select[:fire_ids].map! &:to_i if @select[:fire_ids]
		@select[:school_ids].map! &:to_i if @select[:school_ids]
		
		if request.post? && params[:do_import]
			DB.query('delete from cert_applicants where cert_id = %d', @obj.id)
			params[:applicant_ids] ||= []
			params[:applicant_ids].each { |applicant_id|
				a = Applicant.find applicant_id
				@obj.cert_applicants.create({
					:applicant_id => a.id,
					:person_id => a.person_id
				})
			}
			flash[:notice] = 'Applicants have been imported.'
			redirect_to :action => :view, :id => @obj.id
		else
			
			if !request.post? || params[:do_reset]
				@applicant_ids = @obj.cert_applicants.collect { |ca| ca.applicant_id }
			end
			
			cond = ['applicants.pos != 0']
			if @obj.exam.continuous && @obj.exam.current_exam_id
				@e = Exam.find @obj.exam.current_exam_id
				cond << ('exams.current_exam_id = %d and exams.valid_until >= date(now())' % @e.id)
			else
				cond << ('exams.id = %d' % @obj.exam_id)
			end
			
			cond << 'app_statuses.id is not null'
		
			@objs = Applicant.find(:all, {
				:order => 'applicants.pos',
				:conditions => get_where(cond),
				:include => [:app_status, :exam, {:person => [:town, :village, :school_district, :fire_district]}]
			})
			
			objs_ids = @objs.map &:id
			@extra_objs = @obj.cert_applicants.select { |ca| !objs_ids.include?(ca.applicant_id) }.map &:applicant
		
		end
	end
	
	def save_redirect
		super
		if params[:action] == 'new' && @current_user.agency_level?
			u = Agency.get_liaison(@obj.agency, @obj.department)
			if u
				Notifier.deliver_cert_request [u], @obj
			end
		end
	end
	
	def view
		load_notify_agency_users
		super
	end
	
	def notify_agency
		load_obj
		load_notify_agency_users
		@obj.update_attribute :notified_date, Time.now.to_date
		if @notify_agency_users.empty?
			flash[:notice] = 'No agency users to send notice to.'
		else
			@notify_agency_users.each { |u|
				Notifier.deliver_cert [u], @obj
			}
			flash[:notice] = 'Notification email has been sent.'
		end		
		redirect_to :action => :view, :id => @obj.id
	end
	
	def load_notify_agency_users
		cond = [@obj.division ? 'users.division_id is null or users.division_id = %d' % @obj.division.id : 'users.division_id is null']
		@notify_agency_users = @obj.agency ? @obj.agency.get_users(@obj.department, false, cond) : []	
	end
		
	def notify_specialist
		load_obj
		flash[:notice] = 'Notification email has been sent.'
		if @obj.status == 'requested'
			@obj.update_attribute :pending_date, Time.now.to_date
		elsif @obj.status == 'completed'
			@obj.update_attribute :prefinished_date, Time.now.to_date
		end
		Notifier.deliver_cert_specialist @obj
		redirect_to :action => :view, :id => @obj.id
	end

	def view_applicant
		load_obj
		@cert_applicant = @obj.cert_applicants.find(params[:id2])
		@applicant = @cert_applicant.applicant
	end
	
	def select_end_of_list
		@texts = DB.query('
			select count(c.id) c, trim(trim("*" from replace(replace(replace(c.end_of_list, "\t", ""), "\r", ""), "\n", ""))) txt
			from certs c group by txt having c > 1 and txt != "" order by c desc
		');
		render :template => 'partial/select_text'
	end
	
	def select_bottom_note
		@texts = DB.query('
			select count(c.id) c, trim(trim("*" from trim("\n" from trim("\r" from c.bottom_note)))) txt
			from certs c group by txt having c > 1 and txt != "" order by c desc
		');
		render :template => 'partial/select_text'
	end
	
	def recertify
		if request.post?
			load_obj
			old = @obj
			@obj = @obj.clone
			@obj.certification_date = nil
			@obj.return_date = nil
			@obj.completed_date = nil
			@obj.completed_by_id = nil
			@obj.requested_date = nil
			@obj.notified_date = nil
			@obj.pending_date = nil
			@obj.prefinished_date = nil
			@obj.show_actions = 0
			@obj.finished = nil
			@obj.recert_from_id = old.id
			if @obj.save
				old.cert_applicants.each { |ca|
					cc = ca.cert_code
					if !cc or cc.code == 'X' or cc.code == 'NA'
						@obj.cert_applicants << ca.clone
					end
				}
				flash[:notice] = 'New certification has been created with the same applicants.'
			else
				flash[:errors] = @obj.errors.full_messages
				@obj = old
			end
		end
		redirect_to :action => :view, :id => @obj.id
	end
	
end