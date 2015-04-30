class CertEndOfList < ActiveRecord::Base

	validates_presence_of :value

	def label; "Cert End of List #{id}"; end

end