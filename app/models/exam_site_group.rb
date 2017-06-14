class ExamSiteGroup < ActiveRecord::Base
	
	validates_presence_of :name
	has_many :exam_sites
	
	def label; name_was; end
	
	def full_address j = "\n"
		[address.strip, address2.strip, address3.strip].reject(&:blank?).join(j)
	end	
	
	def full_address_inline; full_address ', '; end
	
	include DbChangeHooks
	
	def handle_before_update
		if address_changed? || address2_changed? || address3_changed?
			exam_sites.find_all_by_address_and_address2_and_address3(address_was, address2_was, address3_was).each { |s|
				s.update_attributes :address => address, :address2 => address2, :address3 => address3
			}
		end
	end
	
	before_update :handle_before_update
	
end