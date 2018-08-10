class ExamController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'exams.id',
			:dir1 => 'desc',
		})
		@orders = [
			['ID', 'exams.id'],
			['Exam No.', 'exams.exam_no'],
			['Title', 'exams.title'],
			['Exam Date', 'exams.given_at'],
			['Established Date', 'exams.established_date'],
			['Expiration Date', 'exams.valid_until']
		]
		cond = get_search_conditions @filter[:search], {
			'exams.id' => :left,
			'exams.exam_no' => :like,
			'exams.title' => :like
		}
		
		#cond << 'exams.established_date <= date(now())' unless @current_user.staff_level?
		
		@date_types = [
			['Exam Date', 'exams.given_at'],
			['Established Date', 'exams.established_date'],
			['Expiration Date', 'exams.valid_until']
		]
		
		cond << get_date_condx
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => {:applicants => :app_status}
		}
		
		@export_fields = %w{id exam_no title requested_at publish_at deadline given_at exam_type program_no established_date valid_until comments continuous training_experience bandscored salary fee calculator scores_date exam_length sort_by_department}
		
		super
	end
	
  def get_job
    load_obj
    if @obj
      atr = {
          :id => @obj.job_id,
      }
      render :json => atr.to_json
    else
      render_nothing
    end
  end
  
	def set_review
		load_obj
		@obj.reviewed_by = params[:reviewed_by]
		@obj.review_complete = params[:review_complete]
		@obj.save
		redirect_to :action => :view, :id => @obj.id
		flash[:notice] = 'Review information updated.'
	end
	
	def calendar
	end
	
	def calendar_data
		from = Date.parse(params.from)
		to = Date.parse(params.to)
		objs = Exam.find(:all, :conditions => ['exams.given_at between ? and ?', from, to])
		events = []
		objs.each { |e|
			duration = e.exam_length.to_f
			endt = duration > 0 ? e.given_at + duration.hours : nil
			events << {
				:id => e.id,
				:title => e.title, 
				:start => e.given_at.strftime('%Y-%m-%d %H:%M:%S'),
				:end => endt ? endt.strftime('%Y-%m-%d %H:%M:%S') : nil,
				:url => url_for(:controller => :exam, :action => :view, :id => e.id)
			}
		}
		render :json => events.to_json
	end
	
	def sessions
		@filter = get_filter({
			:sort1 => 'exam_site_sessions.given_on',
			:dir1 => 'desc',
		})
		@orders = [
			['ID', 'exam_site_sessions.id'],
			['Exam Site', 'exam_sites.name'],
			['Given On', 'exam_site_sessions.given_on'],
		]
		cond = get_search_conditions @filter[:search], {
			'exam_site_sessions.id' => :left,
			'exam_sites.name' => :like,
			'exam_site_sessions.label' => :like
		}
		@date_types = [
			['Given On', 'exam_site_sessions.given_on'],
		]
		cond << get_date_condx
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => :exam_site
		}	
		@opt[:per_page] ||= 25
		@opt[:page] ||= params[:page]
		@objs = ExamSiteSession.paginate(:all, @opt)
	end
	
	def sessions_refresh
		ExamSiteSession.refresh
		redirect_to :action => :sessions
		flash[:notice] = 'New exams/dates/sites have been loaded.'
	end
	
	def session_edit
		@obj = ExamSiteSession.find params.id
		if request.post?
			@obj.update_attributes(params.obj)
		end
		render_nothing
	end
	
	def set_agency_department
		load_obj
		cond = nil
		if params[:only_blank]
			cond = 'applicants.agency_id is null and applicants.department_id is null'
		end
		@obj.applicants.find(:all, :conditions => cond).each { |a|
			a.update_attributes :department_id => params[:department_id], :agency_id => params[:agency_id]
		}
		flash[:notice] = 'Applicants have been updated.'
		redirect_to :action => :applicants, :id => @obj.id
	end
	
	def build_obj
		super
		if !request.post?
			@obj.include_on_master = true
		end
	end
	
	def rerank
		load_obj
		duplicates = @obj.calc_rank_and_pos
		if !duplicates.empty?
			flash[:errors] = ['Excluded because exam was taken before previous eligibility expired (exam taken twice, both valid):']
			duplicates.each { |a|
				flash[:errors] << "#{a.person.ssn} - #{a.person.last_name}, #{a.person.first_name}"
			}
		end
		redirect_to :action => :view, :id => @obj.id
		flash[:notice] = 'Candidates have been reranked.'
	end
	
	def applicants
		load_obj
		applicant_sort
		
		if @obj.continuous && @obj.current_exam_id && params[:export] && @filter[:cr] == '1'
			@e = Exam.find @obj.current_exam_id
			@cond << ('exams.current_exam_id = %d' % @e.current_exam_id)
		else
			@cond << ('exams.id = %d' % @obj.id)
		end
		
		opt = {
			:order => get_order_auto, 
			:include => [:person, :exam, :app_status],
			:conditions => get_where(@cond)
		}
		
		
		if params[:export]
			@objs = Applicant.find(:all, opt)
			export_applicants
		else
			opt[:per_page] ||= 50
			opt[:page] ||= params[:page]
			@objs = Applicant.paginate(:all, opt)
		end
			
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
	
	def print
		cond = []
		
		if @obj.continuous && @obj.current_exam_id
			@obj = Exam.find @obj.current_exam_id
			cond << ('exams.current_exam_id = %d and exams.valid_until >= date(now())' % @obj.current_exam_id)
		else
			cond << ('exams.id = %d' % @obj.id)
		end
		
		if params[:print]
			
			@filter = params[:print]
			
			params[:id2] = params[:short] ? 'short' : 'long'
			
			if @filter[:town_ids]
				@filter[:town_ids].map!(&:to_i)
				cond << 'people.town_id in (%s)' % @filter[:town_ids].join(',')
			end
			
			if @filter[:village_ids]
				@filter[:village_ids].map!(&:to_i)
				cond << 'people.village_id in (%s)' % @filter[:village_ids].join(',')
			end
			
			if @filter[:school_district_ids]
				@filter[:school_district_ids].map!(&:to_i)
				cond << 'people.school_district_id in (%s)' % @filter[:school_district_ids].join(',')
			end
			
			if @filter[:fire_district_ids]
				@filter[:fire_district_ids].map!(&:to_i)
				cond << 'people.fire_district_id in (%s)' % @filter[:fire_district_ids].join(',')
			end
			
		end
		
		@applicants = Applicant.find(:all, {
			#:order => 'applicants.pos asc',
			:order => 'applicants.pos',
			:conditions => get_where(cond),
			:include => [:app_status, :person, :exam, {:taken_perfs => :perf_code}]
		})
		@print_orient = 'Landscape'
		if params[:coversheet] == '1'
			html1 = render_to_string(:layout => false)
			html2 = render_to_string(:inline => '<%= nl2br_h @obj.cover_sheet_notes %>');
			tmp1 = TempfileExt.new('exam.pdf')
			tmp2 = TempfileExt.new('cover.pdf')
			tmp1.close
			tmp2.close
			render_pdf_to_file2 html1, tmp1.path, {:arg => '--footer-right "[page] of [topage]"'}
			render_pdf_to_file2 html2, tmp2.path
			io = IO.popen("pdftk #{tmp2.path} #{tmp1.path} cat output -", 'r')
			send_data io.read, :filename => "#{@obj.exam_no}.pdf", :type => "application/pdf", :disposition => 'inline'
			io.close
			tmp1.delete
			tmp2.delete
		else 
			render_pdf render_to_string(:layout => false), "#{@obj.exam_no}.pdf", {:flags => '--footer-right "[page] of [topage]"'}
		end
	end
	
	def attendance
		@report = {:given_by => []}
		if request.post?
			@report = params[:report]
			@report.given_by ||= []
			begin 
				@report[:from_date] = Date.parse(@report[:from_date])
				@report[:to_date] = Date.parse(@report[:to_date])
			rescue
				@errors = ['Could not parse date.']
				return
			end
			if !@errors
				cond = [DB.escape('date(exams.given_at) between "%s" and "%s"', @report.from_date.to_s, @report.to_date.to_s)]
				cond << 'exams.id in (%s)' % @report.exam_ids.map(&:to_i).join(', ') if !@report.exam_ids.blank?
				cond << 'applicants.exam_site_id in (%s)' % @report.exam_site_ids.map(&:to_i).join(', ') if !@report.exam_site_ids.blank?
				
				@report.given_by.map!(&:to_i)
				
				cond << 'exams.given_by in (%s)' % @report.given_by.join(', ') if !@report.given_by.blank?
				
				cond << 'alternate_exam_date is not null' if @report[:alternate_exam_date] == '1'				
				
				if params[:veterans]
					
					cond << 'applicants.army_served = 1'
					
					@objs = Applicant.find(:all, {
						:include => [:person, :exam],
						:conditions => get_where(cond),
						:order => 'people.last_name asc, people.first_name asc'
					})
					
					@print_orient = 'Landscape'
				
				elsif params[:special_accommodations]
				
					cond << 'wa.special_accommodations = 1 or p.special_accommodations != "" or p.sabbath_observer = 1'
				
					if @report[:only_active] == '1'
						cond << 'app_statuses.code = "A"'
					end
				
					objs = DB.query('
						select p.first_name, p.last_name, p.ssn, p.special_accommodations, p.sabbath_observer, p.special_accommodations_docs, p.sabbath_observer_docs, exams.exam_no, exams.given_at, wa.special_accommodations web_special_accommodations
						from applicants a
						join people p on p.id = a.person_id
						left join ' + HRAPPLYDB + '.applicants wa on wa.id = a.web_applicant_id
						left join app_statuses on app_statuses.id = a.app_status_id
						join exams on exams.id = a.exam_id
						where ' + get_where(cond) + '
						order by p.last_name asc, p.first_name asc'
					)
					@objs = []
					objs.each_hash { |h| @objs << h }
					@print_orient = 'Landscape'
				
				elsif params[:contact_preference]
					@objs = DB.query('
						select
						sum(p.contact_via = "postal") postal_count,
						sum(p.contact_via = "email") email_count,
						sum(p.contact_via = "both") both_count
						from applicants a join
						people p on p.id = a.person_id
						join exams on exams.id = a.exam_id where ' + get_where(cond)
					).fetch_hash
				
				elsif params[:cross_filing] || params[:cross_filing_excel]
					
					cond << 'applicants.cross_filing = 1'
					
					if @report[:only_active] == '1'
						cond << 'app_statuses.code = "A"'
					end					
					
					@objs = Applicant.find(:all, {
						:include => [:person, :exam, :app_status],
						:conditions => get_where(cond),
						:order => 'people.last_name asc, people.first_name asc'
					})
				
				elsif params[:statistics]
					
					objs = DB.query('
						select 
							exams.*,
							count(a.id) applied,
							sum(a.check_confirmed) * exams.fee collected,
							sum(a.approved = "Y") approved,
							sum(a.approved = "N") disapproved,
              sum(if(a.paid_by in ("K","C","R","M") ,1,0)) paid_by,
              sum(if(a.paid_by in ("K","C","R","M") ,1 * exams.fee,0)) total_paid,
            	sum(s.id is null) no_status,
							sum(a.approved = "Y" and s.code != "W" and s.code != "F" and s.code != "-") passed,
							sum(s.code = "F") failed,
							sum(s.code = "-") fta,
							sum(s.code = "W") withdrew,
							sum(s.eligible = "I") inactive,
							sum(s.appointed) appointed,
							sum(t.perf_passed) perf_passed,
							sum(t.perf_failed) perf_failed,
							sum(t.perf_waived) perf_waived
         		from exams
						join applicants a on a.exam_id = exams.id
            left join ' + HRAPPLYDB + '.exam_prices xx on a.web_exam_id = xx.exam_id and xx.applicant_id = a.web_applicant_id
						left join app_statuses s on s.id = a.app_status_id
						left join (
							select 
								t.*,
								sum(c.code = "P") perf_passed,
								sum(c.code = "T" or c.code = "F" or c.code = "S") perf_failed,
								sum(c.code = "W" or c.code = "C") perf_waived
							from taken_perfs t
							join perf_codes c on c.id = t.perf_code_id
							join exams on exams.id = t.exam_id
							where ' + get_where(cond.reject { |s| s.include?('alternate_exam_date') }) + '
							group by exams.id, t.applicant_id
						) t on t.exam_id = exams.id and t.applicant_id = a.id 
						where ' + get_where(cond) + '
						group by exams.id
						order by exams.title asc
					')
					
					@objs = []
					objs.each_hash { |o| @objs << o }
					
					@print_orient = 'Landscape'
				
				elsif params[:statistics2]
				
					where = get_where(cond)
				
					@objs1 = DB.query(
						'select count(*) c, if(applicants.approved = "Y", "Approved", if(applicants.approved = "N", "Disapproved", "(none)")) label, sum(if(w.total > 0, w.waiver_requested, 0)) waiver
						from applicants
						left join ' + HRAPPLYDB + '.applicants w on w.id = applicants.web_applicant_id
						left join exams on exams.id = applicants.exam_id
						where ' + where + '
						group by label order by label'
					)
					
					@objs2 = DB.query(
						'select count(*) c, ifnull(s.name, "(none)") label, sum(if(w.total > 0, w.waiver_requested, 0)) waiver
						from applicants left join app_statuses s on s.id = applicants.app_status_id
						left join ' + HRAPPLYDB + '.applicants w on w.id = applicants.web_applicant_id
						left join exams on exams.id = applicants.exam_id
						where ' + where + '
						group by label order by label'
					)
					
					@objs3 = DB.query(
						'select count(*) c, ifnull(d.reason, "(none)") label, sum(if(w.total > 0, w.waiver_requested, 0)) waiver
						from applicants left join disapprovals d on d.id = applicants.disapproval_id
						left join ' + HRAPPLYDB + '.applicants w on w.id = applicants.web_applicant_id
						left join exams on exams.id = applicants.exam_id
						where applicants.approved = "N" and (' + where + ')
						group by label order by label'
					)
					@objs = [@objs1, @objs2, @objs3]
				
				elsif params[:exam_sites]

					cond << 'applicants.approved = "Y"'

					@objs = Exam.find(:all, {
						:conditions => get_where(cond),
						:order => 'exam_sites.name, exams.exam_no, people.last_name asc, people.first_name asc',
						:include => [:applicants => [:exam, :exam_site, :app_status, :person]]
					})
					
				elsif params[:exam_sites_grid]
				
					cond << 'applicants.approved = "Y"'
					cond << 'exams.program_no != ""'
					objs = DB.query(
						'select s.name site_name, p.id person_id, p.first_name first_name, p.last_name last_name, exams.program_no booklet, count(*) c 
						from exams
						join applicants on applicants.exam_id = exams.id
						join exam_sites s on s.id = applicants.exam_site_id
						join people p on p.id = applicants.person_id
						where ' + get_where(cond) + ' 
						group by s.name, p.id, exams.program_no 
						order by s.name, p.last_name, p.first_name, exams.program_no'
					)
					@objs = Hash.new { |h, k| h[k] = {} }
					@people = Hash.new { |h, k| h[k] = OrderedHash.new }
					@booklets = Hash.new { |h, k| h[k] = OrderedHash.new }
					objs.each_hash { |h|
						@people[h.site_name][h.person_id] = h if !@people[h.site_name][h.person_id]
						@booklets[h.site_name][h.booklet] = h if !@booklets[h.site_name][h.booklet]
						@objs[h.site_name][[h.person_id, h.booklet]] = h.c
					}
				
				elsif params[:attendance] || params[:performance] || params[:performance_excel]

					cond << 'applicants.approved = "Y"'

					if @report[:only_active] == '1'
						cond << 'app_statuses.code = "A"'
					end
					
					if @report[:only_attended] == '1'
						cond << 'app_statuses.code not in ("W", "-")'
          end

					if @report[:separate_exams] == '1'

						@objs = Exam.find(:all, {
							:conditions => get_where(cond),
							:order => 'exams.exam_no, people.last_name asc, people.first_name asc',
							:include => [:applicants => [:exam, :exam_site, :app_status, :person]]
						})
						
					else

						@objs = Person.find(:all, {
							:conditions => get_where(cond),
							:order => 'people.last_name asc, people.first_name asc',
							:include => [:applicants => [:exam, :exam_site, :app_status]]
						})
					
					end					
				end
				
				if @objs.empty?
					@errors = ['No applicants/exams found']
				else
					if params[:performance_excel]
						book = Spreadsheet::Workbook.new
						sheet = book.create_worksheet
						sheet.row(0).concat(%w(first_name last_name ssn exam_no exam_title application_status perf_test1 perf_status1 perf_date1 perf_time1 perf_notes1 perf_test2 perf_status2 perf_date2 perf_time2 perf_notes2))
						i = 0
						if @report[:separate_exams] == '1'
							@objs.each { |e|
								e.applicants.each { |a| p = a.person
									i += 1
									exam_perfs = e.exam_perfs.find(:all, :include => :perf_test, :order => 'perf_tests.name')
									r = [p.first_name, p.last_name, @report[:full_ssn] == '1' ? p.ssn : p.ssn_last4, e.exam_no, e.title, a.app_status ? a.app_status.name : '']
									exam_perfs.each { |ep|
										taken_perf = p.taken_perfs.find(:first, :include => :perf_code, :conditions => ['taken_perfs.exam_id = ? and taken_perfs.perf_test_id = ?', e.id, ep.perf_test_id])
										r << ep.perf_test.name
										if taken_perf
											r << (taken_perf.perf_code ? taken_perf.perf_code.label : '')
											r << taken_perf.date_taken.d0?
											r << taken_perf.time_taken
											r << taken_perf.notes
										else
											r += ['', '', '', '']
										end
									}
									sheet.row(i).concat(r)
								}
							}
						else
							@objs.each { |p|
								p.applicants.each { |a| e = a.exam
									i += 1
									r = [p.first_name, p.last_name, @report[:full_ssn] == '1' ? p.ssn : p.ssn_last4, e.exam_no, e.title, a.app_status ? a.app_status.name : '']
									a.exam.exam_perfs.find(:all, :include => :perf_test, :order => 'perf_tests.name').each { |ep|
										taken_perf = p.taken_perfs.find(:first, :include => :perf_code, :conditions => ['taken_perfs.exam_id = ? and taken_perfs.perf_test_id = ?', a.exam_id, ep.perf_test_id])
										r << ep.perf_test.name
										if taken_perf
											r << (taken_perf.perf_code ? taken_perf.perf_code.label : '')
											r << taken_perf.date_taken.d0?
											r << taken_perf.time_taken
											r << taken_perf.notes
										else
											r += ['', '', '', '']
										end
									}
									sheet.row(i).concat(r)
								}
							}
						end
						data = StringIO.new
						book.write data
						send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
						
						
					elsif params[:cross_filing_excel]
						book = Spreadsheet::Workbook.new
						sheet = book.create_worksheet
						sheet.row(0).concat(%w(last_name first_name exam_no exam_title cross_filing_at other_exams))							
						@objs.each_with_index { |o, i|
							sheet.row(i + 1).concat([
								o.person.last_name, o.person.first_name,
								o.exam.exam_no, o.exam.title,
								o.cross_filing_at,
								o.cross_filing_exams.to_s.gsub("\r", '')
							]);
						}
						data = StringIO.new
						book.write data
						send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
					elsif params[:exam_sites_grid]
						book = Spreadsheet::Workbook.new
						name_format = Spreadsheet::Format.new :align => :left, :weight => :bold, :border => :thin
						head_format = Spreadsheet::Format.new :align => :center, :weight => :bold, :border => :thin, :text_wrap => true
						num_format = Spreadsheet::Format.new :align => :right, :border => :thin
						@objs.keys.sort.each { |site_name| objs = @objs[site_name]
							booklets = @booklets[site_name]
							people = @people[site_name]
							sheet = book.create_worksheet :name => site_name
							sheet.pagesetup[:orientation] = :landscape
							sheet[0, 0] = site_name
							col = 1
							btot = Hash.new { |h, v| h[v] = 0 }
							booklets.each { |b, h|
								sheet[2, col] = b.split(',').map(&:strip).join("\n")
								sheet.rows[2].set_format col, head_format
								col += 1
							}
							sheet[2, col] = 'TOTAL'
							sheet.rows[2].set_format 0, head_format
							sheet.rows[2].set_format col, head_format
							sheet.column(0).width = 40
							row = 3
							footnote = false
							people.each { |p, h|
								sheet[row, 0] = "#{h.last_name}, #{h.first_name}"
								sheet.rows[row].set_format 0, name_format
								col = 1
								ptot = 0
								booklets.each { |b, h|
									v = objs[[p, b]]
									if v 
										btot[b] += 1
										ptot += 1
										if v.to_i > 1
											footnote = true
											v = "#{v}*"
										end
									end
									sheet[row, col] = v
									sheet.rows[row].set_format col, num_format
									col += 1
								}
								sheet[row, col] = ptot
								sheet.rows[row].set_format col, num_format
								row += 1
							}
							col = 1
							sheet[row, 0] = 'TOTAL'
							booklets.each { |b, h|
								sheet[row, col] = btot[b]
								sheet[row + 1, col] = b.split(',').map(&:strip).join("\n")
								sheet.rows[row].set_format col, num_format
								sheet.rows[row + 1].set_format col, head_format
								col += 1
							}
							sheet[row, col] = btot.values.sum &:to_i
							sheet[row + 1, col] = 'TOTAL'
							sheet.rows[row].set_format col, num_format
							sheet.rows[row + 1].set_format col, head_format
							sheet.rows[row].set_format 0, head_format
							sheet.rows[row + 1].set_format 0, head_format
							if footnote
								sheet[row + 3, 0] = '* Only counted once in totals'
							end
						}
						data = StringIO.new
						book.write data
						send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
					else
						html = render_to_string :action => :attendance_print, :layout => false
						render_pdf html, 'report.pdf'
					end
				end
				
			end
		end
	end
					

	def attendance_autocomplete
		from = Date.parse(params[:from_date])
		to = Date.parse(params[:to_date])
		
		cond = [DB.escape('date(exams.given_at) between "%s" and "%s"', from.to_s, to.to_s)]
		
		cond << 'exams.given_by in (%s)' % params[:given_by].map(&:to_i).join(', ') unless params[:given_by].blank?
		
		exams = Exam.find(:all, {
			:conditions => get_where(cond),
			:order => 'exams.exam_no'
		});
		
		sites = ExamSite.find(:all, {
			:include => {:applicants => :exam},
			:conditions => get_where(cond),
			:order => 'exam_sites.name',
			:group => 'exam_sites.id',
			:order => 'exam_sites.name'
		});		
		
		@options = exams.collect { |e| ["#{e.exam_no} - #{e.title}", e.id] }
		exam_ids = render_to_string(:inline => '<%= partial "attendance_exam_ids" %>')
		@options = sites.map { |s| [s.name, s.id] }
		exam_site_ids = render_to_string(:inline => '<%= partial "attendance_exam_site_ids" %>')
		render :json => {:exam_ids => exam_ids, :exam_site_ids => exam_site_ids}.to_json
	end
	
	def load_exam_sites_stats
		@site_stats = [];
		@site_stats_indexed = {};
		DB.query('
			select count(*) site_count, es.id site_id, es.name site_name, es.capacity site_capacity, esa.number_to_assign number_to_assign
			from applicants a
			left join exam_sites es on es.id = a.exam_site_id
			left join exam_site_assignments esa on esa.exam_id = a.exam_id and esa.exam_site_id = es.id
			where a.exam_id = %d and a.approved = "Y"
			group by a.exam_site_id order by es.name asc
		', @obj.id).each_hash { |h|
			if h.site_name.blank?
				h.site_name = '(unassigned)'
			end
			@site_stats << h
			@site_stats_indexed[h.site_id.to_i] = h
		}
	end
	
	def applicant_sort

		@filter = get_filter({
			:sort1 => 'people.last_name',
			:dir1 => 'asc',
			:sort2 => 'people.first_name',
			:dir2 => 'asc',
		})
		
		@orders = [
			['SSN', 'people.ssn'],
			['First Name', 'people.first_name'],
			['Last Name', 'people.last_name'],
			['Score', 'applicants.final_score'],
			['Tiebreaker', 'applicants.tiebreaker'],
			['Position', 'applicants.pos']
		]		
		
		@statuses = AppStatus.find(:all, :order => 'app_statuses.name')
		
		@cond = []
		
		unless @filter[:statuses].blank?
			none = @filter[:statuses].delete('NONE')
			c = nil
			unless @filter[:statuses].blank?
				@filter[:statuses].map!(&:to_i)
				c = 'applicants.app_status_id in (%s)' % @filter[:statuses].join(', ')
			end
			if none && c
				@cond << "applicants.app_status_id is null or #{c}"
			elsif none
				@cond << 'applicants.app_status_id is null'
			elsif c
				@cond << c
			end
			if none
				@filter[:statuses] << 'NONE'
			end
		end
		
	end
	
	def establish
		if request.post?
			@obj.attributes = params[:obj]
			unless @obj.established_date && @obj.valid_until
				@obj.errors.add_to_base 'Both dates are required.'
			else
				@obj.save
				flash[:notice] = 'Eligible list has been established.'
				redirect_to :action => :view, :id => @obj.id, :id2 => nil
				return
			end
		end
		render :action => :establish
	end
	
	def bandscore
		@bs = @obj.bandscore || Bandscore.new(:exam_id => @obj.id)
		if request.post?
			if @bs.update_attributes params[:bs]
				@bs.apply_scoring
				redirect_to :action => :scoring, :id => @obj.id, :id2 => nil
				flash[:notice] = 'Exam has been bandscored.'
				return
			end
		end
		render :action => 'bandscore'
	end
	
	def scoring
		load_obj
		
		if params[:id2] == 'bandscore'
			bandscore
			return
		end
		
		if params[:id2] == 'establish'
			establish
			return
		end
		
		applicant_sort
		
		include = [:person, :app_status]
		
		if params[:id2] == 'perf'
			@exam_perfs = @obj.exam_perfs.find(:all, {
				:include => :perf_test,
				:order => 'perf_tests.name'
			})
			if @filter[:perf_code_ids]
				@filter[:perf_code_ids].map! &:to_i
				@cond << 'taken_perfs.perf_code_id in (' + @filter[:perf_code_ids].join(',') + ')'
				include << :taken_perfs
			end
		end
		
		@cond << 'applicants.approved = "Y"'
		
		opt = {
			:order => get_order_auto,
			:conditions => get_where(@cond),
			:include => include
		}
		
		if params[:export]
			@objs = @obj.applicants.find(:all, opt);
			export_applicants
		else		
			opt[:per_page] ||= 50
			opt[:page] ||= params[:page]
			@objs = @obj.applicants.paginate(:all, opt);
		end		
	end
	
	def export_applicants
		@export_fields = %w{approved app_status.name pos rank person.ssn person.last_name person.first_name person.home_phone person.work_phone person.fax person.cell_phone person.email person.mailing_address person.mailing_address2 person.mailing_city person.mailing_state person.mailing_zip raw_score base_score veterans_credits other_credits final_score}
		@export_fields += %w{person.residence_different person.residence_address person.residence_city person.residence_state person.residence_zip person.town.name person.village.name person.fire_district.name person.school_district.name exam.valid_until person.date_of_birth.d0? person.race}			
		@perf_fields = %w{perf_test.name taken_test.date_taken taken_test.time_taken taken_test.result_code taken_test.notes}
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		sheet.row(0).concat(@export_fields + (@exam_perfs ? @perf_fields * @exam_perfs.size : []))
		@objs.each_with_index { |o, i|
			@export_fields.each_with_index { |f, j|
				sheet[i + 1, j] = o.instance_eval(f) rescue nil
			}
			if @exam_perfs
				@exam_perfs.each_with_index { |e, j|
					perf_test = e.perf_test
					taken_test = o.taken_perfs.find_by_exam_id_and_perf_test_id(@obj.id, e.perf_test_id) || TakenPerf.new
					@perf_fields.each_with_index { |f, k|
						sheet[i + 1, @export_fields.size + (j * @perf_fields.size) + k] = eval(f)
					}
				}
			end
		}
		data = StringIO.new
		book.write data
		send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
	end
	
	def sites_save
		load_obj
		sites = params[:sites]
		if sites && request.post?
			sites.each { |applicant_id, attr|
				@obj.applicants.find(applicant_id).update_attribute :exam_site_id, attr[:id]
			}
		end
		render_nothing
	end
	
	def perf_save
		load_obj
		perf = params[:perf]
		appls = params[:applicant]
		
		if request.post? && (perf || appls)
			if perf 
				perf.each { |i, attr|
					parts = i.split('-')
					applicant_id = parts[0]
					perf_test_id = parts[1]
					tp = @obj.taken_perfs.find_by_perf_test_id_and_applicant_id(perf_test_id, applicant_id)
				
					blank = attr[:date_taken].blank? && attr[:time_taken].blank? && attr[:result_code].blank? && attr[:notes].blank?
				
					if !tp && !blank
						a = Applicant.find applicant_id
						tp = @obj.taken_perfs.build :perf_test_id => perf_test_id, :applicant_id => a.id, :person_id => a.person_id
					end
					if blank && tp
						tp.destroy
					end
					if tp && !blank
						tp.attributes = attr
						tp.save
					end
				}
			end
			if appls
				appls.each { |id, attr|
					a = @obj.applicants.find(id)
					a.update_attributes attr
				}			
			end
		end
		render_nothing
	end
	
	def assign_sites
		load_obj
		
		if params[:id2] == 'detail'
			
			applicant_sort
			
			@sites = @obj.exam_site_assignments.find(:all, :order => 'sort')
			@sites_indexed = {}
			@sites_indexed2 = {}
			
			@sites.each { |a|
				@sites_indexed[a.exam_site_id] = a.sort + 1
				@sites_indexed2[a.sort + 1] = a.exam_site_id
			}
			
			@objs = @obj.applicants.find(:all, {
				:order => get_order_auto,
				:conditions => 'applicants.approved = "Y"',
				:include => [:person, :app_status]
			})
		
		else
		
			load_exam_sites_stats
			
			@zips = []
			DB.query('select count(*) c, if(p.residence_different, p.residence_zip, p.mailing_zip) zip_code, z.name name from applicants a join people p on p.id = a.person_id
				left join zip_codes z on z.zip = if(p.residence_different, p.residence_zip, p.mailing_zip)
				where a.exam_id = %d and a.approved = "Y"
				group by if(p.residence_different, p.residence_zip, p.mailing_zip)
				order by c desc, z.name asc', @obj.id).each_hash { |h|
				@zips << h	
			}
			
			if request.post?
				
				if params[:bulk]
					@bulk = params[:bulk]
				
					DB.query('
						update applicants a 
						set a.exam_site_id = ' + (@bulk.to_id.blank? ? 'null' : @bulk.to_id.to_i.to_s) + '
						where a.exam_id = %d and (a.exam_site_id ' + (@bulk.from_id.blank? ? 'is null or a.exam_site_id = 0' : ' = ' + @bulk.from_id.to_i.to_s) + ')
					', @obj.id)
					redirect_to
					flash[:notice] = 'Bulk reassignment complete.'
				
				elsif params[:obj]
					@obj.update_attributes params[:obj]
					redirect_to
					flash[:notice] = 'Exam sites have been saved.'
				else
				
					applicants = @obj.applicants.find(:all, {
						:conditions => 'approved = "Y"' + (params[:all] ? '' : ' and exam_sites.id is null'), 
						:include => [:person, :exam_site], 
						:order => 'people.last_name asc, people.first_name asc'
					}).to_a
					
					sites = @obj.exam_site_assignments.find(:all, :order => 'exam_site_assignments.sort asc').to_a
					
					
					site_counts = {}
					applicants.each { |a|
						a.exam_site_id = nil
						sites.each { |s|
							if !site_counts[s.id]
								site_counts[s.id] = params[:all] ? 0 : (@site_stats_indexed[s.exam_site_id] ? @site_stats_indexed[s.exam_site_id]['site_count'].to_i : 0)
							end
							site_zips = s.zip_codes.to_s.split(',').map(&:strip).reject(&:blank?)
							person_zip = a.person.residence_different ? a.person.residence_zip : a.person.mailing_zip
							person_zip = person_zip.to_s.strip[0, 5]
							if((site_zips.empty? || site_zips.include?(person_zip)) && ((s.number_to_assign.to_i == 0) || (s.number_to_assign.to_i > site_counts[s.id])))
								a.exam_site_id = s.exam_site_id
								site_counts[s.id] += 1
								break;
							end
						}
						a.save
					}
					
									
					#site_index = 0
					#applicant_index = 0
					#site_count = 0
					#done = false
					#while !done
					#	site = sites[site_index]
					#	site_zips = site.zip_codes.to_s.split(',').map(&:strip).reject(&:blank?)
					#	applicant = applicants[applicant_index]
					#	if !applicant || !site
					#		done = true
					#	else
					#		site_stats = @site_stats_indexed[site.id] || {}
					#		if site.number_to_assign > site_count + (params[:all] ? 0 : site_stats['site_count'].to_i)
					#			applicant.update_attribute :exam_site_id, site.exam_site_id
					#			applicant_index += 1
					#			site_count += 1
					#		else
					#			site_index += 1
					#			site_count = 0
					#		end
					#	end
					#end
					
					#if params[:all] && applicant_index < applicants.size
					#	applicant_index.upto(applicants.size - 1) { |i|
					#		applicants[i].update_attribute :exam_site_id, nil
					#	}
					#end
									
					redirect_to {}
					flash[:notice] = 'Exam site assignments have been made. You can adjust these assignments on the Applicants tab.'
				end
			end
			
		end
			
	end
	
	def view
		
		cond = []
		#if @obj.continuous && @obj.current_exam_id
		#	@e = Exam.find @obj.current_exam_id
		#	cond << ('e.current_exam_id = %d and e.valid_until >= date(now())' % @e.current_exam_id)
		#else
			cond << ('e.id = %d' % @obj.id)
		#end
		
		@stats = DB.query('
			select
				count(a.id) total,
				sum(a.approved = "Y") approved,
				sum(a.approved = "N") disapproved,
				sum(a.approved = "" or a.approved is null) no_action,
				sum(a.approved = "Y" and s.code != "W" and s.code != "F" and s.code != "-" and a.final_score is not null) passed,
				sum(s.code = "F") failed,
				sum(s.code = "-") fta,
				sum(s.code = "W") withdrew,
				sum(s.eligible = "I") inactive,
				sum(s.appointed) appointed,
				sum(s.eligible = "A") active
			from applicants a
			join exams e on e.id = a.exam_id
			left join app_statuses s on s.id = a.app_status_id
			where ' + get_where(cond)
		).fetch_hash
		
		@perf_stats = DB.query('
			select
				pt.*,
				sum(c.code = "P") passed,
				sum(c.code in ("T", "S", "F")) failed,
				sum(c.code in ("N", "-")) fta,
				sum(c.code in ("W", "C")) waived
			from exam_perfs ep
			join exams e on e.id = ep.exam_id
			join perf_tests pt on pt.id = ep.perf_test_id
			left join taken_perfs t on t.exam_id = ep.exam_id and t.perf_test_id = pt.id
			left join perf_codes c on c.id = t.perf_code_id
			where '  + get_where(cond) + '
			group by pt.id
		')
		
		super
	end
	
	def max_cr_group
		cond = ['title = ? and exam_type = ?', params[:title], params[:exam_type]]
		if !params[:exam_id].blank?
			cond[0] += ' and id <= ?'
			cond << params[:exam_id].to_i
		end
		e = Exam.find(:first, :conditions => cond, :order => 'id desc')
		render :text => (e ? e.cr_group : 0).to_s
	end
	
	def send_expiring_cr_email
		d = params[:id] ? Date.parse(params[:id]) : Time.now.to_date - 1
		@objs = Exam.find(:all, :conditions => ['exams.valid_until = ? and exams.continuous = 1', d])
		if !@objs.empty?
			Notifier.deliver_expiring_cr @objs
		end
		render :text => 'done'
	end
	skip_before_filter :authenticate, :only => :send_expiring_cr_email
	
	
	
	
	
	
	
end