class WebApplicant < ActiveRecord::Base
	
	set_table_name "#{HRAPPLYDB}.applicants"
	
	belongs_to :web_user, :foreign_key => 'user_id'
	
	has_many :web_exam_prices, :foreign_key => 'applicant_id'
	has_many :web_attachments, :foreign_key => 'applicant_id'
	has_many :web_certifications, :foreign_key => 'applicant_id'
	has_many :web_educations, :foreign_key => 'applicant_id'
	has_many :web_employments, :foreign_key => 'applicant_id'
	has_many :web_other_exams, :foreign_key => 'applicant_id'
	has_many :web_trainings, :foreign_key => 'applicant_id'

	EDUCATION_LEVELS = 
		[['Less than high school graduation', 'lths'],
		['G.E.D. (general equivalency diploma)', 'ged'],
		['High school diploma', 'hsd'],
		['2-year college (no degree)', '2yc'], 
		['Associate\'s degree', 'assoc'],
		['4-year college (no degree)', '4yc'],
		['Bachelor\'s degree', 'bach'],
		['Graduate study beyond Bachelor\'s', 'bgrad'],
		['Master\'s degree', 'master'],
		['Graduate study beyond Master\'s', 'mgrad'],
		['Doctorate', 'doc']]
	
	def self.web_import
		apps = WebApplicant.find(:all, {
			:conditions => 'exported_mccs = 0 and submit_complete = 1 and submitted_at > "2013-01-04 12:00:00"'
		})
		apps.each { |wa|
			
			p = Person.find(:first, :conditions => [
				'ssn = ? and ((first_name like ? and last_name = ?) or (first_name like ? and last_name = ?))',
				wa.ssn.to_s.strip, 
				"#{wa.first_name.to_s.upcase.strip}%", 
				wa.last_name.to_s.upcase.strip, 
				"#{wa.previous_first_name.to_s.upcase.strip}%", 
				wa.previous_last_name.to_s.upcase.strip
			])
			
			first_name = wa.first_name.to_s.upcase.strip
			
			unless wa.middle_name.blank?
				first_name += ' ' + wa.middle_name.to_s.upcase.strip[0..0] + '.'
			end
      a = wa.residence_different ? wa.res_address : wa.address
      z = wa.residence_different ? wa.res_zip : wa.zip
      a = a.gsub("STREET","ST");
      a = a.gsub("DRIVE","DR");
      a = a.gsub("AVENUE","AVE");
      a = a.gsub("ROAD","RD");
      a = a.gsub("LANE","LN");
      a = a.gsub("  "," ");

      a.delete! ','
      a.delete! '.'
      a.strip!
      x = Parcel.find :first, :conditions => ['address like ? and left(PAR_ZIP, 5) = ?',"%#{a}", z[0, 5]]
      if x
        if wa.fire
        exp_fire = FireDistrict.find_by_name wa.fire.upcase
        if !exp_fire
          logger.warn "no fire district for #{wa.fire.upcase}"
        end
        end
        if wa.school
        exp_school = SchoolDistrict.find_by_name wa.school.upcase
        if !exp_school
          logger.warn "no school district for #{wa.school.upcase}"
        end
        end
        web_swis = WebSwis.find_by_swis_code x.SWIS
        logger.warn "SWIS=#{x.SWIS}"
        if web_swis
          exp_town = Town.find_by_name web_swis.pstek_town_name.upcase
        end
        town_id = exp_town ? exp_town.id : 0
        if web_swis
          exp_village = Village.find_by_name web_swis.pstek_village_name.upcase
          logger.warn "Village=#{web_swis.pstek_village_name.upcase}"
        end
        village_id = exp_village ? exp_village.id : 0

      end
      if x
        fire_id = exp_fire ? exp_fire.id : 0
        school_id = exp_school ? exp_school.id : 0
        village_id = exp_village ? village_id : 0
        town_id = exp_town ? exp_town.id : 0
      else
        fire_id = exp_fire ? exp_fire.id : 0
        school_id = exp_school ? exp_school.id : 0
        village_id = exp_village ? exp_village.id : 0
        town_id = exp_town ? exp_town.id : 0
      end
      if wa.residence_different
        county_id = wa.res_county.to_s.upcase.strip
      else
        county_id =   wa.county.to_s.upcase.strip
      end

			attr = {
				:first_name => first_name,
				:last_name => wa.last_name.to_s.upcase.strip,
				:ssn => wa.ssn.to_s.upcase.strip,
				:home_phone => wa.home_phone.to_s.upcase.strip,
				:work_phone => wa.work_phone.to_s.upcase.strip,
				:email => wa.web_user.email.to_s.upcase.strip,
				:mailing_address => wa.address.to_s.upcase.strip,
				:mailing_address2 => wa.address2.to_s.upcase.strip,
				:mailing_city => wa.city.to_s.upcase.strip,
				:mailing_state => wa.state.to_s.upcase.strip,
				:mailing_zip => wa.zip.to_s.upcase.strip,
				:mailing_county => wa.county.to_s.upcase.strip,
				:residence_different => wa.residence_different,
				:residence_address => wa.res_address.to_s.upcase.strip,
				:residence_city => wa.res_city.to_s.upcase.strip,
				:residence_state => wa.res_state.to_s.upcase.strip,
				:residence_zip => wa.res_zip.to_s.upcase.strip,
				:residence_county => wa.res_county.to_s.upcase.strip,
				:date_of_birth => wa.dob,
				:race => wa.race.to_s,
				:contact_via => wa.contact_via,
        :fire_district_id => fire_id,
        :school_district_id => school_id,
        :village_id => village_id,
        :town_id => town_id,
        :county_id => county_id=="MONROE" ? 2 : 7
    	}
    	
    	unless wa.gender.blank?
    		attr[:gender] = wa.gender.to_s.upcase.strip
    	end

      if p
				p.update_attributes attr
			else
				p = Person.create(attr)
			end
			
			cross_filing = false
			cross_filing_at = ''
			wa.web_other_exams.each { |oe|
				if !oe.no.blank? or !oe.name.blank?
					cross_filing = true
				end
			}
			
			if cross_filing
				cross_filing_at = wa.other_exams_admin
				if cross_filing_at == 'other'
					cross_filing_at = wa.other_exams_admin_other
				end
			end
			
			wa.web_exam_prices.each { |wep|
				we = wep.web_exam
				if we
					e = Exam.find_by_exam_no we.no unless we.no.blank?
					
					paid_by = 'R'
					if we.price.to_f == 0
						paid_by = 'X'
					elsif wa.waiver_requested && wa.waiver_county
						paid_by = 'E'
					elsif wa.waiver_requested
						paid_by = 'W'
					end
					
					a = Applicant.create({
						:person_id => p.id,
						:exam_id => e ? e.id : nil,
						:web_applicant_id => wa.id,
						:submitted_at => wa.submitted_at,
						:paid_by => paid_by,
						:web_exam_id => we.id,
						:loans_outstanding => wa.loans_outstanding ? true : false,
						:loans_default => wa.loans_default ? true : false,
						:cross_filing => cross_filing,
						:cross_filing_at => cross_filing_at.to_s.upcase.strip,
						:army_served => wa.army_served,
						:army_enlisted => wa.army_enlisted,
						:army_from => wa.army_from,
						:army_to => wa.army_to,
						:army_discharge_honorable => wa.army_discharge_honorable,
						:army_discharge_reason => wa.army_discharge_reason,
						:vc_type => wa.vc_type,
						:vc_used => wa.vc_used,
						:vc_used_agency => wa.vc_used_agency,
						:vc_disabled_claim_no => wa.vc_disabled_claim_no,
						:vc_disabled_auth_date => wa.vc_disabled_auth_date						
					})
				end
			}
			wa.update_attribute :exported_mccs, true
		}	
	end
	
	def label; "#{last_name}, #{first_name}"; end

  def name
    "#{first_name} #{last_name}"
  end
  
  def nonseasonal_fields?
    seasonal? == 'mixed' || seasonal? == 'no'
  end
  
  def minimum_age
    web_exam_prices.collect { |e| e.web_exam.minimum_age }.reject(&:blank?).max
  end
  
  def require_graduation_date
		web_exam_prices.to_a.find { |ep| ep.web_exam.require_degree }  
  end

end