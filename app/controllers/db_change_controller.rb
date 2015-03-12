class DbChangeController < CrudController

	def options
		super
		@view_only = true
	end

	def index
		@filter = get_filter({
			:sort1 => 'db_changes.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['When', 'db_changes.created_at'],
			['User', 'db_changes.user'],
			['Object', 'db_changes.record_type'],
			['ID', 'db_changes.record_id'],
		]
		cond = get_search_conditions @filter[:search], {
			'db_changes.record_id' => :left,
			'db_changes.user' => :like,
			'db_changes.record_type' => :like,
			'db_changes.changes_json' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		super
	end

end