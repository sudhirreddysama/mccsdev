class FormTitle  < ActiveRecord::Base
	
	belongs_to :agency
	belongs_to :department
	belongs_to :user
	belongs_to :employee

	has_many :documents
	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'	
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	def label; "#222 #{title}"; end
	
	def title
		t = final_title
		t = suggested_title if t.blank?
		t = present_title if t.blank?
		t = '(blank)' if t.blank?
		t
	end
	
	include DbChangeHooks

	def form_type; '222'; end
	
end