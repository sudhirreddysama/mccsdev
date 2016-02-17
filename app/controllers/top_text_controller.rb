class TopTextController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'agencies.name',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'top_texts.id'],
			['Name', 'top_texts.name'],
			['Path', 'top_texts.path']
		]
		cond = get_search_conditions @filter[:search], {
			'top_texts.id' => :left,
			'top_texts.name' => :like,
			'top_texts.path' => :like,
			'top_texts.text' => :like,
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		@export_fields = %w(id name path text)
		super
  end

end