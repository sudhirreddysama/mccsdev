class PersonUpdate < ActiveRecord::Base

	belongs_to :person
	belongs_to :user

end