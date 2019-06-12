class Department < ActiveRecord::Base

	has_many :documents

	belongs_to :agency
	
	belongs_to :liaison, :class_name => 'User', :foreign_key => 'liaison_id'
	belongs_to :liaison2, :class_name => 'User', :foreign_key => 'liaison2_id'
	belongs_to :omb_liaison, :class_name => 'User', :foreign_key => 'omb_liaison_id'
	belongs_to :payroll_user, :class_name => 'User', :foreign_key => 'payroll_user_id'
	
	has_many :divisions
	has_many :contacts
	
	validates_presence_of :name
	
	def label; name_was; end

	def self.select_options old_val, county = false
		cond = '(active = 1' + (county ? ' and county = 1' : '') + ')' +
			(old_val.blank? ? '' : DB.escape(' or id = "%s"', old_val))
		opts = Department.find(:all, :order => 'name', :conditions => cond).map { |o|
			[o.name, o.id]
		}
		opts = [[old_val, old_val], *opts] if !old_val.blank? && !opts.rassoc(old_val)
		opts
	end

	include DbChangeHooks
	
end
