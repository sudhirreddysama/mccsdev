class DocumentController < CrudController
	
	# TO DO: Implement access check based on context.
	skip_before_filter :block_agency_users
	
	def index
		@paginate = false	
		if params[:sc] == 'applicant'
			@objs2 = @sobj.person.documents.find(:all, :order => 'documents.id desc')
		end
		@opt = {:order => 'documents.id desc'}		
		super
	end
	
	def download
		load_obj
		send_file @obj.path, :filename => @obj.filename
	end
	
	def scores
		load_obj
		@objs_found, @objs_not_found, @applicants_not_found, @band_scoring = @obj.parse_scores
		if request.post?
		
			if @band_scoring
				if @obj.exam.bandscore
					@obj.exam.bandscore.destroy
				end
				atr = {:exam_id => @obj.exam_id}
				@band_scoring.each_with_index { |bs, i|
					atr["rg#{i+1}"] = "#{bs[:from]}-#{bs[:to]}"
					atr["gd#{i+1}"] = bs[:score]
				}
				Bandscore.create(atr)			
				
			end
		
			@objs_found.each { |o|
				a = o.applicant
				use_score = o.raw_score.to_f + a.other_credits.to_f
				if @band_scoring
					band = @band_scoring.find { |b|
						use_score >= b.from && use_score <= b.to
					}
					o.final_score = band.score
				end
				o.final_score = o.final_score.to_f
				o.base_score = o.final_score
				o.final_score += o.applicant.veterans_credits.to_f if o.applicant.veterans_credits
				#o.final_score += o.applicant.other_credits.to_f if o.applicant.other_credits
				attr = {
					:base_score => o.base_score,
					:raw_score => o.raw_score,
					:final_score => o.final_score
				}
				if o.final_score <= 60
					attr[:app_status_id] = 2
				end
				a.update_attributes(attr)
			}
			redirect_to
			flash[:notice] = 'Scores have been imported.'
		end
	end
	
	def move
		@obj = Document.find(params[:id], :conditions => ['documents.applicant_id = ? or documents.person_id = ?', @sobj.id, @sobj.person_id])
		if @obj.person_id
			@obj.applicant_id = @sobj.id
			@obj.person_id = nil
			@obj.save
		else
			@obj.person_id = @sobj.person_id
			@obj.applicant_id = nil
			@obj.save
		end
		flash[:notice] = 'Document has been moved.'
		redirect_to :action => :index
	end
	
	def build_obj
		super
		@obj.user = @current_user
	end
	
	def load_copy_document
		if session[:copy_document_id]
			@copy_document = Document.find_by_id session[:copy_document_id]
			if !@copy_document
				session[:copy_document_id] = nil
			end
		elsif session[:copy_message_id]
			@copy_message = Message.find_by_id session[:copy_message_id]
			if !@copy_message
				session[:copy_message_id] = nil
			end
		end
	end
	before_filter :load_copy_document
	
	def new_from_message
		m = Message.find params[:id]
		m.ensure_rendered
		@sobj.documents.create :uploaded_file => m
		flash[:notice] = 'Letter has been copied to documents.'
		redirect_to :action => :index
	end
	
	def copy
		load_obj
		session[:copy_document_id] = @obj.id
		session[:copy_message_id] = nil
		flash[:notice] = 'Document has been copied. Navigate to the documents tab where you want to paste the document and hit the &quot;paste&quot; link in the blue bar below.'
		redirect_to :back
	end

	def clear_copy
		session[:copy_document_id] = nil
		session[:copy_message_id] = nil
		redirect_to :action => :index
	end
	
	def paste
		if session[:copy_document_id]
			document = Document.find session[:copy_document_id]
			if document
				@sobj.documents << Document.new(:uploaded_file => document, :user => @current_user)
			end
			flash[:notice] = 'Document has been copied.'
		elsif session[:copy_message_id]
			message = Message.find session[:copy_message_id]
			if message
				message.ensure_rendered
				@sobj.documents << Document.new(:uploaded_file => message, :user => message.user)	
			end
		end
		redirect_to :action => :index
	end

end


