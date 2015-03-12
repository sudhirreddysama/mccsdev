class ListNoteController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'list_notes.date',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'list_notes.id'],
			['Date', 'list_notes.note_date'],
			['Note', 'list_notes.note'],
		]
		cond = get_search_conditions @filter[:search], {
			'list_notes.id' => :left,
			'list_notes.note' => :like
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [{:applicant => :exam}]
		}
		super
	end

end