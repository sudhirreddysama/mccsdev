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
	
	validates_presence_of :agency, :department, :first_name, :last_name, :hire_type,
		:address, :address_city, :address_state, :address_zip, :ssn, 
		:job, :salary, :salary_per, :full_or_part_time, :hours_per_week,
		:classification, :civil_service_status, :if => :http_posted
	
	validates_inclusion_of :exempt_vol_firefighter,
		:veteran, :employed_4years, :in => [true, false], :message => 'is required', :if => :http_posted
	
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
	
	def classification_code
		{'Competitive' => 'C', 
		'Non-Competitive' => 'N', 
		'Labor' => 'L', 
		'Exempt' => 'E', 
		'Unclassified' => 'U'}[classification]			
	end
	
	def status_code
		s_code = {'Permanent' => 'P',
		'Contigent Permanent' => 'C', 
		'Provisional' => 'V', 
		'Temporary' => 'T',
		'Pending NYS Approval' => 'PN'}[civil_service_status]
		if s_code == 'T'
			s_code = 'S' if temporary_type == 'Seasonal'
			s_code = 'SU' if temporary_type == 'Sub' || temporary_type == 'Filling in for Leave of Absence'
		end
		s_code
	end
	
end