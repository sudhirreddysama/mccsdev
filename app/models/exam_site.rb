class ExamSite < ActiveRecord::Base
	
	validates_presence_of :name
	has_many :applicants
	belongs_to :exam_site_group
	
	def label; name_was; end
	
	def full_address j = "\n"
		[address.strip, address2.strip, address3.strip].reject(&:blank?).join(j)
	end	
	
	def full_address_inline; full_address ', '; end
	
	include DbChangeHooks
	
end