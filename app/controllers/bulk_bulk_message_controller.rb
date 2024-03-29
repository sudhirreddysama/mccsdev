class BulkBulkMessageController < CrudController
	
	def index
		@filter = get_filter({
			:sort1 => 'bulk_bulk_messages.created_at',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'bulk_bulk_messages.id'],
			['Created At', 'bulk_bulk_messages.created_at'],
			['Subject', 'bulk_bulk_messages.subject']
		]
		cond = get_search_conditions @filter[:search], {
			'bulk_bulk_messages.id' => :left,
			'bulk_bulk_messages.subject' => :like,
			'bulk_bulk_messages.body' => :like
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => nil,
		}
		super
	end	

	def build_obj
		super
		@obj.user_id = @current_user.id
		if !request.post?
			@obj.select_via = 'status'
		end
	end

	def save_redirect
		bulk_bulk = @obj
		bulk_bulk.bulk_messages.each { |bulk|
			bulk.messages.each { |m|
				@obj = m
				#m.create_directories
				#f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
				html = render_to_string :template => 'message/print_pdf', :layout => false
				html = html.gsub 'src="/hrapply/uploads', 'src="/home/rails/hrapply/public/uploads'
				m.update_attributes :body_full => html, :rendered_pdf => false
				#f.write html
				#f.close
				#`wkhtmltopdf9 --footer-html /home/rails/mccs/letter-footer.html -s Letter -O Portrait --margin-left 1in --margin-right 1in --margin-top .5in --margin-bottom .5in --ignore-load-errors #{f.path} #{m.path}`
			}
		}
		@obj = bulk_bulk
		super
	end
	
	def exams_autocomplete
		from = Date.parse(params[:from_date])
		to = Date.parse(params[:to_date])
		exams, sites = Exam.exams_and_sites_for(from, to, params[:given_by])
		@options = exams.collect { |e| ["#{e.exam_no} - #{e.title}", e.id] }
		exam_ids = render_to_string(:inline => '<%= partial "exam_ids" %>')
		@options = sites.map { |s| [s.name, s.id] }
		exam_site_ids = render_to_string(:inline => '<%= partial "exam_site_ids" %>')
		render :json => {:exam_ids => exam_ids, :exam_site_ids => exam_site_ids}.to_json
	end
	

end