class Person < ActiveRecord::Base

	has_many :documents

	belongs_to :school_district
	belongs_to :county
	belongs_to :village
	belongs_to :town
	belongs_to :fire_district
	
	belongs_to :personnel_area
	belongs_to :personnel_division
	
	has_many :applicants
	has_many :app_infos
	has_many :taken_perfs
	has_many :cert_applicants
	has_many :messages
	
	has_many :person_updates, :order => 'person_updates.created_at desc'
	
	has_many :list_notes, :through => :applicants
	
	validates_presence_of :ssn, :first_name, :last_name
	
	validates_format_of :ssn, :with => /\d\d\d-\d\d-\d\d\d\d/
	
	def validate
		if http_posted
			if email.blank? && (contact_via == 'email' || contact_via == 'both')
				errors.add_to_base 'Contact preference includes email but no email is specified.'
			end
		end
	end
	
	def label; "#{last_name_was}, #{first_name_was}"; end
	
	def full_name; "#{first_name} #{last_name}"; end
	
	def email_with_name; "#{full_name} <#{email}>"; end
	
	def ssn_last4; ssn.to_s[7..10]; end
	
	def full_mailing_address j = "\n"
		[mailing_address.to_s.strip, mailing_address2.to_s.strip, mailing_csz].reject(&:blank?).join(j)
	end	
	
	def full_mailing_address_inline; full_mailing_address ', '; end
	
	def mailing_csz
		[[mailing_city.to_s.strip, mailing_state.to_s.strip].reject(&:blank?).join(', '), mailing_zip.to_s.strip].reject(&:blank?).join(' ')
	end		
	
	def full_residence_address j = "\n"
		#return full_mailing_address(j) if !residence_different
		[residence_address.to_s.strip, residence_csz].reject(&:blank?).join(j)
	end	
	
	def full_residence_address_inline		
		#return full_mailing_address_inline if !residence_different
		full_residence_address ', '
	end
	
	def residence_csz
		#return mailing_csz if !residence_different
		[[residence_city.to_s.strip, residence_state.to_s.strip].reject(&:blank?).join(', '), residence_zip.to_s.strip].reject(&:blank?).join(' ')
	end
	
	def set_ssn_raw
		self.ssn_raw = ssn.to_s.gsub('-', '')
	end
	before_save :set_ssn_raw	
	
	def create_person_update
		changes = []
		if first_name_changed? || last_name_changed?
			changes << "Name changed from #{last_name_was}, #{first_name_was} to #{last_name}, #{first_name}. "
		end
		if ssn_changed?
			changes << "SSN changed from #{ssn_was} to #{ssn}. "
		end
		if mailing_address_changed? || mailing_address2_changed? || mailing_city_changed? || mailing_state_changed? || mailing_zip_changed?
			mailing_was = [mailing_address_was, mailing_address2_was, mailing_city_was, mailing_state_was, mailing_zip_was].reject(&:blank?).join(', ')
			mailing_was = 'BLANK'if mailing_was.blank? or mailing_was == 'NY'
			mailing_is = full_mailing_address(', ')
			mailing_is = 'BLANK' if mailing_is.blank? or mailing_is == 'NY'
			changes << "Mailing address changed from #{mailing_was} to #{mailing_is}. "
		end
		if residence_address_changed? || residence_city_changed? || residence_state_changed? || residence_zip_changed?
			residence_was = [residence_address_was, residence_city_was, residence_state_was, residence_zip_was].reject(&:blank?).join(', ')
			residence_was = 'BLANK' if residence_was.blank? or residence_was == 'NY'
			residence_is = full_residence_address(', ')
			residence_is = 'BLANK' if residence_is.blank? or residence_is == 'NY'
			changes << "Residence address changed from #{residence_was} to #{residence_is}. "
		end
		unless changes.empty?
			au = person_updates.create({
				:user_id => Thread.current[:user_id],
				:text => changes.join(' ')
			})
		end
	end
	before_update :create_person_update
	
	def create_first_person_update
		mailing_is = full_mailing_address(', ')
		mailing_is = 'BLANK' if mailing_is.blank? or mailing_is == 'NY'		
		residence_is = full_residence_address(', ')
		residence_is = 'BLANK' if residence_is.blank? or residence_is == 'NY'		
		au = person_updates.create({
			:user_id => Thread.current[:user_id],
			:text => "Record created with SSN: #{ssn}, name: #{last_name}, #{first_name}, Mailing Address: #{mailing_is}, Residence Address: #{residence_is}"
		})
	end
	after_create :create_first_person_update
	
	def handle_before_destroy
		if !applicants.empty?
			errors.add_to_base 'Cannot delete person record. Applications are associated with this person.'
			return false
		end
		return true
	end
	
	before_destroy :handle_before_destroy
	

	def fix_residence_address
		if !residence_different
			self.residence_address = ''
			self.residence_city = ''
			self.residence_state = ''
			self.residence_zip = ''
			self.residence_county = ''
		end
	end
	before_save :fix_residence_address
	
	def ensure_formatta_id
		chars = 'bcdfghjkmnpqrstvwxz23456789'
		if formatta_id.blank?
			begin
				self.formatta_id = Array.new(9) { chars[rand(chars.length), 1] }.join()
			end while Person.find_by_formatta_id formatta_id
		end
	end
	before_save :ensure_formatta_id
	
	def set_personnel_fields
		if personnel_area_id_changed?
			self.personnel_area_no = personnel_area ? personnel_area.no : ''
			self.personnel_area_name = personnel_area ? personnel_area.name : ''
		end
		if personnel_division_id_changed?
			self.personnel_division_name = personnel_division ? personnel_division.name : ''
		end
	end
	before_save :set_personnel_fields
	
	include DbChangeHooks
	
end