class Notice < ActiveRecord::Base

	belongs_to :cert
	belongs_to :form_title
	
	belongs_to :user
	has_and_belongs_to_many :users
	has_many :documents
	
	def validate
		if action == 'message'
			errors.add_to_base 'Message body cannot be blank' if body.blank?
			errors.add_to_base 'No recipients specified' if recipients.blank?
		elsif action == 'disapproval'
			errors.add_to_base 'Please enter the reason for your disapproval in the message body' if body.blank?
			errors.add_to_base 'Disapprovals require at least one recipient' if recipients.blank?
		elsif action == 'approval'
		else
			errors.add_to_base 'Please specify an action (approval, disapproval, or message)'
		end
	end
	
	def recipients= v
		@recipients = v
	end
	
	def recipients
		@recipients ||= user_ids.join(',')
	end
	
	def save_recipients
		if @recipients
			self.user_ids = @recipients.split(',')
		end
	end
	
	def subject 
		"#{object_title} (#{object.id}) - #{action.titlecase}, #{object.label}"
	end
	
	def object
		cert || form_title
	end
	
	def self.approvals_for o
		approvals = []
		o.notices.find(:all, :order => 'notices.created_at desc').to_a.find { |n|
			if n.action == 'approval'
				approvals << n
			end
			n.action == 'disapproval'
		}
		return approvals
	end
	
	def object_title
		if cert 
			'Certified List'
		elsif form_title
			'222 Form'
		else
			'Form/List'
		end
	end
	
	after_save :save_recipients
	
end