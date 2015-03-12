class SchoolDistrictController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'school_districts.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'school_districts.id'],
			['Name', 'school_districts.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'school_districts.id' => :left,
			'school_districts.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end