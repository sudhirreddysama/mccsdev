class ProvisionalController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'provisionals.title',
			:dir1 => 'asc',
			:sort2 => 'provisionals.name',
			:dir2 => 'asc'
		})
		@orders = [
			['ID', 'provisionals.id'],
			['Title', 'provisionals.title'],
			['Name', 'provisionals.name'],
			['Jurisdiction', 'provisionals.jurisdiction'],
		]
		cond = get_search_conditions @filter[:search], {
			'provisionals.id' => :left,
			'provisionals.title' => :like,
			'provisionals.name' => :like,
			'provisionals.jurisdiction' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		@export_fields = %w{id name second_provisional title exam_requested original_appointment exam_date jurisdiction pass_fail}
		super
	end
	
	def build_obj
		super
		@obj.reference_date = Time.now.to_date unless request.post?
	end

end