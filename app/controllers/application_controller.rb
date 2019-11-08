class ApplicationController < ActionController::Base
	
	
	filter_parameter_logging :password
	
	include ExceptionNotifiable

	def render_nothing
		render :nothing => true
	end
	
	def force_ssl
		unless request.ssl?
			# redirect_to :protocol => 'https://'
			return false
		end
	end
	before_filter :force_ssl
	
	def forbid_ssl
		if request.ssl?
			# redirect_to :protocol => 'http://'
			return false
		end
	end
	
	def error_test; this_will_throw_an_error; end
	  
	helper :all
	
	def load_user
		@current_user = User.find_by_id session[:current_user_id], :conditions => 'users.level != "disabled"' if session[:current_user_id]
		Thread.current[:user_id] = session[:current_user_id]
		Thread.current[:current_user] = @current_user
	end
	before_filter :load_user
	
	def authenticate
		if !@current_user
			redirect_to :sc => nil, :sid => nil, :controller => :account, :action => :index
			session[:after_login] = request.url
			flash[:notice] = 'Please log in or register a new account to continue.'
			return false
		elsif session[:reset_password]
			session[:after_login] = request.url
			redirect_to :sc => nil, :sid => nil, :controller => :account, :action => :password
			flash[:notice] = 'Please reset your password.'
		end
		true
	end
	before_filter :authenticate
	
	def block_agency_users
		if !@current_user.above_agency_level?
			render_nothing
			return false
		end
		return true
	end
	before_filter :block_agency_users
	
	def options; end
	before_filter :options
	
	def load_top_text
		p = request.path + '/'
		@top_texts = TopText.find(:all, :conditions => ['? like top_texts.path and top_texts.hidden = 0', p])
	end
	before_filter :load_top_text
	
	def template opt = nil
		return if @performed_render
		begin
			render opt
		rescue ActionView::MissingTemplate, Errno::ENOENT
			opt ||= {}
			a = opt[:action] || params[:action]
			render opt.merge({:template => "partial/#{a}", :layout => 'application'})
		end
	end
	
  def get_search_conditions search, fields
  	search = search.to_s.gsub(',', '')
  	words = search.split ' '
  	return([]) if words.empty?
  	words.collect { |w|
  		fields.collect { |f, type|
				case type
					when :eq
						DB.escape("(#{f} = '%s')", w)
					when :like
						DB.escape("(#{f} like '%%%%%s%%%%')", w)
					when :left
						DB.escape("(#{f} like '%s%%%%')", w)
				end
  		}.join ' or '
  	}
  end
  
  def get_where c
  	c = c.reject &:blank?
  	return nil if c.empty?
  	'(' + c.join(') and (') + ')'
  end
  
  def get_where_or c
  	c = c.reject &:blank?
  	return nil if c.empty?
  	'(' + c.join(') or (') + ')'
  end
  
	def get_order opts, ord
		orders = []
		ord.each { |o|
			sel = opts.rassoc(o[0])
			if sel
				orders << "isnull(#{sel[1]}), #{sel[1]} " + (['desc', 'asc'].include?(o[1]) ? o[1] : '') 
			end
		}
		orders.empty? ? nil : orders.join(', ')
	end
	
	def get_order_auto
		get_order(@orders, [[@filter[:sort1], @filter[:dir1]], [@filter[:sort2], @filter[:dir2]], [@filter[:sort3], @filter[:dir3]]])
	end
	
	def get_filter default = {}, name = nil
		name ||= "#{params[:controller]}_#{params[:action]}_filter" + (params[:popup] ? '_pop' : '')
		@filter = params[:filter] || session[name]
		@filter = default if !@filter or @filter[:clear]
		session[name] = @filter
	end
	
	def get_date_cond
		cond = []
		date_type = @date_types.rassoc(@filter[:date_type])
		dt = date_type[1] if date_type
		d1 = Date.parse(@filter[:from_date]) rescue nil
		d2 = Date.parse(@filter[:to_date]) rescue nil
		cond << "#{dt} >= date('%s')" % d1 if dt && d1
		cond << "#{dt} <= date('%s')" % d2 if dt && d2
		@filter_d1 = d1
		@filter_d2 = d2
		@filter_dt = dt
		@filter_dtl = date_type[0] if date_type
		return cond
	end
	
  def get_date_condx
    cond = []
    dt = @date_types.rassoc(@filter[:date_type])[1] rescue nil
    d1 = Date.parse(@filter[:from_date]) rescue nil
    d2 = Date.parse(@filter[:to_date]) rescue nil
    cond << "#{dt} >= '%s 00:00'" % d1 if dt && d1
    cond << "#{dt} <= '%s 23:59'" % d2 if dt && d2
    return cond
  end
  
	def get_numeric_cond
		cond = []
		dt = @no_types.rassoc(@filter[:no_type])[1] rescue nil
		d1 = @filter[:no_min].to_f unless @filter[:no_min].blank?
		d2 = @filter[:no_max].to_f unless @filter[:no_max].blank?
		cond << "#{dt} >= %f" % d1 if dt && d1
		cond << "#{dt} <= %f" % d2 if dt && d2
		return cond
	end	
	
	def render_htmldoc filename, opts = {}
		f = TempfileExt.open 'htmldoc.html', 'tmp'
		p = TempfileExt.open 'htmldoc.pdf', 'tmp'	
		opts[:layout] ||= false
		f.write render_to_string(opts)
		f.close
		p.close
		`htmldoc -t pdf --webpage --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 10 --headfootfont Arial --headfootsize 7 #{opts[:landscape] ? '--landscape' : ''} -f #{p.path} #{f.path}`
		send_file p.path, :filename => filename, :type => "application/pdf", :disposition => 'inline'
	end
	
	def render_pdf html, fname, opt = {}
		f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
		p = TempfileExt.open 'wkhtmltopdf.pdf', 'tmp'
		f.write html
		f.close
		p.close
		marg = opt[:margin] || '.5in'
		orient = @print_orient || 'Portrait'
		`wkhtmltopdf --disable-smart-shrinking -s Letter -O #{orient} #{opt[:flags]} --margin-left #{marg} --margin-right #{marg} --margin-top #{marg} --margin-bottom #{marg} #{f.path} #{p.path}`
		send_file p.path, :filename => fname, :disposition => 'inline', :type => 'application/pdf'
	end	
	
	def render_pdf_to_file html, fname, opt = {}
		f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
		f.write html
		f.close
		orient = opt[:orient] || @print_orient || 'Portrait'
		`wkhtmltopdf --disable-smart-shrinking -s Letter -O #{orient} --margin-left 1in --margin-right 1in --margin-top .5in --margin-bottom .5in #{f.path} #{fname}`
	end
	
	def render_pdf_to_file2 html, fname, opt = {}
		f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
		f.write html
		f.close
		marg = opt[:margin] || '.5in'
		orient = opt[:orient] || @print_orient || 'Portrait'
		`wkhtmltopdf --disable-smart-shrinking #{opt[:arg]} -s Letter -O #{orient} --margin-left #{marg} --margin-right #{marg} --margin-top #{marg} --margin-bottom #{marg} #{f.path} #{fname}`
	end		
	
	
	def parse_advanced_applicant_filter
		extra_joins = []
		include_web_applicant = false
		cond = []	
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
		return cond, extra_joins
	end
	
end




