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
			['2nd Prov', 'provisionals.second_provisional'],
			['2nd Prov (as date)', 'str_to_date(provisionals.second_provisional, "%m/%d/%Y")'],
			['Exam Req.', 'provisionals.exam_requested'],
			['Exam Req. (as date)', 'str_to_date(provisionals.exam_requested, "%m/%d/%Y")'],
			['Orig. Apt.', 'provisionals.original_appointment'],
			['Orig. Apt. (as date)', 'str_to_date(provisionals.original_appointment, "%m/%d/%Y")'],
			['Exam Date', 'provisionals.exam_date'],
			['Exam Date (as date)', 'str_to_date(provisionals.exam_date, "%m/%d/%Y")'],
			['Ref. Date (as date)', 'provisionals.reference_date'],
			['Illegal', 'provisionals.pass_fail']
		]
		cond = get_search_conditions @filter[:search], {
			'provisionals.id' => :left,
			'provisionals.title' => :like,
			'provisionals.name' => :like,
			'provisionals.jurisdiction' => :like,
			'provisionals.second_provisional' => :like,
			'provisionals.exam_requested' => :like,
			'provisionals.original_appointment' => :like,
			'provisionals.exam_date' => :like
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