class EmplActionTypeController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'empl_action_types.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'empl_action_types.id'],
			['Name', 'empl_action_types.name'],
			['Absent', 'empl_action_types.absent'],
		]
		cond = get_search_conditions @filter[:search], {
			'empl_action_types.id' => :left,
			'empl_action_types.name' => :like,
			'empl_action_types.description' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end