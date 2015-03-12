class CertCodeController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'cert_codes.description',
			:dir1 => 'asc',
		})
		@orders = [
			['ID', 'cert_codes.id'],
			['Code', 'cert_codes.code'],
			['Label', 'cert_codes.label'],
			['Description', 'cert_codes.description']
		]
		cond = get_search_conditions @filter[:search], {
			'cert_codes.id' => :left,
			'cert_codes.code' => :like,
			'cert_codes.label' => :like,
			'cert_codes.description' => :like
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto
		}
		
		@export_fields = %w(id code label description exclude)
		super
	end

end