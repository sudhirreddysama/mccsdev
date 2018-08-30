class Job < ActiveRecord::Base
	
	has_many :documents
	has_many :certs
	has_many :exams
	has_many :preferred_lists
	has_many :agency_jobs
	has_many :agencies, :through => :agency_jobs
	has_many :employees
	
	def label; name_was; end
	
	validates_presence_of :name
	
	def title; name; end
	
	
	include DbChangeHooks
	
	def open_certs
		certs.find(:all, :conditions => 'completed_date is null', :order => 'certs.id desc')
	end
	
end