class NoticeController < CrudController
	
	def options
		params[:popup] = true
		super
	end
	
	def index
		@obj = @sobj.notices.build 
		@obj.user = @current_user
		if request.post?
			@obj.attributes = params[:obj]
			if @obj.save
				if params[:upload_ids]
					@docs = Document.find(params[:upload_ids], :conditions => {:user_id => @current_user.id, :temporary => true})
					@docs.each { |d|
						d.update_attributes :temporary => false, @smodel.to_s.underscore => @sobj, :notice => @obj
					}		
				end
				if !@obj.recipients.blank?
					Notifier.deliver_notice @obj
				end
				flash[:notice] = 'Message has been saved / delivered.'
				redirect_to
				return
			end
		end
		@objs = @sobj.notices.find(:all, :order => 'notices.created_at desc')
	end
	
	def recipients_autocomplete
		cond = get_search_conditions(params[:q], {
			'username' => :like,
			'name' => :like,
			'email' => :like
		})
		@objs = User.find(:all, :conditions => get_where(cond), :limit => 15)
		@json =  @objs.collect { |o| {:id => o.id, :name => o.name} }
		render :json => @json.to_json
	end
	
	def delete
		if @current_user.admin_level?
			@obj.destroy
			flash[:notice] = 'Message has been deleted.'
		end
		redirect_to :action => :index
	end
	
end