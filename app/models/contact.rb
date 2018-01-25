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
		# department address?
		agency ? agency.full_address : ''
	end
	
end