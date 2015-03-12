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
	
	def new_exams e, fname
		recipients e
		from DEFAULT_FROM
		subject 'New Civil Service Exams Announced'
		body :fname => fname
	end
	
	def web_exam_deadline u, web_exams
		recipients [u.email_with_name]
		from DEFAULT_FROM
		subject 'Civil Service Web Post Deadline Today'
		body :u => u, :web_exams => web_exams
	end
	
	def expiring_cr exams
		recipients ['AHenning@monroecounty.gov', 'NDobson@monroecounty.gov']
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
		
	# DEV ONLY!
	def recipients *args
		if RAILS_ENV == 'development'
			super ['jessesternberg@monroecounty.gov']
		else
			super *args
		end
	end


end
