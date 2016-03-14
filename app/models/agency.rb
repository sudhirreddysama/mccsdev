class Agency < ActiveRecord::Base

	#has_and_belongs_to_many :web_exams
	
	has_many :employees
	has_many :users
  has_many :contacts
  has_many :agency_jobs
  has_many :jobs, :through => :agency_jobs
	belongs_to :liaison, :class_name => 'User', :foreign_key => 'liaison_id'
	belongs_to :omb_liaison, :class_name => 'User', :foreign_key => 'omb_liaison_id'
	
	validates_presence_of :name
	
	def label; name_was; end

	include DbChangeHooks
	
	def self.get_liaison a, d
		if a.nil? && d
			return d.liaision
		elsif d.nil? && a
			return a.liaison
		elsif a && d
			if d.liaison && a.use_dept_liaison
				return d.liaison
			else
				return a.liaison
			end
		end
	end
	
	def self.get_omb_liaison a, d
		if a.nil? && d
			return d.omb_liaision
		elsif d.nil? && a
			return a.omb_liaison
		elsif a && d
			if d.omb_liaison && a.use_dept_liaison
				return d.omb_liaison
			else
				return a.omb_liaison
			end
		end
	end	
	
	def get_users d
		# if no department, just find everyone with this agency_id who also has no department
		# if department and agency is MONROE COUNTY, only include people specifically in that department (excluding people with no department)
		# if department and agency is NOT MONROE COUNTY, include people in that department AND ALSO users with NO department
		c = 'users.level != "disabled" and users.only_vacancy = 0 and '
		u = users.find(:all, {
			:conditions => (
				d ? 
				[c + '(' + (name != 'MONROE COUNTY' ? 
					'users.department_id is null or ' : 
					''
				) + 'users.department_id = ?)', d.id] : 
				c + 'users.department_id is null'
			),
			:order => 'users.name'
		})
		return u
	end
	
end