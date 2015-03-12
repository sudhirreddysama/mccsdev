class ListsController < ApplicationController
	
	layout 'mc'
	
	skip_before_filter :force_ssl
	skip_before_filter :authenticate
	
	def mailtest
		Notifier.deliver_mailtest
		render :text => 'Mail Sent'
	end
	
	def errortest
		throw_errortest
	end
	
	before_filter :forbid_ssl
	
	def index
		exams = PublicExam.find(:all,
			:order => 'public_exams.title',
			:conditions => 'public_exams.established_date <= date(now()) and public_exams.valid_until >= date(now()) and (public_exams.continuous = 0 or public_exams.current_exam_id = public_exams.id)'
		)
		@past_exams = {}
		@lists = exams.group_by { |e|
			if e.continuous
				@past_exams[e.id] = e.past_exams.find(:all, 
					:conditions => 'public_exams.established_date <= date(now()) and public_exams.valid_until >= date(now()) and public_exams.current_exam_id != public_exams.id',
					:order => 'public_exams.established_date desc'
				)
			end
			e.title[0..0].upcase
		}
	end
	
	def view
		@obj = PublicExam.find(params[:id], {
			:conditions => 'public_exams.established_date <= date(now()) and public_exams.valid_until >= date(now()) and (public_exams.continuous = 0 or public_exams.current_exam_id = public_exams.id)'
		})
		
		cond = [
			'public_applicants.pos != 0',
			(@obj.continuous ? 'public_exams.current_exam_id = %d and public_exams.valid_until >= date(now())' : 'public_exams.id = %d') % @obj.id
		]
		
		if request.post? && !params[:clear]
			@filter = params[:filter] || {}
			
			if @filter[:town_ids]
				@filter[:town_ids].map!(&:to_i)
				cond << 'public_people.town_id in (%s)' % @filter[:town_ids].join(',')
			end
			
			if @filter[:village_ids]
				@filter[:village_ids].map!(&:to_i)
				cond << 'public_people.village_id in (%s)' % @filter[:village_ids].join(',')
			end
			
			if @filter[:school_district_ids]
				@filter[:school_district_ids].map!(&:to_i)
				cond << 'public_people.school_district_id in (%s)' % @filter[:school_district_ids].join(',')
			end
			
			if @filter[:fire_district_ids]
				@filter[:fire_district_ids].map!(&:to_i)
				cond << 'public_people.fire_district_id in (%s)' % @filter[:fire_district_ids].join(',')
			end
			
		end		
		logger.info 'HERE?????'
		@objs = PublicApplicant.find(:all, {
			:order => 'public_applicants.pos',
			:conditions => get_where(cond),
			:include => [:app_status, :person, :exam]
		})
	end
	
	def applicant
		@obj = PublicPerson.find(params[:id], {
			:conditions => '(app_statuses.eligible != "N" or app_statuses.code = "X") and app_statuses.code != "R" and 
				(public_applicants.perf_test_status is null or public_applicants.perf_test_status != "F") and 
				public_exams.established_date <= date(now())',
			:include => {:applicants => [:exam, :app_status]},
			:order => 'public_exams.established_date desc'
		})
	end
	
	def search
		if request.post?
			@search = params[:search]
			cond = get_search_conditions(@search, {
				'public_people.first_name' => :like,
				'public_people.last_name' => :like,
			})
			
			cond << ['(app_statuses.eligible != "N" or app_statuses.code = "X") and app_statuses.code != "R" and 
				(public_applicants.perf_test_status is null or public_applicants.perf_test_status != "F") and 
				public_exams.established_date <= date(now())']
			
			@objs = PublicPerson.find(:all, {
				:conditions => get_where(cond),
				:order => 'public_people.last_name asc, public_people.first_name asc',
				:include => {:applicants => [:exam, :app_status]}
			})
		end
	end

	def msg
		@obj = Message.find_by_id_and_download_key params[:id], (params[:k] || params[:id2])
		@obj.ensure_rendered
		send_file @obj.path, :filename => "letter.pdf", :disposition => 'inline', :type => 'application/pdf'
	end
	
end