class Agency < ActiveRecord::Base

	has_many :documents

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
	
	def full_address j = "\n"
		[address1.to_s.strip, address2.to_s.strip, csz].reject(&:blank?).join(j)
	end
	
	def csz
		[[city.to_s.strip, state.to_s.strip].reject(&:blank?).join(', '), zip.to_s.strip].reject(&:blank?).join(' ')
	end
	
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
	
	def primary_contacts_string
		contacts.select(&:primary).map { |c| [c.lastname, c.firstname, c.title, c.email, c.phone, c.fax].reject(&:blank?).join(',') }.join('/')
	end
	
	def is_county?
		agency_type == 'COUNTY'
	end
	
	def get_users d = nil, div = nil, condition = nil
		# if no department, just find everyone with this agency_id who also has no department
		# if department and agency is MONROE COUNTY, only include people specifically in that department (excluding people with no department)
		# if department and agency is NOT MONROE COUNTY, include people in that department AND ALSO users with NO department
		cond = ['users.level != "disabled"']
		cond << condition if condition
		cond << (div ? 'users.division_id is null or users.division_id = %d' % div.id : 'users.division_id is null')
		if d
			if name == 'MONROE COUNTY'
				cond << 'users.department_id = %d' % d.id
			else
				cond << 'users.department_id is null or users.department_id = %d' % d.id
			end
		else
			cond << 'users.department_id is null'
		end
		u = users.find(:all, {
			:conditions => '(' + cond.join(') and (') + ')',
			:order => 'users.name'
		})
		return u
	end
	
	def has_title_run?
		@has_title_run ||= (agency_jobs.first ? true : false)
	end
	
end