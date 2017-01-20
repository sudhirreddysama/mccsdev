module ApplicationHelper

	def tab txt, p1, p2 = {}, opt = {}
		opt[:class] ||= ''
		opt[:class] += ' active' if p1.all? { |k, v| !v or params[k].to_s == v.to_s }
		p = p1.merge(p2)
		opt[:class] += ' tab-' + p[:action].to_s if p[:action] and !opt[:class].include?('tab-')
		
		if txt == 'Documents'
			dc = @sobj ? @sobj.documents.count : @obj.documents.count
			if dc > 0
				txt += ' <b>' + dc.to_s + '</b>'
			end
		end
		
		link_to('<span>' + txt + '</span>', p, opt)
	end
	
	def partial name, locals = {}, opt = {}
  	opt[:partial] = name
  	opt[:locals] = locals
  	begin
			render opt
		rescue ActionView::MissingTemplate, Errno::ENOENT
			opt[:partial] = 'partial/' + opt[:partial].to_s
			render opt
		end	
	end
	
	def nl2br s
	  s.to_s.gsub(/\n/, '<br />')
 	end
 	
 	def nl2br_h s
 		return nl2br(h(s))
 	end
	
	def m n
		number_to_currency n.to_f, :unit => '$' if n
	end
	
	def m0 n
		number_to_currency n.to_f, :unit => '$' if n && n.to_f > 0
	end
	
	def nwp n, p = 0
		n ? number_to_currency(n.to_f, :precision => p, :delimeter => ',', :unit => '') : ''
	end
	
	def table_form_for(record_or_name_or_array, *args, &proc)
    options = args.extract_options!
  	form_for(record_or_name_or_array, *(args << options.merge(:builder => TableFormBuilder))) { |f|
  		concat '<table class="form">'
  		proc.call(f)
  		concat '</table>'
  	}
  end
  
	def comma_h *args
		args.collect { |s| s.to_s.strip }.reject(&:blank?).collect { |v| h v }.join ', '
	end
  
	def raw_table_form_for(record_or_name_or_array, *args, &proc)
    options = args.extract_options!
  	form_for(record_or_name_or_array, *(args << options.merge(:builder => TableFormBuilder))) { |f|
  		proc.call(f)
  	}
  end
	
	def yn f
		f ? '<span class="yes">yes</span>' : '<span class="no">no</span>'
	end
	
	def yn? f
		f.nil? ? '' : f ? '<span class="yes">yes</span>' : '<span class="no">no</span>'
	end
	
	def err e = []
		partial 'errors', :errors => e
	end
	
	def phone_format p
		md = /(\d{3})(\d{3})(\d{4})(.*)/.match(p)
		if md
			return "(#{md[1]}) #{md[2]}-#{md[3]}#{md[4]}"
		end
		md = /(\d{3})(\d{4})(.*)/.match(p)
		if md
			return "(#{md[1]}-#{md[2]}#{md[4]}"
		end
		return p
	end
	
	def load_applicant_review_options
		@disapprovals = Disapproval.find(:all, :order => 'reason').collect { |d| [d.reason, d.id] }
		@app_statuses = @statuses.collect { |s| [s.name, s.id] }
		#@exam_sites = ExamSite.find(:all, :order => 'name').collect { |s| [s.name, s.id] }
		#@perf_tests = PerfTest.find(:all, :order => 'name').collect { |t| [t.name, t.id] }
		#@perf_codes = PerfCode.find(:all, :order => 'label').collect { |c| [c.label, c.id] }
		@agency_opts = Agency.find(:all, :order => 'name').collect { |a| [a.name, a.id] }
		@department_opts = Department.find(:all, :order => 'name').collect { |d| [d.name, d.id] }
	end
	
	def cert_status s
		s = s.to_s
		'<div class="cert-status cert-' + s + '">' + s + '</div>'
	end
	
	def form_status s
		s = s.to_s
		'<div class="form-status form-' + s + '">' + s + '</div>'
	end
	
	def vac_status s
		s = s.to_s
		s = 'None' if s.blank?
		'<div class="form-status form-' + s.downcase + '">' + s + '</div>'
	end	
	
	def pref_status s
		s = s.to_s
		'<div class="pref-status pref-' + s + '">' + s + '</div>'
	end	

	def pref_mil t
		t = t.to_s
		'<div class="pref-mil pref-mil-' + t + '">' + t + '</div>'
	end
	
	def load_job_options current_or_prior = nil
		#cond = ['employees.id is not null']
		# Might have to re-enable this (remove "false &&" if they end up wanting the report to be limited to title run, but that will exclude employees with erroneous titles!
		jobs = nil
		if false && @current_user.has_title_run? 
			jobs = Job.find(:all, {
				:order => 'jobs.inactive asc, jobs.name asc', 
				:include => :agency_jobs,
				:conditions => ['agency_jobs.agency_id = ?', @current_user.agency_id],
				:group => 'jobs.id'
			})
		else
			empl_cond = []
			if current_or_prior == 'current'
				empl_cond << '(e.leave_date is null or e.leave_date > date(now()))'
			elsif current_or_prior == 'prior'
				empl_cond << '(e.leave_date <= date(now()))'
			end
			if @current_user.agency_level?
				if @current_user.agency
					empl_cond << 'e.agency_id = %d' % @current_user.agency_id
				end
				if @current_user.department
					empl_cond << 'e.department_id = %d' % @current_user.department_id
				end
			end
			jobs = Job.find(:all, {
				:order => 'jobs.inactive asc, jobs.name asc', 
				:joins => empl_cond.empty? ? nil : 'join employees e on e.job_id = jobs.id and ' + empl_cond.join(' and '), 
				:group => 'jobs.id'
			})
		end
		@job_options = jobs.collect { |j| [j.inactive ? "-#{j.name} (inactive)" : j.name, j.id] }
	end
	
end
