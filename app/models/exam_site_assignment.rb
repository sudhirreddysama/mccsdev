class ExamSiteAssignment < ActiveRecord::Base
	
	belongs_to :exam
	belongs_to :exam_site
	
	
	
	include DbChangeHooks
	
end