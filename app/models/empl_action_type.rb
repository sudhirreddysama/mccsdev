class EmplActionType < ActiveRecord::Base
	
	validates_presence_of :name
	
	def label
		name.to_s + (description.blank? ? '' : ": #{description}")
	end
	
	include DbChangeHooks
	
end