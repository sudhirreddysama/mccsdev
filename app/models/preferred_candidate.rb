class PreferredCandidate < ActiveRecord::Base
	
	belongs_to :preferred_list
	
	has_many :documents
	
	validates_presence_of :first_name, :last_name
	
	def label; "#{last_name_was}, #{first_name_was}"; end

	def full_address j = "\n"
		[address.strip, address2.strip, csz].reject(&:blank?).join(j)
	end	
	
	def csz
		[[city.strip, state.strip].reject(&:blank?).join(', '), zip_code.strip].reject(&:blank?).join(' ')
	end	
	
	def handle_before_save
		if tiebreaker.blank?
			self.tiebreaker = (0...8).map{ (65 + rand(26)).chr }.join
		end
	end
	
	before_save :handle_before_save
	
	include DbChangeHooks
	
end