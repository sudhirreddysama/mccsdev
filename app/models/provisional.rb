class Provisional < ActiveRecord::Base

	has_many :documents

	validates_presence_of :name
	
	def label; name_was; end
	
	include DbChangeHooks
	
end