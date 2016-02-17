class TopText < ActiveRecord::Base

	def label; name_was; end
	
	validates_presence_of :text, :name, :path

	include DbChangeHooks

end