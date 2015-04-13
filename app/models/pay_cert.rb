class PayCert < ActiveRecord::Base
	
	belongs_to :agency
	belongs_to :user
	has_many :pay_cert_lines, :dependent => :delete_all
	
	has_many :documents
	belongs_to :last_document, :foreign_key => :last_document_id, :class_name => 'Document'
	
	def label; "#{as_of_date.d0} #{agency ? agency.name : 'UNKNOWN'}"; end
	
	validates_presence_of :agency
	def validate
		if !as_of_date 
			errors.add_to_base 'Date of payroll is required.'
		end
	end
	
	attr :file, true

	def path; "pay_certs/#{id}-#{filename}"; end

	#def save_filename
	#	self.filename = file.original_filename if file
	#	return true
	#end
	#before_save :save_filename

	def save_file
		if file
			documents.create({
				:uploaded_file => file,
				:user_id => user_id
			})
		end
		#`cp "#{file.path}" "#{path}"` if file
	end
	after_save :save_file
	
	def self.convert_files_to_documents
		pay_certs = PayCert.find(:all)
		pay_certs.each { |c|
			d = c.documents.create({
				:uploaded_file => {
					:original_filename => c.filename,
					:path => c.path
				}
			})
			c.update_attribute :last_document_id, d.id
		}
	end
	
	def process_file doc_id = nil
		empl_ids = []
		pay_cert_lines.clear
		self.verified_count = 0
		self.error_count = 0
		
		if doc_id
			csv_path = documents.find(doc_id).path
			self.last_document_id = doc_id
		else
			csv_path = path
		end
		
		FasterCSV.foreach(csv_path, :headers => true, :skip_blanks => true) { |r|
			if r['ssn'].to_s.match /(\d{3})(\d{2})(\d{4})/
				r['ssn'] = "#{$1}-#{$2}-#{$3}"
			end
			
			r['salary_wage'] = r['salary_wage'].to_s.gsub(/[^0-9.]/, '')
			
			l = pay_cert_lines.build({
				:first_name => r['first_name'].to_s,
				:last_name => r['last_name'].to_s,
				:ssn => r['ssn'].to_s,
				:title => r['title'].to_s,
				:salary_wage => r['salary_wage'].to_s,
				:retirement_no => r['retirement_no'].to_s
			})
			logger.info r['last_name'].to_s
			cond = 'employees.date_hired <= "%s"' % as_of_date.to_s			
			
			if !empl_ids.empty?
				cond = [cond + ' and employees.id not in (?)', empl_ids]
			end
			
			empl = agency.employees.find_all_by_ssn(l.ssn, {
				:include => :job, 
				:conditions => cond,
				:order => '(leave_date is not null)'
				}).to_a
			
			e = nil
			
			has_future_actions = false
			
			actions = {}
			
			if empl.length > 0
			
				empl.each { |c|
					acts = c.empl_actions.find(:all, {
						:order => 'empl_actions.action_date desc'
					})
					acts.each { |a|
						if a.action_date > as_of_date
							l.has_future_actions = true
						else
							actions[c.id] = a
							#l.empl_action = a
							break
						end
					}
				}
				#e = empl.find { |c| l.empl_action.job.name.to_s == l.title.upcase }
				e = empl.find { |c| actions[c.id].job.name.to_s == l.title.upcase }
				if !e
					#e = empl.find { |c| l.empl_action.wage.to_s == l.salary_wage.to_s }
					e = empl.find { |c| actions[c.id].wage.to_s == l.salary_wage.to_s }
				end
				if !e # Just for fun lets try finding a title that begins with the first letter.
					#e = empl.find { |c| l.empl_action.job.name.to_s[0,1] == l.title.upcase[0,1] }
					e = empl.find { |c| actions[c.id].job.name.to_s[0,1] == l.title.upcase[0,1] }
				end
			end
			if !e
				e = empl[0]
			end
			
			if e
			
				l.empl_action = actions[e.id]
			
				ef = e.first_name.to_s.upcase.split(' ')[0]
				lf = l.first_name.to_s.upcase.split(' ')[0]
				el = e.last_name.to_s.upcase.split(' ')[0]
				ll = l.last_name.to_s.upcase.split(' ')[0]
			
				l.name_error = (ef != lf || el != ll)
				l.title_error = (l.empl_action.job.name.to_s.upcase != l.title.to_s.upcase)
				
				l.salary_wage_error = (l.empl_action.wage.to_s.upcase != l.salary_wage.to_s.upcase)
				l.retirement_no_error = (e.pension_no.to_s.upcase != l.retirement_no.to_s.upcase)
				l.leave_error = ((e.leave_date && e.leave_date < as_of_date) ? true : false)
				l.employee_id = e.id
				empl_ids << e.id
			end
			
			l.save
			
			if l.name_error || l.title_error || l.salary_wage_error || l.retirement_no_error || l.leave_error || !e
				self.error_count += 1
			else
				self.verified_count += 1				
			end
			
		}	
		
		cond = nil
		cond = ['employees.id not in (?) and (employees.leave_date is null or employees.leave_date > ?) and employees.date_hired <= ?', empl_ids, as_of_date, as_of_date] unless empl_ids.empty?
		
		empl = agency.employees.find(:all, :conditions => cond)
		
		empl.each { |e|
			l = pay_cert_lines.build({
				:first_name => e.first_name,
				:last_name => e.last_name,
				:ssn => e.ssn,
				:title => e.job.name,
				:salary_wage => e.wage,
				:retirement_no => e.pension_no,
				:no_record_error => true,
				:employee_id => e.id
			})
			self.error_count += 1
			l.save
		}
		
		save
		
	end

	
	include DbChangeHooks
	
end