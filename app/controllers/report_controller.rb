class ReportController < ApplicationController

	def index
		@employee_orders = employee_sort_options
		employee_bd
	end
	
	def employee_bd
		@employee_bd = [
			['Agency', 'agency_name'],
			['Agency Type', 'agency_type'],
			['Department', 'department_name'],
			['Title', 'job_name']
		]
	end
	
	def employee_sort_options
		@orders = [
			['ID', 'e.id'],
			['First Name', 'e.first_name'],
			['Last Name', 'e.last_name'],
			['SSN', 'e.ssn'],
			['Hire Date', 'e.date_hired'],
			['Leave Date', 'e.leave_date'],
			['Title', 'j.name'],
			['Agency Name', 'a.name'],
			['Department Name', 'd.name'],
			['Seniority Date', 'e.seniority_date']
		]
	end
	
	def expiring_lists
		
		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])
		@date = params[:date]
		
		@objs = DB.query(
			'select 
				e.*,
				j.name job_name,
				sum((s.eligible = "A" or s.eligible = "I") and (a.perf_test_status is null or a.perf_test_status != "F")) no_on_list,
				sum(s.eligible = "I") no_inactive,
				sum(s.code = "D" or a.approved = "N") no_disapproved,
				sum(s.code = "F" or a.perf_test_status = "F") no_failed,
				sum(s.code = "-") no_fta
			from exams e
			left join jobs j on j.id = e.job_id
			left join applicants a on a.exam_id = e.id
			left join app_statuses s on s.id = a.app_status_id
			where e.' + (@date == 'establish' ? 'established_date' : 'valid_until') + ' between "%s" and "%s"
			group by e.id
			order by e.valid_until',
			@from_date.to_s,
			@to_date.to_s
		)
		
		if params[:export]
			book = Spreadsheet::Workbook.new
			@sheet = book.create_worksheet
			@export_fields = %w{exam_date title exam_no type cr established expires no_on_list no_inactive no_disapproved no_failed no_fta}
			@sheet.row(0).concat(@export_fields)
			i = 1
			@objs.each_hash { |o|
				@sheet.row(i).concat([
					(Date.parse(o.given_at).d0? rescue nil),
					o.title,
					o.exam_no,
					o.exam_type,
					(o.continuous == '1' ? 'yes' : 'no'),
					(Date.parse(o.established_date).d0? rescue nil),
					(Date.parse(o.valid_until).d0? rescue nil),
					o.no_on_list,
					o.no_inactive,
					o.no_disapproved,
					o.no_failed,
					o.no_fta
				])
				i += 1
			}
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
		else
			render_pdf render_to_string(:layout => false), 'expiring-lists.pdf'
		end
	end
	
	def fees_paid
		
		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])		
		
		@objs = DB.query(
			'select
				e.*,
				e.title job_name,
				count(a.id) no_applied,
				sum(approved = "Y") no_approved,
				sum(approved = "N") no_disapproved,
				sum(paid_by = "K" and check_confirmed = 1) no_check_confirmed,
				sum(paid_by = "K" and check_confirmed = 0) no_check_unconfirmed,
				sum(paid_by = "C") no_cash,
				sum(paid_by = "R") no_credit,
				sum(paid_by = "W") no_reg_waiver,
				sum(paid_by = "E") no_empl_waiver,
				sum(paid_by = "W" and a.approved = "Y") no_reg_waiver_approved,
				sum(paid_by = "E" and a.approved = "Y") no_empl_waiver_approved,				
				sum(paid_by = "M" and check_confirmed = 1) no_money_order_confirmed,
				sum(paid_by = "M" and check_confirmed = 0) no_money_order_unconfirmed,
				sum(paid_by = "B") no_bounced,
				sum(paid_by = "U") no_unpaid,
				sum(paid_by = "X") no_nocharge
			from exams e
			join applicants a on a.exam_id = e.id
			left join jobs j on j.id = e.job_id
			where date(e.given_at) between "%s" and "%s" and e.fee > 0
			group by e.id
			order by e.title',
			@from_date.to_s,
			@to_date.to_s
		)
		
		render_pdf render_to_string(:layout => false), 'fees-paid.pdf'
	end
	
	def employees
	
		employee_bd
		
		cond = ['e.leave_date is null or e.leave_date > date(now())']
		
		@agency_ids = params[:agency_ids]
		@department_ids = params[:department_ids]
		@job_ids = params[:job_ids]
		@agency_types = params[:agency_types]
		@empl_action_type_ids = params[:empl_action_type_ids]
		
		@classes = params[:classes]
		@statuses = params[:statuses]
		
		@time = params[:time]
		
		cond << 'a.id in (%s)' % @agency_ids.map(&:to_i).join(',') unless @agency_ids.blank?
		cond << 'd.id in (%s)' % @department_ids.map(&:to_i).join(',') unless @department_ids.blank?
		cond << 'j.id in (%s)' % @job_ids.map(&:to_i).join(',') unless @job_ids.blank?
		cond << 'a.agency_type in ("%s")' % @agency_types.join('","') unless @agency_types.blank?
		
		cond << 'e.classification in ("%s")' % @classes.join('","') unless @classes.blank?
		cond << 'e.status in ("%s")' % @statuses.join('","') unless @statuses.blank?
		
		extra_join = []
		if !@empl_action_type_ids.blank?
			cond << 'ea.empl_action_type_id in (%s)' % @empl_action_type_ids.map(&:to_i).join(',')
			extra_join << 'join empl_actions ea on ea.employee_id = e.id'
		end
		
		if @current_user.agency_level? && @current_user.agency
			cond << 'e.agency_id = %d' % @current_user.agency_id
		end
		
		if @current_user.agency_level? && @current_user.department
			cond << 'e.department_id = %d' % @current_user.department_id
		end
		
		cond << 'e.job_time = "%s"' % @time unless @time.blank?
		
		params[:sort1] ||= 'e.last_name'
		
		result = DB.query(
			'select e.*,
			a.name agency_name,
			a.agency_type agency_type,
			d.name as department_name,
			j.name as job_name
			from employees e
			join agencies a on a.id = e.agency_id
			join departments d on d.id = e.department_id
			join jobs j on j.id = e.job_id ' + 
			(extra_join * ' ') +
			' where ' +
			get_where(cond) +
			'group by e.id order by ' + get_order(employee_sort_options, [[params[:sort1], params[:dir1]], [params[:sort2], params[:dir2]], [params[:sort3], params[:dir3]]])
		)
		
		objs = []
		result.each_hash { |h| objs << h }
		
		params[:bd] = [params[:bd0], params[:bd1], params[:bd2]].reject(&:blank?)
		
		@indent = params[:bd].length
		
		@agencies = params[:bd].include?('agency_name')
		@departments = params[:bd].include?('department_name')
		@jobs = params[:bd].include?('job_name')
		
		@objs = break_it_down objs, *params[:bd]
		
		if params[:export]
			book = Spreadsheet::Workbook.new
			@sheet = book.create_worksheet
			@export_fields = %w{job_name agency_name department_name last_name first_name classification status job_time}
			@export_fields << 'ssn' if params[:show_ssn]
			@export_fields << 'seniority_date' if params[:show_seniority_date]
			if params[:show_salary]
				@export_fields << 'wage'
				@export_fields << 'wage_per'
			end
			@export_fields << 'veteran' if params[:show_veteran]
			@export_fields << 'pension_no' if params[:show_pension_no]			
			@sheet.row(0).concat(@export_fields)
			
			export_group @objs, 1
			
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
		else
			@print_orient = 'Landscape'
			render_pdf render_to_string(:layout => false), 'employees.pdf'
		end
	end
	
	def export_group objs, i
		if objs.is_a? Array
			objs.each { |o|
				@export_fields.each_with_index { |f, j|
					@sheet[i, j] = o.instance_eval(f) rescue nil
				}
				i += 1
			}
		else
			keys = objs.keys.sort
			keys.each { |k|
				i = export_group objs[k], i
			}
		end
		return i
	end
	
	def break_it_down objs, by = nil, *next_by	
		return objs if by.blank?
		objs2 = objs.group_by { |o| o.send(by.to_sym) }
		unless next_by.blank?
			objs2.each { |k, v|
				objs2[k] = break_it_down objs2[k], *next_by
			}
		end
		return objs2
	end
	
	def seniority
		
		@agency = Agency.find(params[:agency_id])
		
		result = DB.query(
			'select e.*,
			j.name job_name,
			d.name department_name,
			a.name agency_name
			from employees e
			join agencies a on a.id = e.agency_id
			join departments d on d.id = e.department_id
			join jobs j on j.id = e.job_id
			where a.id = %d and e.seniority_date is not null
			order by j.name, e.seniority_date asc, e.last_name, e.first_name',
			params[:agency_id]
		)
		
		@objs = {}
		result.each_hash { |h|
			@objs[h.job_name] ||= []
			@objs[h.job_name] << h
		}
		
		render_pdf render_to_string(:layout => false), 'seniority.pdf'
	end
	
	def applications_log

		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])
			
		cond = [DB.escape('date(a.submitted_at) between "%s" and "%s"', @from_date, @to_date)]
		
		cond << 'e.job_id in (%s)' % params[:job_ids].map(&:to_i).join(',') unless params[:job_ids].blank?
		
		@objs = DB.query(q =
			'select 
					e.title,
					count(a.id) applied,
					sum(a.approved = "Y") approved,
					sum(a.approved = "N") disapproved,
					sum(a.approved = "Y" and s.code != "W" and s.code != "F" and s.code != "-" and (perf_test_status is null or perf_test_status != "F")) passed,
					sum(s.code = "F" or (perf_test_status is not null and perf_test_status = "F")) failed,
					sum(s.code = "-") fta,
					sum(s.code = "W") withdrew,
					sum(s.eligible = "I") inactive,
					sum(s.appointed) appointed
				from applicants a
				join exams e on e.id = a.exam_id
				left join app_statuses s on s.id = a.app_status_id where ' +
				get_where(cond) +
				' group by e.title
				order by e.title asc')
	

	
		render_pdf render_to_string(:layout => false), 'applications-log.pdf'
	end
	
	def loans_default

		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])
		
		@objs = DB.query(
			'select 
				a.*,
				p.*, 
				e.title exam_name,
				date(e.given_at) exam_date,
				e.exam_no exam_no
			from applicants a
			join people p on p.id = a.person_id
			left join exams e on e.id = a.exam_id
			where a.loans_default = 1
			and date(a.submitted_at) between "%s" and "%s"
			',
			@from_date.to_s,
			@to_date.to_s
		)
		q = DB.escape('select 
				a.*,
				p.*, 
				e.title exam_name,
				date(e.given_at) exam_date,
				e.exam_no exam_no
			from applicants a
			join people p on p.id = a.person_id
			left join exams e on e.id = a.exam_id
			where a.loans_default = 1
			and date(a.submitted_at) between "%s" and "%s"
			',
			@from_date.to_s,
			@to_date.to_s
		)

		render_pdf render_to_string(:layout => false), 'loans-default.pdf'
	end
	
	def demographics
		
		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])
			
		cond = [DB.escape('date(e.given_at) between "%s" and "%s"', @from_date, @to_date)]
		
		cond << 'j.id in (%s)' % params[:job_ids].map(&:to_i).join(',') unless params[:job_ids].blank?
		
		@objs = DB.query(q = 
			'select
			
			j.name job_name,
			
			sum(p.race = "white") w_t,
			sum(p.race = "white" and a.approved = "Y") w_a,
			sum(p.race = "white" and a.approved = "N") w_d,
			sum(p.race = "white" and s.eligible != "N") w_e,
			sum(p.race = "white" and s.eligible = "N") w_i,
			sum(p.race = "white" and p.gender = "M") w_m,
			sum(p.race = "white" and p.gender = "F") w_f,
			sum(p.race = "white" and (a.final_score>59 and s.id<>2)) w_p,
			sum(p.race = "white" and (a.final_score<60 or s.id=2)) w_z,
			sum(p.race = "white" and (p.gender = "" or p.gender is null)) w_u,

			
			sum(p.race = "asian") a_t,
			sum(p.race = "asian" and a.approved = "Y") a_a, 
			sum(p.race = "asian" and a.approved = "N") a_d,
			sum(p.race = "asian" and s.eligible != "N") a_e,
			sum(p.race = "asian" and s.eligible = "N") a_i, 
			sum(p.race = "asian" and p.gender = "M") a_m,
			sum(p.race = "asian" and p.gender = "F") a_f,
      sum(p.race = "asian" and (a.final_score>59 and s.id<>2)) a_p,
	    sum(p.race = "asian" and (a.final_score<60 or s.id=2)) a_z,
			sum(p.race = "asian" and (p.gender = "" or p.gender is null)) a_u,
			
			sum(p.race = "pacific") p_t,
			sum(p.race = "pacific" and a.approved = "Y") p_a, 
			sum(p.race = "pacific" and a.approved = "N") p_d,
			sum(p.race = "pacific" and s.eligible != "N") p_e,
			sum(p.race = "pacific" and s.eligible = "N") p_i, 
			sum(p.race = "pacific" and p.gender = "M") p_m,
			sum(p.race = "pacific" and p.gender = "F") p_f,
      sum(p.race = "pacific" and (a.final_score>59 and s.id<>2)) p_p,
	    sum(p.race = "pacific" and (a.final_score<60 or s.id=2)) p_z,
			sum(p.race = "pacific" and (p.gender = "" or p.gender is null)) p_u,			
			
			sum(p.race = "black") b_t,
			sum(p.race = "black" and a.approved = "Y") b_a,
			sum(p.race = "black" and a.approved = "N") b_d,
			sum(p.race = "black" and s.eligible != "N") b_e,
			sum(p.race = "black" and s.eligible = "N") b_i, 
			sum(p.race = "black" and p.gender = "M") b_m,
			sum(p.race = "black" and p.gender = "F") b_f,
      sum(p.race = "black" and (a.final_score>59 and s.id<>2)) b_p,
	    sum(p.race = "black" and (a.final_score<60 or s.id=2)) b_z,
			sum(p.race = "black" and (p.gender = "" or p.gender is null)) b_u,
			
			sum(p.race = "americanindian") i_t,
			sum(p.race = "americanindian" and a.approved = "Y") i_a,
			sum(p.race = "americanindian" and a.approved = "N") i_d,
			sum(p.race = "americanindian" and s.eligible != "N") i_e,
			sum(p.race = "americanindian" and s.eligible = "N") i_i,
			sum(p.race = "americanindian" and p.gender = "M") i_m,
			sum(p.race = "americanindian" and p.gender = "F") i_f,
      sum(p.race = "americanindian" and (a.final_score>59 and s.id<>2)) i_p,
	    sum(p.race = "americanindian" and (a.final_score<60 or s.id=2)) i_z,
			sum(p.race = "americanindian" and (p.gender = "" or p.gender is null)) i_u,
			
			sum(p.race = "hispanic") h_t,
			sum(p.race = "hispanic" and a.approved = "Y") h_a,
			sum(p.race = "hispanic" and a.approved = "N") h_d,
			sum(p.race = "hispanic" and s.eligible != "N") h_e,
			sum(p.race = "hispanic" and s.eligible = "N") h_i,
			sum(p.race = "hispanic" and p.gender = "M") h_m,
			sum(p.race = "hispanic" and p.gender = "F") h_f,
      sum(p.race = "hispanic" and (a.final_score>59 and s.id<>2)) h_p,
	    sum(p.race = "hispanic" and (a.final_score<60 or s.id=2)) h_z,
			sum(p.race = "hispanic" and (p.gender = "" or p.gender is null)) h_u,
			
			sum(p.race = "plural") h_t,
			sum(p.race = "plural" and a.approved = "Y") l_a,
			sum(p.race = "plural" and a.approved = "N") l_d,
			sum(p.race = "plural" and s.eligible != "N") l_e,
			sum(p.race = "plural" and s.eligible = "N") l_i,
			sum(p.race = "plural" and p.gender = "M") l_m,
			sum(p.race = "plural" and p.gender = "F") l_f,
      sum(p.race = "plural" and (a.final_score>59 and s.id<>2)) l_p,
	    sum(p.race = "plural" and (a.final_score<60 or s.id=2)) l_z,
			sum(p.race = "plural" and (p.gender = "" or p.gender is null)) l_u
			
			from applicants a
			join app_statuses s on s.id = a.app_status_id
			join people p on p.id = a.person_id
			join exams e on e.id = a.exam_id
			join jobs j on j.id = e.job_id
			where ' +
				get_where(cond) +
			' group by j.id
			order by j.name asc'
		)
		@print_orient = 'Landscape'
		render_pdf render_to_string(:layout => false), 'demographics.pdf'
	end
	
	def annual			
		date = Date.parse(params[:date])	
		if request[:titles]
			class_cond = request[:class_all] ? '' : 
				'and ((e.status = "P" and e.classification in ("N", "5", "E", "L")) or (e.classification = "C" and e.status in ("P", "V", "V2", "C", "T")))'
			result = DB.query('
				select j.name, e.classification, count(*) employee_count
				from employees e 
				left join jobs j on j.id = e.job_id
				where (e.leave_date is null or e.leave_date > "%s") and e.date_hired <= "%s"
					' + class_cond + '
				group by e.job_id, e.classification
			', date.to_s, date.to_s)
			book = Spreadsheet::Workbook.new
			sheet = book.create_worksheet :name => 'Titles'
			i = 0
			tot = Hash.new { |h, k| h[k] = 0 }
			sheet.row(0).replace(['Title', 'Class', 'Count'])
			result.each_hash { |h|
				i = i + 1
				sheet.row(i).replace([h.name, h.classification, h.employee_count])
				tot[h.classification.to_s] += h.employee_count.to_i
			}
			tot2 = 0
			tot.each { |k, v|
				i += 1
				k_label = k.blank? ? '(blank)' : k
				sheet.row(i).replace(["TOTAL CLASS #{k_label}", '', v])
				tot2 += v
			}
			sheet.row(i + 1).replace(['TOTAL', '', tot2])
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'titles.xls', :type => 'application/vnd.ms-excel'					
			
		elsif request[:overview]
			
			objs = DB.query('
				select
					a.agency_type,
					sum(
						(e.status = "P" and e.classification in ("N", "5", "E", "L")) or
						(e.classification = "C" and e.status in ("P", "V", "V2", "C", "T"))
					) clas,
					sum(e.classification = "C" and e.status in ("P", "V", "V2", "C", "T")) comp,
					sum(e.classification = "C" and e.status = "P") comp_perm,
					sum(e.classification = "C" and e.status in ("V", "V2")) comp_prov,
					sum(e.classification = "C" and e.status = "C") comp_cp,
					sum(e.classification = "C" and e.status = "T") comp_temp,
					sum(e.classification = "N" and e.status = "P") non_comp,
					sum(e.classification = "5" and e.status = "P") non_comp55,
					sum(e.classification = "E" and e.status = "P") exempt,
					sum(e.classification = "L" and e.status = "P") labor
				from employees e
				join agencies a on a.id = e.agency_id
				where (e.leave_date is null or e.leave_date > "%s") 
					and e.date_hired <= "%s"
					and e.status is not null and e.classification is not null
				group by a.agency_type
			', date.to_s, date.to_s)
			
			@objs = {}
			objs.each_hash { |h| @objs[h.agency_type] = h }
			
			render_pdf render_to_string(:layout => false), 'annual-report-overview.pdf'
		else
		
			book = Spreadsheet::Workbook.new
			
			inc = [:agency, :department, :job]
			cond = DB.escape('
				(employees.leave_date is null or employees.leave_date > "%s") and 
				employees.date_hired <= "%s" and 
				employees.status is not null and 
				employees.classification is not null
			', date.to_s, date.to_s)
			ord = 'employees.last_name, employees.first_name'

      condx = DB.escape('(employees.leave_date is null or date(employees.leave_date) > "%s") 	and employees.status is not null and
				employees.classification is not null and employees.date_hired <= "%s"  ',date.to_s,date.to_s)
      objs = Employee.find(:all, {
          :conditions => condx,
          :include => inc,
          :order => ord
      })

      sheet = book.create_worksheet :name => 'All Employees'

      put_objs_in_sheet objs, sheet


			
			v_cond = cond + 'and employees.status in ("V", "V2") and employees.classification = "C"'

			objs = Employee.find(:all, {
				:conditions => v_cond,
				:include => inc,
				:order => ord
			})
			
			sheet = book.create_worksheet :name => 'Provisionals'
			
			put_objs_in_sheet objs, sheet
			
			t_cond = cond + 'and employees.status = "C" and employees.classification = "C"'

			objs = Employee.find(:all, {
				:conditions => t_cond,
				:include => inc,
				:order => ord
			})
			
			sheet = book.create_worksheet :name => 'ContPerm'
			
			put_objs_in_sheet objs, sheet
			
			t_cond = cond + 'and employees.status = "T" and employees.classification = "C"'

			objs = Employee.find(:all, {
				:conditions => t_cond,
				:include => inc,
				:order => ord
			})
			
			sheet = book.create_worksheet :name => 'Temporary'
			
			put_objs_in_sheet objs, sheet
			
			sheet = book.create_worksheet :name => 'Layoffs'
			objs = EmplAction.find(:all, {
				:include => [:empl_action_type, :employee, :agency, :department, :job],
				:conditions => [
					'empl_actions.action_date between ? and ? and empl_action_types.name = "LAYOFF" ',
					date.advance(:years => -1), date],
				:order => 'employees.last_name, employees.first_name'
			})
			sheet.row(0).replace([
				'Last Name', 'First Name', 'SSN', 'Title', 'Agency', 'Department', 'Time', 
				'Class', 'Status', 'Wage', 'WagePer', 'Authorization', 'Date'
			])

			objs.each_with_index { |o, i|
        if !o.employee.nil? then
          logger.info "Employee-#{o.id}"
				sheet.row(i + 1).replace([
					o.employee.last_name, o.employee.first_name, o.employee.ssn, o.job.name, o.agency.name, o.department.name, o.job_time,
					o.classification, o.status, o.wage, o.wage_per, o.authorization, o.action_date
				])
        end
			}
		
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'		
		
		end
	end
	
	def put_objs_in_sheet objs, sheet
		sheet.row(0).replace(['Last Name', 'First Name', 'SSN', 'Title', 'Agency', 'Agency Type','Department', 'Classification','Time','Status'])
		objs.each_with_index { |o, i|
			sheet.row(i + 1).replace([o.last_name, o.first_name, o.ssn, o.job ? o.job.name : '', o.agency ? o.agency.name : '', o.agency ? o.agency.agency_type : '', o.department ? o.department.name : '', o.classification ? o.classification : '',  o.job_time ? o.job_time : '',o.status ? o.status : ''])
		}
	end
	
	def veterans
		@objs = Person.find(:all, {
			:order => 'people.last_name asc, people.first_name asc',
			:conditions => 'people.veteran in ("VETERAN", "DISABLED VET")'
		})
		render_pdf render_to_string(:layout => false), 'veterans.pdf'
	end	
	
	def noncompetitive
	
		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])
			
		cond = [DB.escape('date(empl_actions.reference_date) between "%s" and "%s"', @from_date, @to_date)]
		
		cond << 'empl_actions.classification in ("N", "5")'
		
		cond << 'empl_action_types.hire = 1'
		
		@objs = Employee.find(:all, {
			:include => {:empl_actions => [:empl_action_type, :agency, :department, :job]},
			:order => 'employees.last_name asc, employees.first_name asc, empl_actions.reference_date desc',
			:conditions => get_where(cond)
		})
		
		@objs = @objs.group_by { |o| o.agency.name }
		
		if params[:excel]
			book = Spreadsheet::Workbook.new
			sheet = book.create_worksheet :name => 'NonCompetitive'
			i = 1
			sheet.row(0).replace(['Agency', 'Last Name', 'First Name', 'SSN', 'Title', 'Appointment Date', 'Received Date', 'Days'])
			@objs.keys.sort.each { |k|
				@objs[k].each { |o|
					o.empl_actions.each { |a|						
						sheet.row(i).replace([
							k,
							o.last_name,
							o.first_name,
							o.ssn,
							a.job ? a.job.name : '',
							a.action_date.d0?,
							a.received_date.d0?,
							a.received_date && a.action_date ? a.received_date - a.action_date : ''
						])
						i += 1
					}
				}
			}
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'		
		else
			render_pdf render_to_string(:layout => false), 'noncompetitive.pdf'
		end
	end	
	
	def provisionals
		
		cond = []
		unless params[:jurisdictions].blank?
			juris = params[:jurisdictions].collect { |j| DB.escape(j) }.join('","')
			cond << 'provisionals.jurisdiction in ("%s")' % juris
		end
		
		@from_date = Date.parse(params[:from_date]) rescue nil
		@to_date = Date.parse(params[:to_date]) rescue nil
		
		cond << 'provisionals.reference_date >= "%s"' % @from_date.to_s if @from_date
		cond << 'provisionals.reference_date <= "%s"' % @to_date.to_s if @to_date
		
		@objs = Provisional.find(:all, {
			:order => 'provisionals.jurisdiction, provisionals.title, provisionals.name',
			:conditions => get_where(cond)
		})
		
		render_pdf render_to_string(:layout => false), 'provisionals.pdf'
				
	end
	
	def remove_from_master
		typ = nil
		if params[:obj_typ] == 'exam'
			typ = Exam
		elsif params[:obj_typ] == 'list'
			typ = PreferredList
		end
		typ.find(params[:obj_id]).update_attribute :include_on_master, false
		render :nothing => true
	end
	
	def master
		objs = Exam.find(:all, :conditions => 'exams.include_on_master = 1').to_a
		objs += PreferredList.find(:all, {
			:conditions => 'preferred_lists.include_on_master = 1',
			:include => [:job, :agency, :department]
		}).to_a
		objs += Job.find(:all, {
			:include => :exams,
			:conditions => 'jobs.ordered_date != "" and (exams.id is null)'
		}).to_a
		objs = objs.sort_by(&:title)
		if params[:html]
			@objs = objs
			render :layout => false
		else
			book = Spreadsheet::Workbook.new
			sheet = book.create_worksheet
			sheet.row(0).concat(['TITLE', 'EXAM #', 'TEST DATE', 'LIST EST.', 'LIST EXP.', 'EXAM ORD.', 'NOTES'])
			sheet.column(0).width = 50
			sheet.column(1).width = 12
			sheet.column(2).width = 12
			sheet.column(3).width = 12
			sheet.column(4).width = 12
			sheet.column(5).width = 12
			grey_format = Spreadsheet::Format.new :pattern => 1, :pattern_fg_color => :grey
			yellow_format = Spreadsheet::Format.new :pattern => 1, :pattern_fg_color => :yellow
			0.upto(6) { |j|
				sheet.row(0).set_format(j, yellow_format)
			}		
			objs.each_with_index { |o, i|
				pl = o.is_a? PreferredList
				job = o.is_a? Job
				sheet[i + 1, 0] = o.title
				sheet[i + 1, 5] = pl ? nil : o.ordered_date			
				if !job
					sheet[i + 1, 1] = pl ? 'PREFERRED LIST' : o.exam_no
					sheet[i + 1, 2] = pl ? nil : o.given_at.d0?
					sheet[i + 1, 3] = o.established_date.d0?
					sheet[i + 1, 4] = o.valid_until.d0?
					if  pl
						pl_notes = [o.agency && o.agency.name.to_s, o.department && o.department.name.to_s].reject(&:blank?).uniq.join(' ')
						if !o.master_notes.blank?
							pl_notes += ", NOTES: #{o.master_notes}"
						end
						sheet[i + 1, 6] = pl_notes
					else
						sheet[i + 1, 6] = o.master_notes
					end
					if o.grey_on_master?
						0.upto(5) { |j|
							sheet.row(i + 1).set_format(j, grey_format)
						}
					end
				end
			}
			data = StringIO.new
			book.write data
			send_data data.string, :filename => 'master.xls', :type => 'application/vnd.ms-excel'
		end
	end	
	
	def layoff

		@from_date = Date.parse(params[:from_date])
		@to_date = Date.parse(params[:to_date])
		
		@objs = DB.query('
			select e.first_name, e.last_name, a.action_date, t.name, ag.name agency_name, d.name department_name, a.classification, j.name job_name
			from empl_actions a
			join employees e on e.id = a.employee_id
			join empl_action_types t on t.id = a.empl_action_type_id
			left join departments d on d.id = a.department_id
			left join agencies ag on ag.id = a.agency_id
			left join jobs j on j.id = a.job_id
			where a.action_date between "%s" and "%s"
			and t.name in ("BUMP", "LAYOFF")
			order by e.last_name, e.first_name',
			@from_date.to_s,
			@to_date.to_s
		)
		@print_orient = 'Landscape'
		render_pdf render_to_string(:layout => false), 'layoff-bump.pdf'
	end
	
	def perf_test

		@from_date = Date.parse(params[:from_date]) rescue nil
		@to_date = Date.parse(params[:to_date]) rescue nil
		
		cond = []
		cond << 'date(e.given_at) >= "' + @from_date.strftime('%Y-%m-%d') + '"' if @from_date
		cond << 'date(e.given_at) <= "' + @to_date.strftime('%Y-%m-%d') + '"' if @to_date
		cond << 'pt.id = ' + params[:perf_test_id].to_i.to_s if !params[:perf_test_id].blank?
		w = get_where(cond)
		
		@objs = DB.query('
			select pt.name perf_test_name, e.exam_no, e.title, e.given_at from exams e
			join exam_perfs ep on ep.exam_id = e.id
			join perf_tests pt on pt.id = ep.perf_test_id
			' + (!w.blank? ? " where #{w} " : '') + '
			order by e.given_at, e.exam_no, pt.name'
		)
		render_pdf render_to_string(:layout => false), 'perf-test.pdf'
	end
	
	def perf_test_results

		@from_date = Date.parse(params[:from_date]) rescue nil
		@to_date = Date.parse(params[:to_date]) rescue nil
		@perf_tests = params.perf_test_ids.empty? ? [] : PerfTest.find(params.perf_test_ids)
		cond = ['a.approved = "Y"']
		cond << DB.escape('date(e.given_at) >= "%s"', @from_date.to_s) if @from_date
		cond << DB.escape('date(e.given_at) <= "%s"', @to_date.to_s) if @to_date
		cond << DB.escape('pt.id in (%s)', params.perf_test_ids.map(&:to_i) * ',') if !params.perf_test_ids.empty?
		pci = params.perf_code_ids || []
		pci_cond = []
		@include_no_result = pci.include?('')
		pci_cond << '(pc.id is null)' if @include_no_result
		pci = pci.reject(&:blank?).map(&:to_i)
		pci_cond << DB.escape('(pc.id in (%s))', pci * ',') if !pci.empty?
		@perf_codes = pci.empty? ? [] : PerfCode.find(pci)
		cond << pci_cond * ' or '
		result = DB.query(q = 'select e.exam_no, e.title, e.given_at, pt.name, p.first_name, p.last_name, pc.label from exams e
			join exam_perfs ep on ep.exam_id = e.id
			join perf_tests pt on pt.id = ep.perf_test_id
			join applicants a on a.exam_id = e.id
			join people p on p.id = a.person_id
			left join taken_perfs tp on tp.exam_id = e.id and tp.applicant_id = a.id and tp.perf_test_id = pt.id
			left join perf_codes pc on pc.id = tp.perf_code_id where ' + 
			get_where(cond) + ' order by pt.name, pc.label, p.first_name, p.last_name'
		)
		@objs = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
		result.each_hash { |h|
			@objs[h.name.to_s][h.label.to_s] << h
		}

		render_pdf render_to_string(:layout => false), 'perf-test-results.pdf'
	end
	
	def survey

		@from_date = Date.parse(params[:from_date]) rescue nil
		@to_date = Date.parse(params[:to_date]) rescue nil
		
		cond = []
		cond << DB.escape('date(created_at) >= "%s"', @from_date.to_s(:db)) if @from_date
		cond << DB.escape('date(created_at) <= "%s"', @to_date.to_s(:db)) if @to_date
		
		@objs = AppSurvey.find(:all, :order => 'created_at', :include => :web_applicant, :conditions => get_where(cond))
		@totals = Array.new(3) { |i| Hash.new { |h, k| h[k] = 0 } }
		@total = 0
		@objs.each { |o|
			@total += 1
			@totals[0][o.q1.to_i] += 1
			@totals[1][o.q2.to_i] += 1
			@totals[2][o.q3.to_i] += 1
		}
		render :layout => false
	end
	
end