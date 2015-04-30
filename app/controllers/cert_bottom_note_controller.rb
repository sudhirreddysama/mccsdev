class CertBottomNoteController < CrudController

	def index
		@paginate = false
		@opt = {:order => 'cert_bottom_notes.sort asc'}
		super
	end
	
	def delete_ajax
		load_obj
		@obj.destroy
		render_nothing
	end
	
end