class BulkMessage < ActiveRecord::Base

	has_many :messages, :dependent => :destroy
	
	belongs_to :bulk_bulk_message
	
	belongs_to :letter
	belongs_to :exam
	belongs_to :cert
	belongs_to :web_exam
	belongs_to :user
	
	validates_presence_of :subject, :body, :public_name
	
	has_and_belongs_to_many :app_statuses
	has_and_belongs_to_many :disapprovals
	has_and_belongs_to_many :agencies
	has_and_belongs_to_many :applicants
	has_and_belongs_to_many :contacts
	
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
	
	def new_contact_ids
		@new_contact_ids ||= contact_ids
	end
	
	def new_contact_ids= v
		@new_contact_ids = v.map(&:to_i)
	end
	
	attr :save_new_app_status_ids, true
	attr :save_new_disapproval_ids, true
	attr :save_new_agency_ids, true
	attr :save_new_applicant_ids, true
	attr :save_new_contact_ids, true

	def validate
		if @save_new_applicant_ids && @new_applicant_ids.blank? && @new_contact_ids.blank?
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
		self.contact_ids = @new_contact_ids || [] if @save_new_contact_ids
		
		o = bulk_object
		cond = []
		messages.clear
		attr = {
			:letter_id => letter_id,
			:subject => subject,
			:public_name => public_name,
			:email_from => email_from,
			#:hr_letterhead => hr_letterhead,
			:letterhead => letterhead,
			:deliver_after => deliver_after,
			:user_id => user_id,
			:force_postal => force_postal
		}
		if select_via == 'contact'
			cond << 'contacts.id in (%s)' % contact_ids.join(',') unless contact_ids.empty?
			conts = Contact.find(:all, :conditions => cond.join(' and '))
			update_attribute :message_count, conts.size
			conts.each { |c|
				m = messages.create(attr + {
					:contact => c,
					:body => Letter.apply(body, {:contact => c}),
				})
			}
		else
			cond << 'applicants.id in (%s)' % applicant_ids.join(',') unless applicant_ids.empty?		
			apps = o.applicants.find(:all, :conditions => cond.join(' and '))
			update_attribute :message_count, apps.size
			apps.each { |a|
				m = messages.create(attr + {
					:applicant => a,
					:person => a.person,
					:body => Letter.apply(body, {:applicant => a, :person => a.person}),
				})
			}
		end
	end
	after_save :handle_after_save

	include DbChangeHooks
	
end