class WebEmployment < ActiveRecord::Base

	set_table_name 'hr_apply_online.employments'	
	
	belongs_to :web_applicant, :foreign_key => 'applicant_id'
	
	def full_address j = "\n"
		[address.to_s.strip, address2.to_s.strip, csz].reject(&:blank?).join(j)
	end	
	
	def csz
		[[city.to_s.strip, state.to_s.strip].reject(&:blank?).join(', '), zip.to_s.strip].reject(&:blank?).join(' ')
	end	
	
	def empl_to
		return end_date if end_date
		return web_applicant.submitted_at.to_date if web_applicant && web_applicant.submitted_at
	end
	
	def calculate_years
		y = {}
		to_date = empl_to
		
		hours_per_week = hours.to_i rescue 0
		
		if start_date && to_date && hours_per_week > 0
			y.years_raw = (to_date - start_date) / 365
			
			# Min qualifications
			if hours_per_week <= 9
				y.years_min = y.years_raw * hours_per_week / 40
			elsif hours_per_week <= 14
				y.years_min = y.years_raw * 0.25
			elsif hours_per_week <= 29
				y.years_min = y.years_raw * 0.5
			else
				y.years_min = y.years_raw
			end
			
			# T&E Score
			if hours_per_week < 10
				y.years_te = 0
			elsif hours_per_week < 25
				y.years_te = y.years_raw * 0.5
			else
				y.years_te = y.years_raw
			end
			
			y.years_te_minus_min = y.years_te - y.years_min
			
		else
			y.years_raw = nil
			y.years_min = nil
			y.years_te = nil
		end
		
		return y
		
	end	
	
end