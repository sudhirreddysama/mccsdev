class UploadController < ApplicationController
	
	# TO DO: Implement access check based on context.
	skip_before_filter :block_agency_users

	def new
		@doc = Document.create :uploaded_file => params[:file], :filename => params[:name], :user => @current_user, :temporary => true
		render :layout => false
	end
	
	def load_doc
		@doc = Document.find_by_id_and_user_id_and_temporary params[:id], @current_user.id, true
	end
	
	def download
		load_doc
		send_file @doc.path, :filename => @doc.filename
	end
	
	def delete
		load_doc
		@doc.destroy
		render_nothing
	end

end