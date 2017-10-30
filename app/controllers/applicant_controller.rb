class ApplicantController < CrudController

	def index
		
		@filter = get_filter({
			:sort1 => 'applicants.submitted_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'applicants.id'],
			['SSN', 'people.ssn'],
			['First Name', 'people.first_name'],
			['Last Name', 'people.last_name'],
			['Status', 'app_statuses.name'],
			['Exam No.', 'exams.exam_no'],
			['Submitted', 'applicants.submitted_at'],
			['Title', 'exams.title'],
			['Exam Date', 'exams.given_at'],
			['Web Post', 'we.name'],
			['Web Type', 'et.short_name'],
		]
		cond = get_search_conditions @filter[:search], {
			'applicants.id' => :left,
			'people.first_name' => :like,
			'people.last_name' => :like,
			'people.ssn' => :like,
			'exams.exam_no' => :like,
			'exams.title' => :like,
			'we.name' => :like,
			'et.short_name' => :like,
			'app_statuses.name' => :left,
		}
		@date_types = [
			['Date Submitted', 'applicants.submitted_at'],
			['Exam Date', 'exams.given_at'],
			['Established Date', 'exams.established_date'],
			['Exam Expiration Date', 'exams.valid_until']
		]
		cond << 'exams.id is null' if @filter[:no_exam] == '1'
		cond << get_date_condx
		
		extra_joins = []
		include_web_applicant = false
		
		if !@filter.wem_search.blank? || @filter.wem_current == '1'
			cond += get_search_conditions @filter[:wem_search], {
				'wem.name' => :like,
				'wem.title' => :like,
				'wem.description' => :like,
			}
			cond << 'wem.currently_employed = 1' if @filter.wem_current == '1'
			extra_joins << 'join ' + HRAPPLYDB + '.employments wem on wem.applicant_id = wa.id'
		end
		if !@filter.wce_search.blank? || @filter.wce_valid == '1'
			cond += get_search_conditions @filter[:wce_search], {
				'wce.name' => :like,
				'wce.agency' => :like,
			}
			cond << 'wce.permanent = 1 or wce.to_date > date(now())' if @filter.wce_valid == '1'
			extra_joins << 'join ' + HRAPPLYDB + '.certifications wce on wce.applicant_id = wa.id'
		end	
		wed_sem_h = @filter.wed_sem_hours.to_i
		wed_qua_h = @filter.wed_qua_hours.to_i	
		if !@filter.wed_search.blank? || wed_sem_h != 0 || wed_qua_h != 0
			cond += get_search_conditions @filter[:wed_search], {
				'wed.school_name' => :like,
				'wed.major' => :like,
				'wed.degree' => :like,
			}
			h_cond = [
				('wed.credits_semester >= %d' % wed_sem_h if wed_sem_h != 0),
				('wed.credits_quarter >= %d' % wed_qua_h if wed_qua_h != 0)
			].compact
			cond << h_cond.join(' or ') if !h_cond.empty?
			extra_joins << 'join ' + HRAPPLYDB + '.educations wed on wed.applicant_id = wa.id'
		end	
		wtr_h = @filter.wtr_hours.to_f
		if !@filter.wtr_search.blank? || wtr_h != 0
			cond += get_search_conditions @filter[:wtr_search], {
				'wtr.description' => :like,
			}
			cond << 'wtr.hours >= %f' % wtr_h if wtr_h != 0
			extra_joins << 'join ' + HRAPPLYDB + '.trainings wtr on wtr.applicant_id = wa.id '
		end
		if !@filter.wed_level.blank?
			lvls = WebApplicant::EDUCATION_LEVELS.map &:last
			cond << 'case wa.education ' + 
				lvls.each_with_index.map { |v, i| DB.escape 'when "%s" then %d', v, i }.join(' ') + 
				(' end >= %d' % lvls.index(@filter.wed_level))
			include_web_applicant = true
		end				
		if !extra_joins.empty? || include_web_applicant
			extra_joins.unshift 'join ' + HRAPPLYDB + '.applicants wa on wa.id = applicants.web_applicant_id'
			@adv_search = true
		end
		extra_joins << 'left join ' + HRAPPLYDB + '.exams we on we.id = applicants.web_exam_id'
		extra_joins << 'left join ' + HRAPPLYDB + '.exam_types et on et.id = we.exam_type_id'
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:person, :exam, :app_status],
			:joins => extra_joins * ' ',
		}
		if @adv_search
			@opt[:group] = 'applicants.id'
		end
   	super
	end

	def web_import
		if request.post?
			WebApplicant.web_import
			flash[:notice] = 'Web import complete.'
			redirect_to :action => :index
		end
	end
	
	def web_attachment
		load_obj
		f = @obj.web_attachments.find(params[:id2])
		send_file f.pdf_path, :filename => File.basename(f.name, File.extname(f.name)) + '.pdf'
	end
	
	def web_attachment_copy
		load_obj
		f = @obj.web_attachments.find(params[:id2])
		@obj.person.documents.create({
			:uploaded_file => {
				:original_filename => File.basename(f.name, File.extname(f.name)) + '.pdf',
				:path => f.pdf_path
			}
		})
		flash[:notice] = 'Application attachment has been copied to person record.'
		redirect_to :sc => :applicant, :sid => @obj.id, :controller => :document, :action => :index, :id => nil
	end
	
	def checks_report
	
		@objs = Applicant.find(:all, {
			:include => [:person, :exam], 
			:order => 'people.last_name asc, people.first_name asc',
			:conditions => 'applicants.paid_by in ("K", "M") and applicants.check_confirmed = 0 and exams.fee > 0'
		})
		
		if request.post?
			@paid = []
			@unpaid = []
			
			@objs.each { |o|
				attr = params[:objs][o.id.to_s]
				if attr
					o.update_attributes attr
					if o.paid_by == 'K' or o.paid_by == 'M'
						if o.check_confirmed
							@paid << o
						else
							@unpaid << o
						end
					end
				end
			}
			
			@report = CheckReport.create
			
			@mode = 'paid'
			html = render_to_string :action => :checks_pdf, :layout => false
			render_pdf_to_file html, "check_reports/#{@report.id}-paid.pdf", :orient => 'Landscape'
			
			@mode = 'unpaid'
			html = render_to_string :action => :checks_pdf, :layout => false
			render_pdf_to_file html, "check_reports/#{@report.id}-unpaid.pdf", :orient => 'Landscape'
			
			flash[:notice] = 'Applications have been updated.'
			redirect_to
		else
			@reports = CheckReport.find(:all, :order => 'check_reports.created_at desc', :limit => 10)
		end
	end
	
	def checks_file
		send_file "check_reports/#{params[:id]}-#{params[:id2]}.pdf"
	end
	
	def admin_notes
		load_obj
		if params[:educations]
			n = @obj.applicant_notes.find_or_create_by_object_type_and_object_id 'education', params[:id2]
			v = params[:educations]
			#@obj.web_applicant.web_educations.find(params[:id2]).update_attribute :admin_notes, params[:educations]
		elsif params[:employments]
			n = @obj.applicant_notes.find_or_create_by_object_type_and_object_id 'employment', params[:id2]
			v = params[:employments]
			#@obj.web_applicant.web_employments.find(params[:id2]).update_attribute :admin_notes, params[:employments]
		elsif params[:certifications]
			n = @obj.applicant_notes.find_or_create_by_object_type_and_object_id 'certification', params[:id2]
			v = params[:certifications]
			#@obj.web_applicant.web_certifications.find(params[:id2]).update_attribute :admin_notes, params[:certifications]
		elsif params[:trainings]
			n = @obj.applicant_notes.find_or_create_by_object_type_and_object_id 'training', params[:id2]
			v = params[:trainings]
			#@obj.web_applicant.web_trainings.find(params[:id2]).update_attribute :admin_notes, params[:trainings]
		elsif params[:applicant]
			@obj.update_attribute :notes, params[:applicant]
		elsif params[:list]
			@obj.update_attribute :list_note, params[:list]
		elsif params[:seniority_date]
			@obj.update_attribute :seniority_date, params[:seniority_date]
		end
		
		if n
			if v.blank?
				n.destroy
			else
				n.update_attribute :notes, v
			end
		end
		
		render_nothing
	end

	def print
		docs = []
		wa = @obj.web_applicant
		if wa
			f = TempfileExt.open "applicant-#{@obj.id}-main.pdf", 'tmp'
			f.close
			IO.popen('HTMLDOC_NOCGI=TRUE;export HTMLDOC_NOCGI;htmldoc -f ' + f.path + ' -t pdf --path "/home/rails/hrapply/public/images" --webpage --header "..." --footer "..." --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 8 --headfootfont Arial --headfootsize 8 -', 'w+') { |io|
				html = render_to_string(:layout => false)
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





	def web_export
		if request.post?
							
			DB.query 'truncate table public_people'
			DB.query 'insert into public_people select * from people'
			
			if params[:export_certs]

				DB.query 'truncate table public_cert_applicants'
				DB.query 'insert into public_cert_applicants select ca.* from cert_applicants ca
					join certs c on c.id = ca.cert_id
					where c.certification_date is not null'			

				DB.query 'truncate table public_certs'
				DB.query 'insert into public_certs select * from certs'
				
				DB.query 'truncate table public_list_notes'
				DB.query 'insert into public_list_notes select * from list_notes'
			
			else
						
				DB.query 'truncate table public_applicants'
				DB.query 'insert into public_applicants select * from applicants'
			
				DB.query 'truncate table public_exams'
				DB.query 'insert into public_exams select * from exams'				
			
			end
			
			flash[:notice] = 'Web export complete.'
			redirect_to :action => :index
		end
	end

	
end


