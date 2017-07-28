class PersonnelDivisionController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'personnel_divisions.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'personnel_divisions.id'],
			['Name', 'personnel_divisions.name'],
			['Area Name', 'personnel_areas.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'personnel_divisions.id' => :left,
			'personnel_divisions.name' => :like,
			'personnel_divisions.emails' => :like,
			'personnel_areas.name' => :like,
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:personnel_area]
		}
		@export_fields = %w{id name emails personnel_area.no personnel_area.name personnel_area.emails}
		super
	end

end