class ExamSiteController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'exam_sites.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'exam_sites.id'],
			['Name', 'exam_sites.name'],
			['Capacity', 'exam_sites.capacity'],
		]
		cond = get_search_conditions @filter[:search], {
			'exam_sites.id' => :left,
			'exam_sites.name' => :like,
			'exam_sites.address' => :like,
			'exam_sites.address2' => :like,
			'exam_sites.address3' => :like,
			'exam_sites.notes' => :like
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end