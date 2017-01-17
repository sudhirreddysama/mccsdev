class Vacancy < ActiveRecord::Base

	def label; "#{cost_center} #{position}"; end
	
	belongs_to :agency
	belongs_to :department
	belongs_to :user
	belongs_to :submitted_by, :class_name => 'User', :foreign_key => 'submitter_id'
	has_many :documents
	
	OMB_CODES = [
		['Approved - Funding Available', 'A1'],
		['Approved - Grant Position', 'A2'],
		['Approved w/Note', 'A3'],
		['Disapproved - Funding Low or Negative', 'D1'],
		['Disapproved w/Note', 'D2'],
		['Hold', 'H']
	]
	
	FILLED_FROM_OPTIONS = ['Within County', 'Outside County']
	JOB_TYPES = ['Full Time', 'Part Time', 'Seasonal/Temporary']
	
	def validate
		#errors.add :received_date, '^Received date is required' if received_date.blank?
		errors.add :agency, '^Agency is required' if !agency
		errors.add :organization, '^Department/Division is required' if organization.blank?
		errors.add :org_no, '^Org # is required' if org_no.blank?
		errors.add :cost_center, '^Cost center is required' if cost_center.blank?
		errors.add :position, '^Position is required' if position.blank?
		errors.add :position_no, '^Position # is required' if position_no.blank?
		errors.add :salary_group, '^Salary group is required' if salary_group.blank?
		errors.add :job_type, '^Job type is required' if job_type.blank?
		errors.add :work_covered, '^How work covered is required' if work_covered.blank?
		errors.add :justification, '^Justification is required' if justification.blank?
		errors.add :from_position, '^Filled from position is required if filled from within county' if from_position.blank? && filled_from == 'Within County'
		if !hr_candidate_hired.blank? || !hr_approval_used.blank?
			errors.add :hr_candidated_hired, '^Candidate hired is required if approval used date is entered' if hr_candidate_hired.blank?
			errors.add :hr_approval_used, '^Approval used date is required if candidate hired is entered' if hr_approval_used.blank?
			errors.add :hr_candidate_hired, '^Filled position information can only be entered for requested with an Approved status' if !(%w(Approved Expired Filled).include?(exec_decision))
		end		
		if !hr_decision.blank?
			errors.add :hr_date, '^HR decision date is required' if hr_date.blank?
			errors.add :hr_comments, '^HR comments are required if disapproved' if hr_comments.blank? && hr_decision == 'Disapproved'
		end
		if !omb_code.blank?
			errors.add :omb_date, '^OMB decision date is required' if omb_date.blank?
			errors.add :omb_comments, '^OMB comments are required for selected decision' if omb_comments.blank? && (omb_code == 'A3' || omb_code == 'D2')
			errors.add :omb_grant_percent, '^OMB grant % funded is required for selected decision' if omb_grant_percent.blank? && omb_code == 'A2'
		end
		if %w(Approved Disapproved Filled Expired).include?(exec_decision)
			errors.add :exec_approval_no, '^Exec. approval # is required' if exec_approval_no.blank? && %w(Approved Filled Expired).include?(exec_decision)
			errors.add :exec_comments, '^Exec. comments are required if disapproved' if exec_comments.blank? && exec_decision == 'Disapproved'
			errors.add :exec_date, '^Exec. decision date is required' if exec_date.blank?
		end
		if !exec_approval_no.blank?		
			if Vacancy.find(:first, :conditions => ['exec_approval_no = ? and id != ifnull(?, 0)', exec_approval_no, id])
				errors.add :exec_approval_no, '^Exec. approval # has already been used'
			end
		end
	end
	

	def self.expire_vacancy_requests
		DB.query('update vacancies set exec_decision = "Expired" where exec_decision = "Approved" and exec_date + interval 1 year < date(now())')
	end
	
	def handle_before_save
		self.omb_decision = {'H' => 'Hold', 'A' => 'Approved', 'D' => 'Disapproved'}[omb_code.to_s[0, 1]].to_s
		if !hr_candidate_hired.blank? && hr_approval_used && %w(Approved Expired).include?(exec_decision)
			self.exec_decision = 'Filled'
		elsif exec_decision == 'Filled' && hr_candidate_hired.blank?
			self.exec_decision = 'Approved'
		end
		if exec_date && exec_date.advance(:years => 1) < Time.now.to_date
			if exec_decision == 'Approved'
				self.exec_decision = 'Expired'
			end
		else
			if exec_decision == 'Expired'
				self.exec_decision = 'Approved'
			end
		end
	end
	before_save :handle_before_save
	
	def handle_after_update
		if exec_decision_changed?
			u = Agency.get_liaison(agency, department)
			u2 = Agency.get_omb_liaison(agency, department)
			u3 = agency.get_users(department, true, ['users.vacancy_emails = 1']).to_a
			if exec_decision == 'Submitted' && exec_decision_was == 'Started'
				if user && (u || u2)
					Notifier.deliver_vacancy_submitted(([u, u2] + u3).reject(&:nil?), self)
				end
			elsif %w(Started Submitted Approved Disapproved).include?(exec_decision_was) && %w(Approved Disapproved).include?(exec_decision)
				users = ([user, submitted_by, u, u2] + u3).reject(&:nil?).uniq
				if !users.empty?
					Notifier.deliver_vacancy_updated users, self			
				end
			end
		end
	end
	after_update :handle_after_update
	
	def self.next_exec_approval_no yr, id = nil
		no = DB.query('select lpad(ifnull(max(substr(exec_approval_no, 4) + 0), 0) + 1, 3, "0") no from vacancies where substr(exec_approval_no, 1, 2) = "%s" and id != %d', yr, id).fetch_hash.no
		return "#{yr}-#{no}"
	end

	include DbChangeHooks
	
end