class DepartmentController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'departments.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'departments.id'],
			['Name', 'departments.name'],
			['Abbreviation', 'departments.abbreviation'],
		]
		cond = get_search_conditions @filter[:search], {
			'departments.id' => :left,
			'departments.name' => :like,
			'departments.abbreviation' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		@export_fields = %w{id name}
		super
	end

end