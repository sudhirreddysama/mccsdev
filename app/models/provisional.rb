class Provisional < ActiveRecord::Base

	validates_presence_of :name
	
	def label; name_was; end
	
	include DbChangeHooks
	
end