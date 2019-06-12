class User < ActiveRecord::Base

	has_many :documents
		
	belongs_to :agency
	belongs_to :department
	belongs_to :division
	
	belongs_to :switch_user, :class_name => 'User', :foreign_key => 'switch_user_id'
	has_many :switch_users, :class_name => 'User', :foreign_key => 'switch_user_id', :conditions => 'users.level != "disabled"'

	validates_format_of :password, :with => /\A(?=.*?[A-Z])(?=.*?[a-z])(?=.*?\d)(?=.*[^A-Za-z0-9]).{8,}\z/, :allow_blank => true, :message => 'min: 8 characters, must contain 1 of each: uppercase, lowercase, number, special character (#%$@*...)'

	validates_format_of :username, :with => /\A[a-zA-Z0-9_]{3,100}\Z/
	validates_uniqueness_of :username
	validates_presence_of :password, :if => Proc.new { |u| u.new_record? || u.resetting_password }
	validates_confirmation_of :password, :if => :password
	validates_presence_of :name, :email
	validates_presence_of :level
	
	has_many :liaison_web_exams, :class_name => 'WebExam', :foreign_key => 'liaison_id'
	has_many :liaison2_web_exams, :class_name => 'WebExam', :foreign_key => 'liaison2_id'
	
	def validate
  	if !new_record? && !@password.blank?
  		if previous_encrypted_passwords.include?(encrypted_password)
	  		errors.add_to_base 'Password has been used in the past. Please enter a new password.'
	  	end
  	end	
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
  
  def previous_encrypted_passwords
  	db_changes.map { |c| JSON.parse(c.changes_json)['encrypted_password'] }.compact.map(&:last).uniq
  end
  
  # User levels that can login. Note "disabled" is missing.
  USER_LEVELS = %w{agency agency-head agency-employees view-only staff admin}
  
  def self.authenticate n, p
  	return nil if n.blank? || p.blank?
  	u = find_by_username n
  	return nil if !u
  	bad = u.encrypted_password != Digest::SHA1.hexdigest(p.to_s + SALT)
  	bad ||= !USER_LEVELS.include?(u.level)
  	bad ||= u.failed_logins.to_i > 5
  	if bad
  		u.update_attribute :failed_logins, u.failed_logins.to_i + 1
  		return nil
  	end
  	u.update_attributes :activation_key => '', :failed_logins => 0, :failed_recoveries => 0
  	return u
  end
  
  def self.authenticate_by_activation_key uid, k
  	return nil if uid.blank? || k.blank?
  	u = find_by_id uid
  	return nil if !u
  	bad = u.activation_key.blank?
  	bad = u.activation_key != k
  	bad ||= !USER_LEVELS.include?(u.level)
  	bad ||= u.failed_recoveries.to_i > 5
  	if bad
  		u.update_attribute :failed_recoveries, u.failed_recoveries.to_i + 1
  		return nil
  	end
		u.update_attributes :activation_key => '', :failed_logins => 0, :failed_recoveries => 0
		return u
  end
  
  def create_activation_key
  	begin
  		self.activation_key = Array.new(10) { rand(9).to_s }.join
  	end while User.find_by_activation_key activation_key
  	save
  end
  
  attr :resetting_password, true
  attr :reset_failed_logins, true
  def reset_failed_logins= v; @reset_failed_logins = !!(v && v != 0 && v != '0'); end
  
  def handle_before_save
  	if reset_failed_logins
  		self.failed_logins = 0
  		self.failed_recoveries = 0
  	end
  	self.password_set_at = Time.now if @password
  	self.reset_password = false if resetting_password
  	return true
  end
  before_save :handle_before_save
      
  def email_with_name 
  	"#{name} <#{email}>"
  end
  
  def agency_level?
  	level == 'agency' || level == 'agency-head' || level == 'agency-employees'
  end
  
  def above_agency_level?
  	level == 'view-only' || level == 'staff' || level == 'admin'
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
  
  def has_title_run?
  	agency_level? && agency && agency.has_title_run?
  end
	
	include DbChangeHooks
	
	# One time queries.
	def self.setup_new_permissions
		DB.query('update users set perm_formatta_email = allow_applicants')
		DB.query('update users u left join agencies a on a.id = u.agency_id set
			u.perm_ag_employees = a.agency_type != "COUNTY" and u.only_vacancy = 0,
			u.perm_ag_pay_certs = a.agency_type != "COUNTY" and u.only_vacancy = 0,
			u.perm_ag_form_changes = u.only_vacancy = 0,
			u.perm_ag_form_hires = u.only_vacancy = 0,
			u.perm_ag_form_titles = u.only_vacancy = 0,
			u.perm_ag_web_posts = u.only_vacancy = 0,
			u.perm_ag_reports = u.only_vacancy = 0,
			u.perm_ag_applicants = u.allow_applicants,
			u.perm_ag_vacancies = 1
			where u.level like "agency%"'
		)
	end
	
end