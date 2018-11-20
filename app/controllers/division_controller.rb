class DivisionController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'divisions.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'divisions.id'],
			['Name', 'divisions.name'],
			['Department Name', 'departments.name'],
		]
		cond = get_search_conditions @filter[:search], {
			'divisions.id' => :left,
			'divisions.name' => :like,
			'departments.name' => :like,
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:department]
		}
		@export_fields = %w{id name department.name}
		super
	end
	
	def division_select
		@opts = nil
		if !params.department_id.blank?
			@opts = Division.find(:all, :conditions => ['divisions.department_id = ?', params.department_id]).map { |d| [d.name, d.id] }
		end
		render :inline => "<%= partial 'division/division_select_field', :department_id => params.department_id, :division_id => nil, :field_name => params.field_name, :opts => @opts %>"
	end

end