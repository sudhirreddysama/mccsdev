class FormTitle  < ActiveRecord::Base
	
	belongs_to :agency
	belongs_to :department
	belongs_to :user
	belongs_to :employee

	has_many :documents
	has_many :empl_actions
	
	belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_id'	
	belongs_to :status_user, :class_name => 'User', :foreign_key => 'status_user_id'
	
	has_many :notices
	
	attr :status_notify, true
	
	def validate
		if !http_posted
			return
		end
		err 'Agency is required' if agency.blank?
		err 'Department is required' if department.blank?
		if agency
			if agency.agency_type == 'COUNTY'
				err 'Cost center no. is required' if cost_center.blank?
				err 'SAP org no. is required' if sap_number.blank?
				err 'For funding select grant funding or non-grant funding' if !['Grant Funded', 'Non-Grant Funded'].include?(grant_funded)
			else
				err 'Division, unit or section is required' if division_unit_section.blank?
			end
		end
		err 'Select request to classify or reclassify and enter number of positions' if !['Classify', 'Reclassify'].include?(classify_reclassify) || number_positions.blank?
		err 'Present position title, incumbent, and salary level are required if reclassifying a position' if classify_reclassify == 'Reclassify' && (present_title.blank? || present_incumbent.blank? || present_salary_level.blank?)
		err 'Suggested title is required' if suggested_title.blank?
		err 'Salary group and range is required' if suggested_salary_group_range.blank?
		err 'Job duties brief summary is required' if brief_summary.blank?
		err 'At least one percentage and paragraph is required for description of duties (enter both values for first row)' if duties_percent1.blank? || duties_description1.blank?
		err 'At least one supervisor is required (enter all fields in first row)' if supervisor_name1.blank? || supervisor_title1.blank? || supervisor_type1.blank? || supervisor_email1.blank? || supervisor_phone1.blank?
		err 'At least one supervisee is required (enter all fields in first row)' if supervisee_name1.blank? || supervisee_title1.blank? || supervisee_type1.blank?
		err 'At least one similar position is required (enter all fields in first row)' if similar_name1.blank? || similar_title1.blank? || similar_location1.blank?
		err 'Suggested minimum education is required' if min_hs.blank? && min_college.blank? && min_other.blank?
		err 'Specialization is required for minimum college education' if !min_college.blank? && min_college_specialization.blank?
		err 'Specialization is required for minimum other education' if !min_other.blank? && min_other_specialization.blank?
		err 'Suggested experience is required' if experience.blank?
		err 'Essential knowledge, skills and abilities is required' if essential_skills.blank?
		err 'Check YES or NO for drug testing' if drug_testing.nil?
		err 'The checkbox indicating this form is accurate and complete must be checked' if !accurate_and_complete
	end
	
	def err s
		errors.add_to_base s
	end	
	
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