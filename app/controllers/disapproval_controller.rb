class DisapprovalController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'disapprovals.reason',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'disapprovals.id'],
			['Reason', 'disapprovals.reason'],
		]
		cond = get_search_conditions @filter[:search], {
			'disapprovals.id' => :left,
			'disapprovals.reason' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end