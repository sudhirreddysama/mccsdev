class PersonnelDivision < ActiveRecord::Base

	belongs_to :personnel_area
	
	validates_presence_of :name, :personnel_area
	
	def label; name_was; end

end