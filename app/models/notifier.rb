class Notifier < ActionMailer::Base
	
	DEFAULT_FROM = 'Monroe County Civil Service <civilservice@monroecounty.gov>'
	
	def message m
		recipients m.person.email_with_name
		if m.email_from.blank?
			from DEFAULT_FROM
		else
			from m.email_from
		end
		subject 'Monroe County Civil Service Letter'
		body :m => m
	end

	def form_status u, f
		recipients u.collect { |i| i.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject f.form_type + " Form Status Updated (#{f.status})"
		body :o => f
	end
	
	def form_submitted u, f
		recipients u.collect { |i| i.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject f.form_type + ' Form Submitted'
		body :o => f
	end
	
	def cert_request u, c
		recipients u.collect { |u| u.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject 'Certified List Requested'
		body :c => c
	end
	
	def cert u, c
		recipients u.collect { |u| u.email_with_name }
		subject 'Certified List Available'
		from Thread.current[:current_user].email_with_name
		body :c => c
	end
	
	def cert_specialist c
		recipients ['JMcCann@monroecounty.gov']
		subject 'Certified List Pending'
		from Thread.current[:current_user].email_with_name
		body :c => c
	end
	
	def cert_complete u, c
		recipients u.collect { |u| u.email_with_name }
		subject 'Certified List Completed/Returned'
		from Thread.current[:current_user].email_with_name
		body :c => c
	end

	def perf_request u, o
		recipients u.collect { |i| i.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject 'Preferred List Certification Requested'
		body :o => o
	end
	
	def perf_certify u, o
		recipients u.collect { |i| i.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject 'Preferred List Certified'
		body :o => o
	end
	
	def perf_complete u, o
		recipients u.collect { |i| i.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject 'Preferred List Completed'
		body :o => o
	end	
	
	def new_exams e, fname, txt = ''
		recipients e
		from DEFAULT_FROM
		subject 'New Civil Service Exams Announced'
		body :fname => fname, :txt => txt
	end
	
	def web_exam_deadline u, web_exams
		recipients [u.email_with_name]
		from DEFAULT_FROM
		subject 'Civil Service Web Post Deadline Today'
		body :u => u, :web_exams => web_exams
	end
	
	def expiring_cr exams
		recipients ['kconklin@monroecounty.gov', 'NDobson@monroecounty.gov']
		from DEFAULT_FROM
		subject 'Continuous Recruitment Exams Expiring!'
		body :exams => exams
	end
	
	def mailtest
		recipients ['jesse@unicornelex.com', 'jessesternberg@monroecounty.gov']
		subject 'Test Email From MCCS'
		from DEFAULT_FROM
		body :a => 'TEST'
	end
	
	def pay_cert u, o
		recipients u.collect { |u| u.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject 'Payroll Certification Uploaded'
		body :o => o
	end
	
	# Only called from the console. A quick way to batch process email blasts. Populate email_blasts
	# table with whatever you want. Example:
	# insert into blast_emails (email)
	# select distinct email from mccs.users
	# union select distinct email from mccs.people
	# union select distinct email from hr_apply_online.users
	# union select distinct email from hr_apply_online.subscriptions
	# order by email
	def self.process_blast_social limit = 1000
		result = DB.query('select * from blast_emails where sent = 0 limit 0, %d', limit)
		result.each_hash { |h|
			p "Sending Email To: #{h.email}"
			Notifier.deliver_blast_social h.email
			DB.query('update blast_emails set sent = 1 where id = %d', h.id);
			p "Email Sent!"
		}
	end
	
	def notice n
		recipients n.users.collect &:email_with_name
		subject n.subject
		from n.user.email_with_name
		body :n => n
	end
		
	def blast_social e
		recipients [e]
		subject 'Never Miss a Job or Exam Announcement'
		from DEFAULT_FROM
		body({})
	end
	
	def custom_email r, s, f, b
		recipients r
		subject s
		from f
		body :b => b
	end
		
	# DEV ONLY!
	def recipients *args
		logger.info 'recipients overloaded...'
		if RAILS_ENV == 'development'
			logger.info 'Sending dev email...'
			super ['jessesternberg@monroecounty.gov']
		else
			super *args
		end
	end


end
