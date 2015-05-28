class Job < ActiveRecord::Base
	
	has_many :documents
	has_many :certs
	has_many :exams
	has_many :preferred_lists
	has_many :agency_jobs
	has_many :agencies, :through => :agency_jobs
	
	def label; name_was; end
	
	validates_presence_of :name
	
	def title; name; end
	
	
	include DbChangeHooks
	
end