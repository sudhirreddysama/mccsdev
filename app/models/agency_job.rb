class AgencyJob < ActiveRecord::Base

	belongs_to :agency
	belongs_to :job

end