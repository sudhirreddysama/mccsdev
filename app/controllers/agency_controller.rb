class AgencyController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'agencies.name',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'agencies.id'],
			['Name', 'agencies.name'],
			['Abbreviation', 'agencies.abbreviation'],
			['Type', 'agencies.agency_type']
		]
		cond = get_search_conditions @filter[:search], {
			'agencies.id' => :left,
			'agencies.name' => :like,
			'agencies.agency_type' => :like,
			'agencies.abbreviation' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		@export_fields = %w(id name)
		super
  end
  
  def notes
   super
  end

	def jobs
		load_obj
		if params[:id2] == 'problems'
			job_problems
			return
		end
		@agency_jobs = @obj.agency_jobs.index_by &:job_id
		@jobs = Job.find(:all, :order => 'jobs.inactive asc, jobs.name asc')
	end

	def jobs_save
		load_obj
		job_ids = params[:job_ids] || []
		job_ids.map! &:to_i
		agency_jobs = @obj.agency_jobs.index_by &:job_id
		existing_job_ids = agency_jobs.keys
		delete_ids = existing_job_ids - job_ids
		create_ids = job_ids - existing_job_ids
		delete_ids.each { |delete_id|
			agency_jobs[delete_id].destroy
		}
		create_ids.each { |create_id|
			@obj.agency_jobs.create :job_id => create_id
		}
		render_nothing
	end
	
	def job_problems
		@objs = DB.query('
			select 
				e.ssn, e.id, e.first_name, e.last_name, e.job_time, e.status, e.classification,
				a.name agency_name, d.name department_name, aj.agency_id agency_job, 
				j.name job_name, j.id job_id, j.inactive job_inactive
			from employees e
			join jobs j on j.id = e.job_id
			join agencies a on a.id = e.agency_id
			left join departments d on d.id = e.department_id
			left join agency_jobs aj on aj.job_id = j.id and aj.agency_id = a.id
			where a.id = %d and (aj.agency_id is null or j.inactive = 1)
			and (e.leave_date is null or date(e.leave_date) > date(now()))
			order by e.last_name, e.first_name
		', @obj.id)
		render :action => :job_problems
	end
	
	
	# Not used.
	def job_select
		@obj = {}
		@obj.agency = params[:id2].blank? ? nil : Agency.find(params[:id2])
		@obj.job_id = params[:job_id]
		instance_variable_set('@' + params[:id], @obj)
		render :layout => false
	end
	
	
	
end