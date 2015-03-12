class PreferredList < ActiveRecord::Base

	belongs_to :job
	belongs_to :agency
	belongs_to :department
	
	has_many :preferred_candidates
	
	def label; "#{established_date.d0?} #{title}"; end
	
	validates_presence_of :title, :job
	
	validates_presence_of :agency, :department, :if => Proc.new { |pl| pl.list_type != 'military' }
	
	def grey_on_master?
		return (!valid_until or valid_until < Time.now.to_date)
	end
	
	include DbChangeHooks
	
end