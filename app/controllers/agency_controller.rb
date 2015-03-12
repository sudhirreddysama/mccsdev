class AgencyController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'agencies.name',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'agencies.id'],
			['Name', 'agencies.name'],
			['Abbreviation', 'agencies.abbreviation'],
			['Type', 'agencies.agency_type']
		]
		cond = get_search_conditions @filter[:search], {
			'agencies.id' => :left,
			'agencies.name' => :like,
			'agencies.agency_type' => :like,
			'agencies.abbreviation' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		@export_fields = %w(id name)
		super
  end
  def notes
   super

  end

end