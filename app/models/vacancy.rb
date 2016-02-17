class Vacancy < ActiveRecord::Base

	def label; "#{cost_center} #{position}"; end
	
	belongs_to :agency
	belongs_to :department
	belongs_to :user
	has_many :documents
	
	OMB_CODES = {
		'A1' => 'Funding Available',
		'A2' => 'Grant Position',
		'A3' => 'Approved w/ Note',
		'D1' => 'Funding Low or Negative',
		'D2' => 'Disapproved w/ Note',
		'H' => 'Hold'
	}
	
	FILLED_FROM_OPTIONS = ['Within County', 'Outside County']
	JOB_TYPES = ['Full Time', 'Part Time', 'Seasonal/Temporary']
	
	def validate
		self.omb_decision = {'H' => 'Hold', 'A' => 'Approved', 'D' => 'Disapproved'}[omb_code.to_s[0, 1]].to_s
		errors.add :received_date, '^Received date is required' if received_date.blank?
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
		if !hr_decision.blank? && hr_decision_changed?
			errors.add :hr_date, '^HR decision date is required' if hr_date.blank?
			errors.add :hr_comments, '^HR comments are required if disapproved' if hr_comments.blank? && hr_decision == 'Disapproved'
		end
		if !omb_decision.blank? && omb_decision_changed?
			errors.add :omb_date, '^OMB decision date is required' if omb_date.blank?
			errors.add :omb_comments, '^OMB comments are required for selected decision' if omb_comments.blank? && (omb_code == 'A3' || omb_code == 'D2')
			errors.add :omb_grant_percent, '^OMB grant % funded is required for selected decision' if omb_grant_percent.blank? && omb_code == 'A2'
		end
		if !exec_decision.blank? && exec_decision_changed?
			errors.add :exec_date, '^Exec. decision date is required' if exec_date.blank?
			errors.add :exec_comments, '^Exec. comments are required if disapproved' if exec_comments.blank? && exec_decision == 'Disapproved'
			errors.add :exec_approval_no, '^Exec. approval # is required' if exec_approval_no.blank? && exec_decision == 'Approved'
		end
		if !exec_approval_no.blank?		
			if Vacancy.find(:first, :conditions => ['exec_approval_no = ? and id != ifnull(?, 0)', exec_approval_no, id])
				errors.add :exec_approval_no, '^Exec. approval # has already been used'
			end
		end
	end
	
	def handle_after_create
		u = Agency.get_liaison(agency, department)
		if user && u
			Notifier.deliver_vacancy_submitted [u], self
		end
	end
	after_create :handle_after_create
	
	def handle_after_update
		if user && (hr_decision_changed? || omb_decision_changed? || exec_decision_changed?)
			Notifier.deliver_vacancy_updated [user], self
		end
	end
	after_update :handle_after_update
	
end