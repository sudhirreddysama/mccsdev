class SeasonalAppController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'seasonal_apps.created_at',
			:dir1 => 'desc',
		})
		@orders = [
			['ID', 'seasonal_apps.id'],
			['Name', 'seasonal_apps.name'],
			['Received', 'seasonal_apps.created_at']
		]
		cond = get_search_conditions @filter[:search], {
			'seasonal_apps.id' => :left,
			'seasonal_apps.name' => :like,
			'seasonal_apps.ssn' => :like
		}
		@date_types = [
			['Received', 'seasonal_apps.created_at'],
		]
		cond << get_date_cond		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		@export_fields = %w(id created_at name ssn phone_day phone_alt email county address city state zip_code)
		super
	end

end