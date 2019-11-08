class Division < ActiveRecord::Base

	belongs_to :department
	
	validates_presence_of :name, :department
	
	def label; name_was; end
	
end