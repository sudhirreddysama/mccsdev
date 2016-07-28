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
			['HR Liaison', 'users.name'],
			['OMB Liaison', 'omb_liaisons_departments.name']
		]
		cond = get_search_conditions @filter[:search], {
			'departments.id' => :left,
			'departments.name' => :like,
			'departments.abbreviation' => :like,
			'users.name' => :like,
			'omb_liaisons_departments.name' => :like
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
	#		:joins => 'left join users u2 on u2.id = departments.omb_liaison_id',
			:include => [:liaison, :omb_liaison]
		}
		
		@export_fields = %w{id name}
		super
	end

end