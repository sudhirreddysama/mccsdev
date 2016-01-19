class PayCertController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'pay_certs.as_of_date',
			:dir1 => 'desc',
			:sort2 => 'agencies.name',
			:dir2 => 'asc'
		})
		@orders = [
			['ID', 'pay_certs.id'],
			['As Of Date', 'pay_certs.as_of_date'],
			['Agency Name', 'agencies.name']
		]
		cond = get_search_conditions @filter[:search], {
			'pay_certs.id' => :left,
			'agencies.name' => :like
		}
		
		@date_types = [
			['Date of Payroll', 'pay_certs.as_of_date']
		]
		
		cond << get_date_cond
		
		if @current_user.agency_level?
			cond << 'pay_certs.agency_id = %d' % @current_user.agency_id
		end
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => :agency
		}
		super
	end
	
	def build_obj
		super
		#@obj.as_of_date = Time.now.to_date unless request.post?
		@obj.user = @current_user
		if @current_user.agency_level?
			@obj.agency = @current_user.agency
		end
	end

	def download
		load_obj
		send_file @obj.path, :filename => @obj.filename
	end
	
	def process_file
		load_obj
		@obj.process_file params[:id2]
		flash[:notice] = 'Payroll certification file has been processed.'
		redirect_to :action => :view, :id => @obj.id
	end
	
	def load_error_lines
		@employee_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'employee_id is null')
		@name_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'name_error = 1')
		@title_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'title_error = 1')
		@salary_wage_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'salary_wage_error = 1')
		@retirement_no_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'retirement_no_error = 1')
		@leave_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'leave_error = 1')
		@no_record_error = @obj.pay_cert_lines.find(:all, :order => 'last_name, first_name', :conditions => 'no_record_error = 1')	
	end

	def view
		if request.post?
			bad_names = []
			params[:wage_changes].each { |w|
				l = @obj.pay_cert_lines.find(w)
				e = l.employee
				d = Date.parse(params[:action_date])
				a = e.empl_actions.find(:first, :conditions => ['empl_actions.action_date <= ?', d], :order => 'empl_actions.action_date desc')
				if a
					e.empl_actions.create({
						:job_id => a.job_id,
						:agency_id => a.agency_id,
						:department_id => a.department_id,
						:wage => l.salary_wage,
						:wage_per => a.wage_per,
						:classification => a.classification,
						:status => a.status,
						:job_time => a.job_time,
						:leave_date => a.leave_date,
						:reference_date => Time.now.to_date,
						:action_date => params[:action_date],
						:empl_action_type_id => 9
					})
				else
					n = "#{e.first_name}, #{e.last_name}"
					logger.info "Couldn't create wage change action for: #{n}"
					bad_names << n
				end
			}
			redirect_to
			flash[:notice] = 'Wage change actions have been saved.' + (bad_names.empty? ? '' : " Could not create wage changes for: #{bad_names.join(', ')}")
		else
			load_error_lines
			super
		end
	end
	
	def load_verified_lines
		@objs = @obj.pay_cert_lines.find(:all, {
			:order => 'last_name, first_name',
			:conditions => '
				employee_id is not null 
				and name_error = 0
				and title_error = 0 
				and salary_wage_error = 0
				and retirement_no_error = 0
				and leave_error = 0
				and no_record_error = 0'
		})
	end
	
	def print
		@print_orient = 'Landscape'
		if params[:id2] == 'verified'
			load_verified_lines
		else
			load_error_lines
		end
		super
	end
	
	def excel
		load_obj 
		load_verified_lines
		load_error_lines
	
		book = Spreadsheet::Workbook.new

		@cols = ['Name', 'SSN','Title', 'Salary Wage', 'Retirement No']

		sheet = book.create_worksheet :name => 'Verified'
		sheet.row(0).concat(@cols)
		@objs.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o))
		}
		
		@cols << 'Error'
		
		sheet = book.create_worksheet :name => 'Employee Not Found'
		sheet.row(0).concat(@cols)
		@employee_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'employee'))
		}
		
		sheet = book.create_worksheet :name => 'Name Mismatch'
		sheet.row(0).concat(@cols)
		@name_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'name'))
		}
		
		sheet = book.create_worksheet :name => 'Title Mismatch'
		sheet.row(0).concat(@cols)
		@title_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'title'))
		}
		
		sheet = book.create_worksheet :name => 'Salary Wage Mismatch'
		sheet.row(0).concat(@cols)
		@salary_wage_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'salary_wage'))
		}
		
		sheet = book.create_worksheet :name => 'Retirement No. Mismatch'
		sheet.row(0).concat(@cols)
		@retirement_no_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'retirement_no'))
		}
		
		sheet = book.create_worksheet :name => 'No Longer Employed'
		sheet.row(0).concat(@cols)
		@leave_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'leave'))
		}
		
		sheet = book.create_worksheet :name => 'Missing From Upload'
		sheet.row(0).concat(@cols)
		@no_record_error.each_with_index { |o, i|
			sheet.row(i + 1).concat(excel_line(o, 'no_record'))
		}
		
		data = StringIO.new
		book.write data
		send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'		
	end
	
	def excel_line o, error = nil
		l = [
			"#{o.last_name}, #{o.first_name}", 
			o.ssn,
			o.title,
			o.salary_wage.to_s,
			o.retirement_no
		]
		if error
			l << o.error_text(error)
		end
		return l
	end
	
	def save_redirect
		if @current_user.agency_level?
			u = Agency.get_liaison(@obj.agency, @current_user.department)
			if u
				Notifier.deliver_pay_cert [u], @obj
			end
		end
		super
	end
	
	def example_file
		send_file 'public/pay-cert-example.csv', :filename => 'pay-cert-example.csv', :type => 'application/excel'
	end	
	
	
end