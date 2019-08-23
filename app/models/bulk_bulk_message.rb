class BulkBulkMessage < ActiveRecord::Base

	has_many :bulk_messages, :dependent => :destroy
	
	def exam_ids; []; end
	def exam_site_ids; []; end
	
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
		
	
end