class TownController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'towns.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'towns.id'],
			['Name', 'towns.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'towns.id' => :left,
			'towns.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end