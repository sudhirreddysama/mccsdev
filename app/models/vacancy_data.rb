class VacancyData < ActiveRecord::Base
	
	has_many :vacancies, :primary_key => 'position_no', :foreign_key => 'position_no'
	
	set_table_name 'vacancy_data'
	
	def label; "#{last_incumbent_was} - #{position_was}"; end
	
	def name_fml; [first_name, middle_name, last_name].reject(&:blank?) * ' '; end
	
	def self.cron
		logger.auto_flushing = true
		logger.info "VacancyData.cron started #{Time.now}"
		ftp = Net::FTP.new '10.100.224.234'
		ftp.login 'civilservice', 's@prtf123'
		data = nil
		logger.info 'Loading File'
		objs = []
		first = true
		ftp_file = 'position_maxx.txt'
		#ftp_file = 'position_maxx_qr1.txt'
		ftp.gettextfile(ftp_file, 'tmp/position_maxx.txt') { |line|
			if first
				first = false
				next
			end
			#line = line.ljust(207) # Minimum length, right most fields not required.
			parts = line.split('|')
			if parts[1]
				d = VacancyData.new({
					:position_no => parts[0],
					:position => parts[2],
					:status => parts[4],
					:org_no => parts[5],
					:organization => parts[6],
					:cost_center => parts[7],
					:job_no => parts[8],
					:salary_group => parts[9],
					:last_incumbent => parts[10],
					:county_org_no => parts[11],
					:flsa_exempt => parts[12],
					:personnel_no => parts[13],
					:last_name => parts[14],
					:first_name => parts[15],
					:middle_name => parts[16],
				})
				d.id = "#{d.position_no}-#{d.personnel_no}"
				objs << d
			end
		}
		if !objs.empty?
			logger.info "Saving Records, Count: #{objs.size}"
			VacancyData.delete_all
			objs.each &:save
		end
		objs = []
		ftp.gettextfile('position_maxx_cost.txt', 'tmp/position_maxx_cost.txt') { |line|
			parts = line.split('|')
			if parts[0]
				d = VacancyCostData.new
				d.position_no, d.sequence, d.company_code, d.business_area, d.conrolling_area, d.object_type, d.cost_center, d.order_no, d.wbs_element, 
					d.fin_manage_area, d.fund, d.functional_area, d.grant, d.funds_center, d.service_type, d.service_category, d.segment, 
					d.budget_period, d.percentage = parts
				objs << d
			end
		}
		if !objs.empty?
			logger.info "Saving Cost Records, Count: #{objs.size}"
			VacancyCostData.delete_all
			objs.each &:save
		end
		ftp.close
		logger.info "VacancyData.cron finished #{Time.now}"
	end
	
	# Currently only MONROE COUNTY-SHERIFF (cc = "38...") or MONROE COUNTY
	def agency
		return @agency if @agency_loaded
		@agency_loaded = true
		cc = cost_center.to_s[0, 2]
		agens = Agency.find(:all, :conditions => ['find_in_set(?, vacancy_data_codes)', cc])
		@agency = agens[0] if agens.size == 1
		@agency ||= Agency.find_by_abbreviation('MC')
	end
	
	def department
		return @department if @department_loaded
		@department_loaded = true
		cc = cost_center.to_s[0, 2]
		depts = Department.find(:all, :conditions => ['find_in_set(?, vacancy_data_codes)', cc])
		@department = depts[0] if depts.size == 1
	end
	
	def autocomplete_json_data field = 'search'
		{
			:id => id,
			:organization => organization,
			:org_no => org_no,
			:cost_center => cost_center,
			:position => position,
			:position_no => position_no,
			:last_incumbent => last_incumbent,
			:salary_group => salary_group,
			:status => status,
			:county_org_no => county_org_no,
			:job_no => job_no,
			:flsa_exempt => flsa_exempt,
			:personnel_no => personnel_no,
			:last_name => last_name,
			:first_name => first_name,
			:middle_name => middle_name,
			:label => field == 'search' ? "#{position} - #{last_incumbent.blank? ? '(NO INCUMBENT)' : last_incumbent}" : send(field)
		}	
	end
	
end