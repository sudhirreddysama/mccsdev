class PersonnelArea < ActiveRecord::Base

	has_many :personnel_divisions
	
	validates_presence_of :name, :no
	
	def label; no_was; end
	
end