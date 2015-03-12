class FormHire  < ActiveRecord::Base

	belongs_to :agency
	belongs_to :department
	belongs_to :employee
	belongs_to :user
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	belongs_to :cert
	
	belongs_to :job

	has_many :documents
	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'	
	
	validates_presence_of :agency, :department, :first_name, :last_name, :hire_type
	
	def label; "#330 #{last_name_was}, #{first_name_was}"; end
	
	def form_type; '330'; end
	
	def full_address j = "\n"
		[address.strip, address2.strip, csz].reject(&:blank?).join(j)
	end	
	
	def csz
		[[address_city.strip, address_state.strip].reject(&:blank?).join(', '), address_zip.strip].reject(&:blank?).join(' ')
	end	
	
	def set_title_text
		if job
			self.title = job.name
		else
			self.title = ''
		end
	end
	before_save :set_title_text
	
	include DbChangeHooks
	
end