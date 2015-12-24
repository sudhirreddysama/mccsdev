class MessageController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'messages.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'messages.id'],
			['Created At', 'messages.created_at'],
			['Subject', 'messages.subject']
		]
		cond = get_search_conditions @filter[:search], {
			'messages.id' => :left,
			'messages.subject' => :like,
			'messages.body' => :like
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => :user,
		}
		super
	end
	
	def build_obj
		super
		@obj.user_id = @current_user.id
		if @obj.applicant
			@obj.person = @obj.applicant.person
		end
	end
	
	def save_redirect
		#@obj.create_directories
		#f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
		html = render_to_string :action => :print_pdf, :layout => false
		html = html.gsub 'src="/hrapply/uploads', 'src="/home/rails/hrapply/public/uploads'
		@obj.update_attributes :body_full => html, :rendered_pdf => false
		#f.write html
		#f.close
		#`wkhtmltopdf9 --footer-html /home/rails/mccs/letter-footer.html -s Letter -O Portrait --margin-left 1in --margin-right 1in --margin-top .5in --margin-bottom .5in --ignore-load-errors #{f.path} #{@obj.path}`
		super
	end
	
	def duplicate
		@original,@obj = @obj,@obj.clone
		@obj.attributes = params[:obj] if request.post?
		@obj.user_id = @current_user.id
		new
	end	
	
	def print_pdf
		load_obj
		@obj.ensure_rendered
		send_file @obj.path, :filename => "#{@obj.subject}.pdf", :disposition => 'inline', :type => 'application/pdf'
	end
		
	def copy
		load_obj
		session[:copy_message_id] = @obj.id
		session[:copy_document_id] = nil
		flash[:notice] = 'Letter has been copied. Navigate to the documents tab where you want to paste the letter\'s PDF and hit the &quot;paste&quot; link in the blue bar below.'
		redirect_to :back
	end

end