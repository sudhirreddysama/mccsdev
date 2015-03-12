class FireDistrictController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'fire_districts.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'fire_districts.id'],
			['Name', 'fire_districts.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'fire_districts.id' => :left,
			'fire_districts.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end