class User < ActiveRecord::Base

	has_many :documents
		
	belongs_to :agency
	belongs_to :department
	
	belongs_to :switch_user, :class_name => 'User', :foreign_key => 'switch_user_id'
	has_many :switch_users, :class_name => 'User', :foreign_key => 'switch_user_id', :conditions => 'users.level != "disabled"'
	
	validates_format_of :username, :with => /\A[a-zA-Z0-9_]{3,100}\Z/
	validates_uniqueness_of :username
	validates_presence_of :password, :on => :create
	validates_confirmation_of :password, :if => :password
	validates_length_of :password, :minimum => 4, :if => :password
	validates_presence_of :name, :email
	validates_presence_of :level
	
	has_many :liaison_web_exams, :class_name => 'WebExam', :foreign_key => 'liaison_id'
	has_many :liaison2_web_exams, :class_name => 'WebExam', :foreign_key => 'liaison2_id'
	
	def validate
		if agency_level?
			if !agency
				errors.add_to_base 'Agency is required for agency level users.'
			end
		end
		if @switch_username
			if @switch_username.blank?
				self.switch_user_id = nil
			else
				u = User.find_by_username @switch_username
				if u
					self.switch_user_id = u.id
				else
					errors.add_to_base 'Switch user not found.'
				end
			end
		end
	end
	
	def label; username_was; end
	
	SALT = '--this-is-the-salt!'
	
  def password= v
  	unless v.to_s.empty?
			self.encrypted_password = Digest::SHA1.hexdigest(v.to_s + SALT)
			@password = v
  	end
  end  
  attr_reader :password
  
  def self.authenticate u, p
  	find_by_username u, :conditions => ['encrypted_password = ? and level != "disabled"', Digest::SHA1.hexdigest(p.to_s + SALT)]
  end
      
  def email_with_name 
  	"#{name} <#{email}>"
  end
  
  def agency_level?
  	level == 'agency' || level == 'agency-head' || level == 'agency-employees'
  end
  
  def view_only?
  	level == 'view-only'
  end
  
  def staff_level?
  	level == 'staff' || level == 'admin'
  end
  
  def liaison_level?
  	level == 'liaison'
  end
  
  def admin_level?
  	level == 'admin'
  end
  
  def is_agency_county?
  	agency_level? && agency && agency.agency_type == 'COUNTY'
  end
  
  def switch_username
  	if @switch_username 
  		return @switch_username 
  	elsif switch_user
  		return switch_user.username
  	end
  end
  
  def switch_username= v
  	@switch_username = v
  end
	
	include DbChangeHooks
	
end