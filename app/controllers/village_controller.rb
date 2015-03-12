class VillageController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'villages.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'villages.id'],
			['Name', 'villages.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'villages.id' => :left,
			'villages.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end