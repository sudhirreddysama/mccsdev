class JobController < CrudController

	def index
		@agency_options = Agency.find(:all, {
			:order => 'agencies.name', 
			:include => {:agency_jobs => :job}, 
			:conditions => 'jobs.id is not null'
		}).collect { |a| 
			[a.name, a.id]
		}
		@filter = get_filter({
			:sort1 => 'jobs.name',
			:dir1 => 'asc',
			:agency_id => @current_user.agency_level? ? @current_user.agency_id : nil
		})
		if params[:agency_id]
			@filter[:agency_id] = params[:agency_id]
		end
		@orders = [
			['ID', 'jobs.id'],
			['Active/Inactive', 'jobs.inactive'],
			['Name', 'jobs.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'jobs.id' => :left,
			'jobs.name' => :like,
		}
		include = nil
		if !@filter[:agency_id].blank?
			@filter[:agency_id] = @filter[:agency_id].to_i
			if @agency_options.rassoc(@filter[:agency_id])
				cond << 'agency_jobs.agency_id = %d' % @filter[:agency_id]
			else
				@filter[:agency_id] = nil
			end
		end
		cond << 'jobs.inactive = 0' unless @filter[:inactive] == '1'
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => :agency_jobs
		}
		@export_fields = %w(id inactive name)
		super
	end

end