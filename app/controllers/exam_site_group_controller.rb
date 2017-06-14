class ExamSiteGroupController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'exam_site_groups.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'exam_site_groups.id'],
			['Name', 'exam_site_groups.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'exam_site_groups.id' => :left,
			'exam_site_groups.head_proctor_room' => :like,
			'exam_site_groups.name' => :like,
			'exam_site_groups.address' => :like,
			'exam_site_groups.address2' => :like,
			'exam_site_groups.address3' => :like,
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		super
	end

end