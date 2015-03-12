class JobController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'jobs.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'jobs.id'],
			['Active/Inactive', 'jobs.inactive'],
			['Name', 'jobs.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'jobs.id' => :left,
			'jobs.name' => :like,
		}
		
		cond << 'jobs.inactive = 0' unless @filter[:inactive] == '1'
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		@export_fields = %w(id inactive name)
		
		super
	end

end