class CertController < CrudController

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
			cond << 'agencies.id = %d' % @current_user.agency_id
			cond << 'departments.id = %d' % @current_user.department_id if @current_user.department
		end
		
		@filter.statuses ||= []
		
		if !@filter.statuses.empty?
			sub_c = []
			if @filter.statuses.include?('requested')
				sub_c << 'certs.certification_date is null and certs.pending_date is null'
			end
			if @filter.statuses.include?('expired')
				sub_c << 'certs.return_date < date(now()) and certs.completed_date is not null'
			end
			if @filter.statuses.include?('pending')
				sub_c << '(certs.certification_date is null or certs.certification_date > date(now())) and certs.pending_date <= date(now())'
			end			
			if @filter.statuses.include?('overdue')
				sub_c << 'certs.return_date < date(now()) and certs.completed_date is null'
			end
			if @filter.statuses.include?('certified')
        sub_c << 'certs.certification_date <= date(now()) and certs.return_date >= date(now()) and (certs.completed_date is null or certs.completed_date > date(now()))'
			end
			if @filter.statuses.include?('completed')
				sub_c << 'certs.return_date >= date(now()) and certs.completed_date <= date(now()) and ifnull(certs.finished, "") = ""'
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
		@export_fields = %w{person.last_name person.first_name final_score person.home_phone}
		@export_fields += %w{person.email person.mailing_address person.mailing_address2 person.mailing_city person.mailing_state person.mailing_zip exam.valid_until}		
		if @current_user.staff_level?
			@export_fields += %w{approved app_status.name pos rank person.ssn person.work_phone person.fax person.cell_phone raw_score base_score veterans_credits other_credits}
			@export_fields += %w{person.residence_different person.residence_address person.residence_city person.residence_state person.residence_zip}
			@export_fields += %w{person.town.name person.village.name person.fire_district.name person.school_district.name}
		end
		@sheet.row(0).concat(['cert_pos'] + @export_fields)
		@objs.each_with_index { |o, i|
			a = o.applicant
			@sheet[i + 1, 0] = i + 1
			@export_fields.each_with_index { |f, j|
				@sheet[i + 1, j + 1] = a.instance_eval(f) rescue nil
			}
		}
		data = StringIO.new
		book.write data
		send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'		
	end
	
	def build_obj
		super
		if @current_user.agency_level?
			@obj.agency = @current_user.agency if @current_user.agency
			@obj.department = @current_user.department if @current_user.department
			@obj.requested_date = Time.now.to_date
			@obj.requestor = @current_user.name
		end		
		@obj.job_id = @obj.exam ? @obj.exam.job_id : nil
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
		ca = @obj.cert_applicants.find(params[:id2])
		ca.update_attribute :cert_code_id, params[:act]
		render_nothing
  end
  def set_action_all
    load_obj
    ca = @obj.cert_applicants.find(:all)
    ca.each_with_index { |o, i|
      o.update_attribute :cert_code_id, params[:act]
    }

    render_nothing
  end

	
	def set_status
		load_obj
		ca = @obj.cert_applicants.find(params[:id2])
		ca.applicant.update_attribute :app_status_id, params[:sta]
		render_nothing
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
		ca = @obj.cert_applicants.find(params[:id2])
		ca.update_attribute :action_date, params[:dte]
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
	
	def notify_agency
		load_obj
		users = @obj.agency ? @obj.agency.get_users(@obj.department) : []
		if users.empty?
			flash[:notice] = 'No agency users to send notice to.'
		else
			users.each { |u|
				Notifier.deliver_cert [u], @obj
			}
			flash[:notice] = 'Notification email has been sent.'
		end		
		redirect_to :action => :view, :id => @obj.id
	end
		
	def notify_specialist
		load_obj
		Notifier.deliver_cert_specialist @obj
		flash[:notice] = 'Notification email has been sent.'
		@obj.update_attribute :pending_date, Time.now.to_date
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
	
end