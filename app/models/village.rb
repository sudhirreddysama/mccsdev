class Village  < ActiveRecord::Base

	def label; name_was; end
	
	include DbChangeHooks
	
end