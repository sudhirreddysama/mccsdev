class Notifier < ActionMailer::Base
	
	DEFAULT_FROM = 'Monroe CS <civilservice@monroecounty.gov>'
	HR_FROM = 'Monroe HR <noreply@monroecounty.gov>'
	
	# This is called from county form controllers. Need to see if there are any recipients before sending email.
	def self.county_form_recipient f
		u = nil
		case f.hr_status
			when 'liaison', 'liaison-final'
				u = Agency.get_liaison(f.agency, f.department)
				#u ? u.email_with_name : nil
			when 'exam-mgr'
				#'Aileen Henning <AHenning@monroecounty.gov>'
				u = User.find_by_username 'ahenning'
			when 'hr-mgr'
				#'Patty English <PEnglish@monroecounty.gov>'
				u = User.find_by_username 'penglish'
			when 'hr-director'
				#'Brayton Connard <BConnard@monroecounty.gov>'
				u = User.find_by_username 'connardb'
			when 'payroll'
				u = f.department && f.department.payroll_user
				#u ? u.email_with_name : nil
			when 'benefits'
				#'Debra Wood <DebraWood@monroecounty.gov>'
				u = User.find_by_username 'dwood'
		end
		return u
	end
	
	def cert_overdue c, users
		subject "Certified List Overdue Notice (#{c.id})"
		recipients users.map(&:email_with_name)
		from DEFAULT_FROM
		body :c => c
	end

	def county_form_status f, to_email, from_email
		recipients to_email
		from from_email
		typ = 'County Form'
		typ = '105(C) Personnel Change Form' if f.is_a?(FormCountyChange)
		typ = '330(C) New Hire Form' if f.is_a?(FormCountyHire)
		subject "[#{f.status}] #{typ} (#{f.id} - #{f.name})"
		body :o => f
	end
	
	def county_form_hr_status f, to_email, from_email, act = nil
		recipients to_email
		from from_email
		typ = 'County Form'
		typ = '105(C) Personnel Change Form' if f.is_a?(FormCountyChange)
		typ = '330(C) New Hire Form' if f.is_a?(FormCountyHire)
		subject "[#{f.hr_status}] #{typ} (#{f.id} - #{f.name})"
		body :o => f, :act => act
	end
	
	def form_action act
		recipients act.recipient.email_with_name
		from act.user.email_with_name
		typ = 'County Form'
		typ = '105(C) Personnel Change Form' if act.obj.is_a?(FormCountyChange)
		typ = '330(C) New Hire Form' if act.obj.is_a?(FormCountyHire)
		subject "[#{act.obj.status}] #{typ} (#{act.obj.id} - #{act.obj.name})"
		body :o => act.obj, :act => act
	end
	
	def lost_password u, url
		recipients u.email_with_name
		from DEFAULT_FROM
		subject 'Account Recovery'
		body :u => u, :url => url
	end
	
	def formatta_login person
		recipients person.email_with_name
		from 'welcome2mc@monroecounty.gov'
		subject 'Monroe County Employment Onboarding Forms'		
		content_type 'text/html'
		#attachment :content_type => 'image/gif', :body => File.read('public/images/mclogo-120x120.gif'), :filename => 'mc.gif'
		#attachment :content_type => 'image/gif', :body => File.read('public/images/brayton-signature-253x100.gif'), :filename => 'sig.gif'
		body :person => person
	end
	
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

	def form_change_provisional f
		recipients ['ahenning@monroecounty.gov']
		from Thread.current[:current_user].email_with_name
		subject f.form_type + ' Form Provisional Change'
		body :o => f
	end
	
	def form_hire_provisional f
		recipients ['ahenning@monroecounty.gov']
		from Thread.current[:current_user].email_with_name
		subject f.form_type + ' Form Provisional Hire'
		body :o => f
	end

	def form_status u, f
		recipients u.collect { |i| i.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject f.form_type + " Form Status Updated (#{f.status})"
		body :o => f
	end
	
	def form_county_personnel f
		if f.status == 'hr-personnel'
			recipients ['PEnglish@monroecounty.gov']
		elsif f.status == 'hr-director'
			recipients ['BConnard@monroecounty.gov']
		end
		from f.status_user.email_with_name
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
	
	def cert_applicant_appointed u, ca
		recipients u.collect { |u| u.email_with_name }
		subject 'Candidate Appointed From Other Certified List'
		from DEFAULT_FROM
		body :ca => ca
	end
	
	def cert_specialist c
		recipients ['meganmetzler@monroecounty.gov']
		subject "Certified List Specialist Notification - Cert #{c.status}"
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
		recipients ['ahenning@monroecounty.gov', 'MDolan@monroecounty.gov']
		from DEFAULT_FROM
		subject 'Continuous Recruitment Exams Expiring!'
		body :exams => exams
	end
	
	def mailtest r = 'jessesternberg@monroecounty.gov', f = 'Monroe CS <civilservice@monroecounty.gov>', s = 'TEST EMAIL', b = 'TEST'
		recipients r
		subject s
		from f
		body :body => b
	end
	
	def pay_cert u, o
		recipients u.collect { |u| u.email_with_name }
		from Thread.current[:current_user].email_with_name
		subject 'Payroll Certification Uploaded'
		body :o => o
	end
	
	def vacancy_submitted u, o
		recipients u.collect { |u| u.email_with_name }
		from o.user.email_with_name
		subject "Request to Fill Vacancy Submitted"
		body :o => o
	end
	
	def vacancy_updated u, o
		recipients u.collect { |u| u.email_with_name }
		from HR_FROM
		subject "Request to Fill Vacancy Decision Update"
		body :o => o
	end
	
	def vacancy_notification f, u, o
		recipients u.collect { |u| u.email_with_name }
		from f.email_with_name
		subject "Request to Fill Vacancy Notification"
		body :o => o, :f => f
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
	
	def pending_cert_exam_established c, e
		u = ['meganmetzler@monroecounty.gov']
		liaison = Agency.get_liaison c.agency, c.department
		u << liaison.email if liaison
		recipients u 
		subject "List Established For Pending Cert: #{c.title}"
		from DEFAULT_FROM
		body :c => c, :e => e
	end

	def login_notice u
		recipients ['jessesternberg@monroecounty.gov']
		subject "#{u.username} HAS LOGGED IN!"
		from DEFAULT_FROM
		body :u => u
	end

	def custom_email r, s, f, b
		recipients r
		subject s
		from f
		body :b => b
	end
	
	def deliver!(mail = @mail)
		begin
			logger.info "#{Time.now.to_s} Mail Subject: #{subject}, To: #{Array(recipients).join(',')}"
			super mail
		rescue Exception => e 
			logger.info 'EMAIL ERROR!'
			logger.info e.inspect
			logger.info mail.encoded
			logger.flush
		end
		return mail
	end
	
	# DEV ONLY!
	def recipients *args
		if RAILS_ENV == 'development'
			if args.size > 0
				logger.info 'Development Env intercepted mail recipients:'
				logger.info args.inspect
			end
			super ['jessesternberg@monroecounty.gov']
		else
			super *args
		end
	end


end
