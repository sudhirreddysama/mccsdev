class Contact < ActiveRecord::Base

  belongs_to :agency
  belongs_to :department
  has_many :messages
  
  def label; lastname; end

	def name; "#{firstname} #{lastname}"; end
	
	validates_presence_of :firstname, :lastname
	
	include DbChangeHooks
	
	def liaison
		Agency.get_liaison agency, department
	end
	
	def full_address  j = "\n"
		addr = [organization_name.to_s.strip, address.to_s.strip, address2.to_s.strip, csz].reject(&:blank?).join(j)
		addr = [agency.name.to_s.strip, agency.full_address(j)].reject(&:blank?).join(j) if agency && addr.blank?
		return addr
	end
	
	def csz
		return '' if city.blank? && zip.blank?
		[[city.to_s.strip, state.to_s.strip].reject(&:blank?).join(', '), zip.to_s.strip].reject(&:blank?).join(' ')
	end
	
end