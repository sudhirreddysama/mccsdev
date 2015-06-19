class CertEndOfList < ActiveRecord::Base

	validates_presence_of :value, :typ

	def label; "Cert End of List #{id}"; end

end