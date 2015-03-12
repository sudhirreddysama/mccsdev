class Job < ActiveRecord::Base
	
	has_many :documents
	has_many :certs
	has_many :exams
	
	has_many :preferred_lists
	
	def label; name_was; end
	
	validates_presence_of :name
	
	def title; name; end
	
	
	include DbChangeHooks
	
end