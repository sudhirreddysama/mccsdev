class WebExamController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.agency_level? && @current_user.perm_ag_web_posts
		render_nothing and return false
	end
	before_filter :check_access

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
		if @current_user.agency_level? #and !@current_user.view_web_post_for_agency?
			cond << 'users_web_exams.user_id = %d' % @current_user.id
    end
    #if @current_user.agency_level? and @current_user.view_web_post_for_agency?
      #cond << "#{HRAPPLYDB}.exams.exam_type_id = 4"
    #end
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
	
	# Copy pasted from applicant_controller
	def applicant_print
		load_obj
		@obj = @obj.applicants.find params[:id2]
		docs = []
		wa = @obj.web_applicant
		if wa
			f = TempfileExt.open "applicant-#{@obj.id}-main.pdf", 'tmp'
			f.close
			IO.popen('HTMLDOC_NOCGI=TRUE;export HTMLDOC_NOCGI;htmldoc -f ' + f.path + ' -t pdf --path "/home/rails/hrapply/public/images" --webpage --header "..." --footer "..." --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 8 --headfootfont Arial --headfootsize 8 -', 'w+') { |io|
				html = render_to_string(:layout => false, :template => 'applicant/print')
				io.puts html
				io.close_write
			}
			docs << f.path
		end
		@obj.documents.each { |d|
			docs << d.path
		}
		if wa
			wa.web_attachments.each { |d|
				docs << d.pdf_path
			}
		end
		docs_arg = docs.collect { |d| Shellwords.escape d }.join ' '
		f = TempfileExt.open "applicant-#{@obj.id}.pdf", 'tmp'
		f.close
		`pdftk #{docs_arg} cat output #{f.path}`
		send_file f.path, :filename => "application-#{@obj.id}.pdf"
	end	
	
	# 
	def web_attachment
		load_obj
		@obj = @obj.applicants.find params[:id2]
		f = @obj.web_attachments.find(params[:id3])
		send_file f.pdf_path, :filename => File.basename(f.name, File.extname(f.name)) + '.pdf'
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
  
  #def social_media
  #  load_obj
  #  super
  #end
	
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
			['Disapproved/Approved', 'applicants.approved']
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
		if @current_user.agency_level? && !@current_user.allow_web_post_review
			cond << 'applicants.approved = "Y"'
		else			
			sub_cond = []
			sub_cond << 'applicants.approved = "Y"' if @filter.status_approved == '1'
			sub_cond << 'applicants.approved = "N"' if @filter.status_disapproved == '1'
			sub_cond << 'ifnull(applicants.approved, "") = ""' if @filter.status_na == '1'
			cond << '(' + sub_cond.join(') or (') + ')' if !sub_cond.empty?
		end		
		cond << get_date_cond		
		include = [:person, :web_exam]
		join = nil
		if params[:action] == 'all_applicants'
    	#if !@current_user.view_web_post_for_agency?
				join = 'join users_web_exams uwe on uwe.web_exam_id = applicants.web_exam_id and uwe.user_id = %d' % @current_user.id
     	#end 
			@model = Applicant
		else
			load_obj
			@assoc = @obj.applicants
		end
		
		adv_cond, extra_joins = parse_advanced_applicant_filter
		cond += adv_cond
		join = ([join] + extra_joins).compact * ' '
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => include,
			:joins => join
		}
		if @adv_search
			@opt[:group] = 'applicants.id'
		end
		
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
		elsif params[:approve_all]
			app_status_a = AppStatus.find_by_code 'A'
			app_status_d = AppStatus.find_by_code 'D'
			find_on = @assoc || @model
			@objs = find_on.find(:all, @opt)
			@objs.each { |o|
				o.approved = 'Y'
				if !o.app_status || o.app_status_id == app_status_d.id
					o.app_status_id = app_status_a.id
				end
				o.save
			}
			redirect_to
		elsif params[:overview_report]
			@paginate = false
			@opt[:limit] = 500
			fetch_objs
			render_pdf render_to_string(:template => 'applicant/overview_report', :layout => false), 'report.pdf'
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
			`wkhtmltopdf --disable-smart-shrinking --footer-html /home/rails/mccs/app/views/web_exam/new_exams_footer.html -s Letter -O Portrait --margin-left .5in --margin-right .5in --margin-top .5in --margin-bottom 1in #{f.path} public/new-exams/#{@fname}`					
			
			if params[:resend]
				@system = System.find(:first)
				emails = params[:emails]
				if params[:emails].blank?
					emails = @system.exam_emails
				end
				emails.to_s.split(/[,\r\n]/).collect(&:strip).reject(&:blank?).each { |e|
					Notifier.deliver_new_exams e, @fname, params[:txt]
				}
			end
			render :inline => "<a href=\"/mccs" + (RAILS_ENV == 'development' ? 'dev' : '') + "/new-exams/#{@fname}\">#{@fname}</a>"
		end
	end
	skip_before_filter :authenticate, :only => :send_exam_emails
	skip_before_filter :check_access, :only => :send_exam_emails

	def social
	end

	def get_facebook_client
		@facebook_client = Koala::Facebook::OAuth.new(
			FACEBOOK_KEY, 
			FACEBOOK_SECRET, 
			url_for(:action => :facebook_callback)
		)
	end
	
	def facebook_oauth
		exams = WebExam.find(:all, :order => 'name, no', :conditions => 'published = 1 and publish < now() and facebook_posted = 0')	
		if exams.length > 0
			message = ''
			exams.each { |e|
				p "Posting to Facebook: #{e.id} #{e.no} #{e.name}"
				message += [e.no, e.name].reject(&:blank?).join(' ') + "\n"
				e.update_attribute :facebook_posted, true
			}
			System.find(:first).update_attribute :last_facebook_update, "New Exam/Job Announcements: \n#{message}Apply Now: https://cs.monroecounty.gov/hrapply"
			flash[:notice] = 'Facebook post text updated.'
		else
			flash[:errors] = ['No new exams to post to Facebook!']
		end
		redirect_to :action => :social
		
		return # facebook disabled their api
		get_facebook_client
		redirect_to @facebook_client.url_for_oauth_code(:permissions => 'email,publish_actions,manage_pages')
	end
	
	def facebook_callback
		get_facebook_client
		access_token = @facebook_client.get_access_token(params[:code])
		graph = Koala::Facebook::API.new(access_token)
		#res = graph.get_connections('me', 'accounts');
		
		page_token = graph.get_page_access_token('398465983501035')
		page_graph = Koala::Facebook::API.new(page_token)
		
		exams = WebExam.find(:all, :order => 'name, no', :conditions => 'published = 1 and publish < now() and facebook_posted = 0')	
		p "Exams To Post to Facebook: #{exams.length}"
		if exams.length > 0
			message = ''
			exams.each { |e|
				p "Posting to Facebook: #{e.id} #{e.no} #{e.name}"
				message += [e.no, e.name].reject(&:blank?).join(' ') + "\n"
				e.update_attribute :facebook_posted, true
			}
			page_graph.put_wall_post("New Exam/Job Announcements: \n#{message}Apply Now: cs.monroecounty.gov/hrapply");
			#graph.put_connections('me', 'feed', :message => "New Exam/Job Announcements: \n#{message}Apply Now: cs.monroecounty.gov/hrapply")
		end
		p 'Facebook Done'		
		flash[:notice] = 'Exams have been posted to Facebook.'
		redirect_to :action => :social
	end
	
	def get_twitter_client
		@twitter_client = TwitterOAuth::Client.new(
			:consumer_key => TWITTER_KEY, 
			:consumer_secret => TWITTER_SECRET
		)
	end
	
	def twitter_oauth
		get_twitter_client
		callback_url = url_for(:action => :twitter_callback)
		logger.info callback_url
		request_token = @twitter_client.authentication_request_token(:oauth_callback => callback_url)
		session[:twitter_token] = request_token.token
		session[:twitter_secret] = request_token.secret
		redirect_to request_token.authorize_url
	end
	
	def twitter_callback
		get_twitter_client
		access_token = @twitter_client.authorize(
			session[:twitter_token],
			session[:twitter_secret],
			:oauth_verifier => params[:oauth_verifier]
		)
		exams = WebExam.find(:all, :order => 'name, no', :conditions => 'published = 1 and publish < now() and twitter_posted = 0')	
		logger.info "Exams To Post to Twitter: #{exams.length}"
		if exams.length > 0
			exams.each { |e|
				logger.info "Posting to Twitter: #{e.id} #{e.no} #{e.name}"
				# NOTE: "Apply*Online:*" contains non-breaking space characters!
				@twitter_client.update 'New Exam/Job: ' + [e.no, e.name].reject(&:blank?).join(' ') + " Apply Online: cs.monroecounty.gov/hrapply/apply/exam/#{e.id}"
				e.update_attribute :twitter_posted, true
			}
		end
		logger.info 'Twitter Done'
		flash[:notice] = 'Exams have been posted to Twitter.'
		redirect_to :action => :social
	end

end