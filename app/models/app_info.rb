class AppInfo < ActiveRecord::Base

	belongs_to :app_info_type
	belongs_to :person
	
	include DbChangeHooks
	
end