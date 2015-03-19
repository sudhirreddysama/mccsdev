class BulkMessage < ActiveRecord::Base

	has_many :messages, :dependent => :destroy
	
	belongs_to :letter
	belongs_to :exam
	belongs_to :cert
	belongs_to :web_exam
	belongs_to :user
	
	validates_presence_of :subject, :body
	
	has_and_belongs_to_many :app_statuses
	has_and_belongs_to_many :disapprovals
	has_and_belongs_to_many :agencies
	has_and_belongs_to_many :applicants
	
	def label; subject_was; end
	
	def bulk_object; exam || cert || web_exam; end
	
	def new_app_status_ids
		@new_app_status_ids ||= app_status_ids
	end
	
	def new_app_status_ids= v
		@new_app_status_ids = v.map(&:to_i)
	end
	
	
	
	def new_disapproval_ids
		@new_disapproval_ids ||= disapproval_ids
	end
	
	def new_disapproval_ids= v
		@new_disapproval_ids = v.map(&:to_i)
	end
	
	
	
	def new_agency_ids
		@new_agency_ids ||= agency_ids
	end
	
	def new_agency_ids= v
		@new_agency_ids = v.map(&:to_i)
	end
	
	
	def new_applicant_ids
		@new_applicant_ids ||= applicant_ids
	end
	
	def new_applicant_ids= v
		@new_applicant_ids = v.map(&:to_i)
	end
	
	attr :save_new_app_status_ids, true
	attr :save_new_disapproval_ids, true
	attr :save_new_agency_ids, true
	attr :save_new_applicant_ids, true

	def validate
		if @save_new_applicant_ids && @new_applicant_ids.blank?
			errors.add_to_base 'You must select at least one recipient.'
		end
	end

	def handle_after_save
		return if @saving
		@saving = true
		
		self.app_status_ids = @new_app_status_ids || [] if @save_new_app_status_ids
		self.disapproval_ids = @new_disapproval_ids || [] if @save_new_disapproval_ids
		self.applicant_ids = @new_applicant_ids || [] if @save_new_applicant_ids
		self.agency_ids = @new_agency_ids || [] if @save_new_agency_ids
		
		o = bulk_object
		
		cond = []
		cond << 'applicants.id in (%s)' % applicant_ids.join(',') unless applicant_ids.empty?
		
		apps = o.applicants.find(:all, :conditions => cond.join(' and '))
		update_attribute :message_count, apps.size
		messages.clear
		apps.each { |a|
			m = messages.create({
				:applicant => a,
				:person => a.person,
				:letter_id => letter_id,
				:subject => subject,
				:body => Letter.apply(body, {:applicant => a, :person => a.person}),
				:email_from => email_from,
				:hr_letterhead => hr_letterhead,
				:user_id => user_id
			})
		}
	end
	after_save :handle_after_save

	include DbChangeHooks
	
end