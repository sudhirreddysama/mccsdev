class PerfTestController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'perf_tests.name',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'perf_tests.id'],
			['Name', 'perf_tests.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'perf_tests.id' => :left,
			'perf_tests.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end