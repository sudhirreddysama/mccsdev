class CertBottomNote < ActiveRecord::Base

	validates_presence_of :value, :typ
	
	def label; "Cert Comment #{id}"; end

end