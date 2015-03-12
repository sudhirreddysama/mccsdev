module NumberExt
	
	include ActionView::Helpers::NumberHelper
	
	def m0
		number_to_currency to_f, :precision => 0
	end
	
	def m2
		number_to_currency to_f, :precision => 2
	end
	
	def n0
		number_to_currency to_f, :precision => 0, :unit => ''
	end
	
	def n2
		number_to_currency to_f, :precision => 2, :unit => ''
	end
	
	def w0
		to_f.round.en.numwords
	end
		
	def w2
		to_f.round(2).en.numwords	
	end
	
	def two_decimals; n2?; end
	def no_decimals; n0?; end
	
	def m0?; m0 unless nil?; end
	def m2?; m2 unless nil?; end
	def n0?; n0 unless nil?; end
	def n2?; n2 unless nil?; end
	def w0?; w0 unless nil?; end
	def w2?; w2 unless nil?; end

end

class Float
	include NumberExt
end

class Fixnum
	include NumberExt
end

class BigDecimal
	include NumberExt
end

class NilClass
	include NumberExt
end

class Rational
	include NumberExt
end