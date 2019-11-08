class PersonnelAreaController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'personnel_areas.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'personnel_areas.id'],
			['Name', 'personnel_areas.name'],
			['No', 'personnel_areas.no'],
		]
		cond = get_search_conditions @filter[:search], {
			'personnel_areas.id' => :left,
			'personnel_areas.name' => :like,
			'personnel_areas.no' => :like,
			'personnel_areas.emails' => :like,
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		@export_fields = %w{id name no emails}
		super
	end

end