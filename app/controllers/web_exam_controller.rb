class WebExamController < CrudController

	def index
		@filter = get_filter({
			:sort1 => "#{HRAPPLYDB}.exams.publish",
			:dir1 => 'desc'
		})
		@orders = [
			['ID', "#{HRAPPLYDB}.exams.id"],
			['Name', "#{HRAPPLYDB}.exams.name"],
			['Publish Date', "#{HRAPPLYDB}.exams.publish"],
			['Deadline', "#{HRAPPLYDB}.exams.deadline"],
			['Exam Date', "#{HRAPPLYDB}.exams.exam_date"],
			['Type', "#{HRAPPLYDB}.exam_types.short_name"]
		]
		cond = get_search_conditions @filter[:search], {
			"#{HRAPPLYDB}.exams.id" => :left,
			"#{HRAPPLYDB}.exams.name" => :like,
			"#{HRAPPLYDB}.exams.no" => :like,
			"#{HRAPPLYDB}.exam_types.short_name" => :like
		}
		if @current_user.agency_level? and !@current_user.view_web_post_for_agency?
			cond << 'users_web_exams.user_id = %d' % @current_user.id
    end
    if @current_user.agency_level? and @current_user.view_web_post_for_agency?
      cond << "#{HRAPPLYDB}.exams.exam_type_id = 4"
    end
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:web_exam_type, :users, :web_exam_total]
		}
		super
	end
	
	def applicant
		load_obj
		@applicant = @obj.applicants.find params[:id2]
	end
	
	def agency_access
		load_obj
		if request.post?
			@obj.user_ids = params[:user_ids] || []
			flash[:notice] = 'Agency access has been updated.'
			redirect_to :action => :view, :id => @obj.id
		else
			users = User.find(:all, :conditions => 'users.level in ("agency", "agency-head")')
			@grouped_users = {}
			users.each { |u|
				a = u.agency ? u.agency.name : 'NO AGENCY'
				d = u.department ? u.department.name : 'NO DEPT'
				s = "#{a} - #{d}"
				@grouped_users[s] ||= []
				@grouped_users[s] << u
			}
		end
  end
  def social_media
    load_obj
    super
  end
	
	def applicants_save
		load_obj
		if request.post? && params[:applicant]
			params[:applicant].each { |id, attr|
				a = @obj.applicants.find(id)
				a.update_attributes attr
			}
		end
		render_nothing
	end
	
	def auto_status
		load_obj
		@obj.applicants.find(:all, {
			:include => :app_status,
			:conditions => 'app_statuses.id is null'
		}).each { |a|
			wa = a.web_applicant
			if wa
				county = wa.residence_different ? wa.res_county : wa.county
				if wa.over_18 and county == 'MONROE'
					a.update_attributes :approved => 'Y', :app_status_id => 5
				else
					a.update_attributes :approved => 'N', :app_status_id => 3
				end
			end
		}
		flash[:notice] = 'Applicants have been updated.'
		redirect_to :action => :applicants, :id => @obj.id
	end
	
	def all_applicants
		applicants
	end
	
	def applicants
		@statuses = AppStatus.find(:all, :order => 'app_statuses.name')
		@filter = get_filter({
			:sort1 => 'applicants.submitted_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'applicants.id'],
			['SSN', 'people.ssn'],
			['First Name', 'people.first_name'],
			['Last Name', 'people.last_name'],
			['Submitted', 'applicants.submitted_at'],
		]
		cond = get_search_conditions @filter[:search], {
			'applicants.id' => :left,
			'people.first_name' => :like,
			'people.last_name' => :like,
			'people.ssn' => :like,
		}
		@date_types = [
			['Date Submitted', 'applicants.submitted_at'],
		]
		if @current_user.agency_level?
			cond << 'applicants.approved = "Y"'
		end		
		cond << get_date_cond		
		include = [:person, :web_exam]
		join = nil
		if params[:action] == 'all_applicants'
     if !@current_user.view_web_post_for_agency?
			join = 'join users_web_exams uwe on uwe.web_exam_id = applicants.web_exam_id and uwe.user_id = %d' % @current_user.id
     end 
			@model = Applicant
		else
			load_obj
			@assoc = @obj.applicants
		end
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => include,
			:joins => join
		}
		
		@export_fields = %w{approved app_status.name pos rank person.ssn person.last_name person.first_name person.home_phone person.work_phone person.fax person.cell_phone person.email person.mailing_address person.mailing_address2 person.mailing_city person.mailing_state person.mailing_zip raw_score base_score veterans_credits other_credits final_score}
		@export_fields += %w{person.residence_different person.residence_address person.residence_city person.residence_state person.residence_zip person.town.name person.village.name person.fire_district.name person.school_district.name exam.valid_until person.date_of_birth.d0?}			
		
		if params[:export]
			find_on = @assoc || @model
			@objs = find_on.find(:all, @opt)
			book = Spreadsheet::Workbook.new
			sheet = book.create_worksheet
			sheet.row(0).concat(@export_fields)
			@objs.each_with_index { |o, i|
				@export_fields.each_with_index { |f, j|
					sheet[i + 1, j] = o.instance_eval(f) rescue nil
				}
			}
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'			
		else
			fetch_objs
		end
	end
	
	def new
		@obj.new_web_new_category_ids = [] if request.post? && params[:obj][:new_web_new_category_ids].nil?
		super
	end
	
	def build_obj
		super
		if params[:exam_id] && !request.post?
			exam = Exam.find_by_id params[:exam_id]
			if exam
				@obj.no = exam.exam_no
				@obj.name = exam.title.titleize
				@obj.publish = exam.publish_at
				@obj.deadline = exam.deadline
				@obj.exam_date = exam.given_at
				@obj.price = exam.fee
			end
		end
	end
	
	def edit
		@obj.new_web_new_category_ids = [] if request.post? && params[:obj][:new_web_new_category_ids].nil?
		super
	end
	
	def move_to_list
		load_obj
		@objs = @obj.applicants.find(:all, :conditions => 'applicants.exam_id is null', :include => :person)
		if request.post?
			if params[:exam_no].blank?
				@errors = ['Exam no is required.']
			else
				@exam = Exam.find_by_exam_no params[:exam_no]	
				if @exam
					@objs.each { |o|
						o.update_attribute :exam_id, @exam.id
					}
					redirect_to
					flash[:notice] = 'Applicants have been moved to the specified exam no'
				else
					@errors = ['Exam not found']
				end
			end
		end
	end

	def exam_emails
		@system = System.find(:first)
		if request.post?
			@system.update_attribute :exam_emails, params[:exam_emails]
			flash[:notice] = 'Exam emails have been updated.'
			redirect_to
		end
	end
	
	def send_exam_emails
		if !params[:id].blank?
			d = Date.parse(params[:id])
		else
			d = Time.now.to_date
		end
		d2 = d.advance(:days => -1)
		@objs = WebExam.find(:all, :conditions => "publish between '#{d2} 16:00:01' and '#{d} 16:00:00' and exam_date is not null and published = 1", :order => 'name, no')
		if @objs.empty?
			render :inline => 'No exams found.'
		else
			@fname = "#{d.to_s}.pdf"
			html = render_to_string :action => :new_exams, :layout => false
			
			f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
			f.write html
			f.close
			`wkhtmltopdf9 --footer-html /home/rails/mccs/app/views/web_exam/new_exams_footer.html -s Letter -O Portrait --margin-left .5in --margin-right .5in --margin-top .5in --margin-bottom 1in --ignore-load-errors #{f.path} public/new-exams/#{@fname}`					
			
			if !params[:id] || params[:resend]
				@system = System.find(:first)
				emails = @system.exam_emails.to_s.split(/[,\r\n]/).collect(&:strip).reject(&:blank?)
				emails.each { |e|
					Notifier.deliver_new_exams e, @fname
				}
			end
			render :inline => "<a href=\"/mccs/new-exams/#{@fname}\">#{@fname}</a>"
		end
	end
	skip_before_filter :authenticate, :only => :send_exam_emails
	
end