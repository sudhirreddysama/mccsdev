class Disapproval < ActiveRecord::Base

	validates_presence_of :reason
	
	def label; reason_was; end
	
	include DbChangeHooks
	
end