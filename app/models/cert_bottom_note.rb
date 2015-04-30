class CertBottomNote < ActiveRecord::Base

	validates_presence_of :value
	
	def label; "Cert Comment #{id}"; end

end