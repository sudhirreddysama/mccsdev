class SwisCode < ActiveRecord::Base
	
	belongs_to :village
	belongs_to :town
	
end