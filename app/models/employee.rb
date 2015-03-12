class Employee < ActiveRecord::Base

	has_many :documents

	belongs_to :job
	belongs_to :department
	belongs_to :agency
	
	belongs_to :form_change
	belongs_to :form_hire
	
	belongs_to :last_action, :class_name => 'EmplAction', :foreign_key => :last_action_id
	belongs_to :first_action, :class_name => 'EmplAction', :foreign_key => :first_action_id
	
	has_many :empl_actions
	
	validates_presence_of :first_name, :last_name
	validates_format_of :ssn, :with => /\d\d\d-\d\d-\d\d\d\d/
	
	def label; "#{last_name_was}, #{first_name_was}"; end
	
	def full_address j = "\n"
		[address.to_s.strip, address2.to_s.strip, csz].reject(&:blank?).join(j)
	end	
	
	def csz
		[[city.to_s.strip, state.to_s.strip].reject(&:blank?).join(', '), zip.to_s.strip].reject(&:blank?).join(' ')
	end	
	
	def set_first_last_action
		self.last_action = empl_actions.find(:first, {
			:include => :empl_action_type, 
			:order => 'empl_actions.action_date desc, empl_action_types.absent desc, empl_actions.id desc'
		})
		self.first_action = empl_actions.find :first, :order => 'empl_actions.action_date asc'
		set_first_last_action_properties
	end
	
	def set_first_last_action_properties
		if last_action
			self.leave_date = last_action.leave_date
			self.agency_id = last_action.agency_id
			self.agency_name = agency.name if agency
			self.department_id = last_action.department_id
			self.department_name = department.name if department
			self.job_id = last_action.job_id
			self.job_name = job.name if job
			self.wage = last_action.wage
			self.wage_per = last_action.wage_per
			self.job_time = last_action.job_time
			self.status = last_action.status
			self.classification = last_action.classification
		end
		if first_action
			self.date_hired = first_action.action_date
		end	
		save
	end
	
	def set_ssn_raw
		self.ssn_raw = ssn.to_s.gsub('-', '')
	end
	before_save :set_ssn_raw
	
	def new_empl_action
		@new_empl_action ||= EmplAction.new({
			:empl_action_type_id => 30, 
			:reference_date => Time.now.to_date
		})
	end
	
	def new_empl_action= v
		new_empl_action.attributes = v
	end
	
	def check_new_empl_action
		if @new_empl_action
			@new_empl_action.employee_id = id
			@new_empl_action.save
		end
	end
	after_save :check_new_empl_action
	
	def validate
		if @new_empl_action
			@new_empl_action.valid?
			@new_empl_action.errors.full_messages.each { |e|
				errors.add_to_base e
			}
		end
	end
	

	
	include DbChangeHooks
	
end