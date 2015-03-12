class PositionController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'positions.title',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'positions.id'],
			['Title', 'positions.title'],
			['Job No.', 'positions.job_no'],
			['Empl. Name', 'positions.name'],
			['Job Type', 'job_types.code'],
			['Job Class', 'job_classes.code'],
			['Agency', 'agencies.name'],
			['Department', 'departments.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'positions.id' => :left,
			'positions.title' => :like,
			'positions.job_no' => :like,
			'positions.name' => :like,
			'agencies.name' => :like,
			'departments.name' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:job_class, :job_type, :agency, :department]
		}
		super
	end

end