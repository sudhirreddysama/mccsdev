class CertEndOfListController < CrudController

	def index
		@paginate = false
		@opt = {:order => 'cert_end_of_lists.sort asc'}
		super
	end
	
	def delete_ajax
		load_obj
		@obj.destroy
		render_nothing
	end
	
end