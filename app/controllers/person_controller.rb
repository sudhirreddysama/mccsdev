class PersonController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'people.last_name',
			:dir1 => 'asc',
			:sort2 => 'people.first_name',
			:dir2 => 'asc'
		})
		@orders = [
			['ID', 'people.id'],
			['First Name', 'people.first_name'],
			['Last Name', 'people.last_name'],
			['SSN', 'people.ssn'],
			['Town', 'towns.name'],
			['Village', 'villages.name'],
			['Fire District', 'fire_districts.name'],
			['School District', 'school_districts.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'people.id' => :left,
			'people.ssn' => :left,
			'people.ssn_raw' => :left,
			'people.first_name' => :like,
			'people.last_name' => :like,
			'towns.name' => :like,
			'villages.name' => :like,
			'school_districts.name' => :like,
			'fire_districts.name' => :like,
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:town, :village, :fire_district, :school_district]
		}
		super
	end

	def veterans
		@filter = get_filter({
			:sort1 => 'people.last_name',
			:dir1 => 'asc',
			:sort2 => 'people.first_name',
			:dir2 => 'asc'
		}, 'person_index_filter')
		@orders = [
			['ID', 'people.id'],
			['First Name', 'people.first_name'],
			['Last Name', 'people.last_name'],
			['SSN', 'people.ssn'],
			['Type', 'people.veteran'],
			['Veteran Verified?', 'people.veteran_verified'],
			['Veteran Used?', 'people.veteran_used'],
		]
		cond = get_search_conditions @filter[:search], {
			'people.id' => :left,
			'people.ssn' => :left,
			'people.ssn_raw' => :left,
			'people.first_name' => :like,
			'people.last_name' => :like,
			'people.veteran_used_exam_no' => :like,
			'people.veteran_used_title' => :like,
		}
		cond << 'people.veteran != "" and people.veteran is not null'
		types = []
		types << 'VETERAN' if @filter.type_veteran == '1'
		types << 'DISABLED VET' if @filter.type_disabled_vet == '1'
		types << 'ACTIVE DUTY' if @filter.type_active_duty == '1'
		if !types.empty?
			cond << 'people.veteran in ("' + types.join('","') + '")'
		end
		cond << 'people.veteran_verified = 1' if @filter.veteran_verified == 'verified'
		cond << 'people.veteran_verified = 0' if @filter.veteran_verified == 'unverified'
		cond << 'people.veteran_used = 1' if @filter.veteran_used == 'used'
		cond << 'people.veteran_used = 0' if @filter.veteran_used == 'unused'
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		fetch_objs
		template if !params[:export]
	end

	def edit_vet
		load_obj
		@redirect = {:action => :view_vet, :id => @obj.id, :controller => :person}
		edit
	end

	def view_vet
		load_obj
		view
	end

	def update_residency
    load_obj
    p=@obj
    a = p.residence_different ? p.residence_address : p.mailing_address
    z = p.residence_different ? p.residence_zip : p.mailing_zip
    a = a.gsub("STREET","ST");
    a = a.gsub("DRIVE","DR");
    a = a.gsub("AVENUE","AVE");
    a = a.gsub("ROAD","RD");
    a = a.gsub("LANE","LN");
    a = a.gsub("  "," ");

    a.delete! ','
    a.delete! '.'
    a.strip!
    x = Parcel.find :first, :conditions => ['address like ? and left(PAR_ZIP, 5) = ?', "%#{a}", z[0, 5]]
    if x
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

      web_school = WebSchool.find_by_gis_name x.SCH_NAME
      if web_school
        exp_school = SchoolDistrict.find_by_name web_school.pstek_name.upcase
      end
      school_id = exp_school ? exp_school.id : 0
      web_fire = WebFire.find_by_gis_name x.DISTRICT
      if web_fire
         exp_fire = FireDistrict.find_by_name web_fire.pstek_name.upcase
      end
      fire_id = exp_fire ? exp_fire.id : 0
      if p.residence_different
        county_id = p.residence_county.to_s.upcase.strip
      else
        county_id =   p.mailing_county.to_s.upcase.strip
      end

    attr = {
        :town_id => town_id,
        :village_id => village_id,
        :school_district_id => school_id,
        :fire_district_id => fire_id,
        :county_id =>  2

    }
    p.update_attributes attr
    else
      attr = {
          :town_id => 0,
          :village_id => 0,
          :school_district_id => 0,
          :fire_district_id => 0
      }
      p.update_attributes attr
    end
    redirect_to :back
  end
	def list_notes
		load_obj
		if request.post?
			@objs = params[:objs]
			@new_objs = params[:new_objs]
			if @objs
				@objs.each { |ln_id, attr|
					o = ListNote.find ln_id
					if attr[:note_date].blank? || attr[:note].blank?
						o.destroy
					else
						o.update_attributes attr
					end
				}
			end
			if @new_objs
				@new_objs.each { |app_id, attr|
					if !attr[:note_date].blank? && !attr[:note].blank?
						attr[:applicant_id] = app_id
						ListNote.create attr
					end
				}
			end
			redirect_to
			flash[:notice] = 'List notes have been saved.'
		else
			@apps = @obj.applicants.find(:all, {
				:include => [:exam, :app_status],
				:order => 'exams.established_date desc',
				:conditions => 'applicants.approved = "Y" and app_statuses.eligible != "N"'
			})
			@objs = @obj.list_notes.find(:all, {
				:include => {:applicant => [:exam, :app_status]},
				:order => 'exams.established_date desc'
			})
		end
	end
	
	BAD_SSNS = %w(999-99-9999 012-34-5678 000-00-0000 123-12-1234 123-45-6789 111-11-1111)
	
	def ssn_merge
		if request.post? && params[:objs]
			tables = %w{applicants cert_applicants documents messages taken_perfs person_updates}
			params[:objs].each { |o|
				old_id, new_id = o.split('-')
				old_a = Person.find old_id
				new_a = Person.find new_id
				if old_a.ssn = new_a.ssn
					tables.each { |t|
						DB.query("update #{t} set person_id = %d where person_id = %d", new_a.id, old_a.id)
					}
					old_a.destroy
				end
			}
			redirect_to
			flash[:notice] = 'Records have been merged.'
		else
			@objs = DB.query('
				select
				p1.ssn ssn,
				p1.id old_id, p1.first_name old_first_name, p1.last_name old_last_name,
				p2.id new_id, p2.first_name new_first_name, p2.last_name new_last_name
				from people p1
				join people p2 on p1.ssn = p2.ssn and p2.id > p1.id
				where p1.ssn not in ("' + BAD_SSNS.join('","') + '")
				order by p1.last_name asc, p1.first_name asc
			')
		end
	end
	
	#adding this to catch the "spoof" ssn's that are flushed out of the ssn_merge
	def ssn_merge_bad
		@objs = Person.find(:all, :conditions => ['ssn in (?)', BAD_SSNS], :order => 'id desc')
	end

end
