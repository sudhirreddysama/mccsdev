class Department < ActiveRecord::Base

	belongs_to :agency
	
	belongs_to :liaison, :class_name => 'User', :foreign_key => 'liaison_id'
	belongs_to :liaison2, :class_name => 'User', :foreign_key => 'liaison2_id'
	belongs_to :omb_liaison, :class_name => 'User', :foreign_key => 'omb_liaison_id'
	
	validates_presence_of :name
	
	def label; name_was; end

	include DbChangeHooks
	
end
