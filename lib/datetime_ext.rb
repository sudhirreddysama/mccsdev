module DateTimeExt

	def d0
		to_date.strftime '%m/%d/%y' rescue '00/00/00'
	end
	
	def dy0
		to_date.strftime '%m/%d/%Y' rescue '00/00/00'
	end
	
	def dt0
		to_time.strftime '%m/%d/%y %I:%M%p' rescue '00/00/00 12:00AM'
	end
	
	def dt2
		d = (to_time.strftime '%m/%d/%y') rescue '00/00/00'
		t = (to_time.strftime '%I:%M%p') rescue '12:00AM'
		d + (t == '12:00AM' ? '' : " #{t}")
	end
	
	def t0
		to_time.srftime '%I:%M%p' rescue '12:00am'
	end
	
	def fmt
		to_date.strftime '%B %d, %Y' unless nil?
	end
	
	def short; d0?; end
	def long; fmt; end
	def time; t0?; end
	
	def d0?; d0 unless nil?; end
	def dy0?; dy0 unless nil?; end
	def dt0?; dt0 unless nil?; end
	def dt2?; dt2 unless nil?; end
	def t0?; t0 unless nil?; end

end

class Date
	include DateTimeExt
end

class Time
	include DateTimeExt
end

class DateTime
	include DateTimeExt
end

class NilClass
	include DateTimeExt
end