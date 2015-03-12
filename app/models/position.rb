class Position < ActiveRecord::Base

	belongs_to :job
	belongs_to :agency
	belongs_to :department
	belongs_to :job_class
	belongs_to :job_type
	
	has_many :empl_actions
	
	def label; job_no_was; end
	
	include DbChangeHooks
	
end