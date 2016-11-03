class VacancyData < ActiveRecord::Base

	set_table_name 'vacancy_data'
	
	def self.cron
		logger.auto_flushing = true
		logger.info "VacancyData.cron started #{Time.now}"
		ftp = Net::FTP.new '10.100.224.234'
		ftp.login 'civilservice', 's@prtf123'
		data = nil
		# Just schedule the cron job a good time after the SAP dump. The modified time reported by FTP is unreliable. Timezone issue.
		#mtime = ftp.mtime 'positon.txt', true
		#if mtime.advance(:minutes => 10) < Time.now
			logger.info 'Loading File'
			objs = []
			ftp.gettextfile('positon.txt', 'tmp/positon.txt') { |line|
				parts = line.unpack('A8x45A40x8AA8A40A10x2A6x37A2A*') rescue nil
				if parts
					d = VacancyData.new
					d.position_no, d.position, d.status, d.org_no, d.organization, d.cost_center, d.job_no, d.salary_group, d.last_incumbent = parts
					objs << d
				end
			}
			if !objs.empty?
				logger.info "Saving Records, Count: #{objs.size}"
				VacancyData.delete_all
				objs.each &:save
			end
		#end
		ftp.close
		logger.info "VacancyData.cron finished #{Time.now}"
	end
	
end