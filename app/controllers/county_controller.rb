class CountyController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'counties.name',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'counties.id'],
			['Name', 'counties.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'counties.id' => :left,
			'counties.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end