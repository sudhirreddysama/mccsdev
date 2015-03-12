class ListNote < ActiveRecord::Base

	belongs_to :applicant
	
	def label; "Note ID #{id}"; end
	
	def date; note_date; end
	
	def app_status_id
		if applicant && !@app_status_id
			@app_status_id = applicant.app_status_id
		end
		return @app_status_id
	end
	
	def app_status_id= v
		v = v.to_i
		v = nil if v == 0
		@app_status_id = v
	end
	
	def status_code
		if applicant && !@status_code
			@status_code = applicant.status_code
		end
		return @status_code
	end
	
	def status_code= v
		@status_code = v
	end
	
	def handle_after_save
		if applicant
			if !@app_status_id.blank?
				applicant.update_attribute :app_status_id, @app_status_id
			elsif !@status_code.blank?
				applicant.update_attribute :status_code, @status_code
			end
		end
	end
	
	after_save :handle_after_save
	
	
	
	include DbChangeHooks
	
end