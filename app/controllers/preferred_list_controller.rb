class PreferredListController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.agency_level? && @current_user.show_pref_lists
		render_nothing and return false
	end
	before_filter :check_access

	def index
		@filter = get_filter({
			:sort1 => 'preferred_lists.id',
			:dir1 => 'desc',
		})
		@orders = [
			['ID', 'preferred_lists.id'],
			['Title', 'preferred_lists.title'],
			['Agency', 'agencies.name'],
			['Department', 'departments.name'],
			['Established Date', 'preferred_lists.established_date'],
			['Expiration Date', 'preferred_lists.valid_until'],
			['Status', 'preferred_lists.status']
		]
		cond = get_search_conditions @filter[:search], {
			'preferred_lists.id' => :left,
			'preferred_lists.title' => :like,
			'agencies.name' => :like,
			'departments.name' => :like,
			'preferred_lists.status' => :left
		}
		
		@date_types = [
			['Established Date', 'preferred_lists.established_date'],
			['Expiration Date', 'preferred_lists.valid_until']
		]
		
		if @current_user.is_agency_county?
			cond << 'agencies.agency_type = "COUNTY"'
		elsif @current_user.agency_level?
			cond << 'agencies.id = %d' % @current_user.agency_id
			cond << 'departments.id = %d' % @current_user.department_id if @current_user.department
		end
		
		cond << get_date_cond
		
		if @filter[:typ] == 'preferred'
			cond << 'preferred_lists.list_type = "preferred"'
		end
		if @filter[:typ] == 'military'
			cond << 'preferred_lists.list_type = "military"'
		end
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:job, :agency, :department]
		}
		
		@export_fields = %w{id title agency.name department.name established_date valid_until}
		
		super
	end
	
	def build_obj
		super
		if !request.post?
			@obj.include_on_master = true
			@obj.list_type = 'preferred'
		end
	end
	
	def load_candidates
		@objs = @obj.preferred_candidates.find(:all, {
			:order => 'preferred_candidates.seniority_date asc, preferred_candidates.sort asc, preferred_candidates.tiebreaker asc',
			:conditions => 'preferred_candidates.removed = 0'
		})
	end
	
	def view
		load_candidates
		super
	end
	
	def print
		load_candidates
		@print_orient = 'Landscape'
		super
	end
	
	def new_candidate
		load_obj
		@pc = @obj.preferred_candidates.build params[:pc]
		if request.post? and @pc.save
			flash[:notice] = 'Preferred candidate has been saved.'
			redirect_to :action => :view, :id => params[:id], :id2 => nil
		end
	end
	
	def edit_candidate
		load_obj
		@pc = @obj.preferred_candidates.find params[:id2]
		if request.post? and @pc.update_attributes(params[:pc])
			flash[:notice] = 'Preferred candidate has been saved.'
			redirect_to :action => :view, :id => params[:id], :id2 => nil
		end
	end
	
	def delete_candidate
		load_obj
		@pc = @obj.preferred_candidates.find params[:id2]
		if request.post? and @pc.destroy
			flash[:notice] = 'Preferred candidate has been deleted.'
			redirect_to :action => :view, :id => params[:id], :id2 => nil
		end
	end
	
	def export_xls
		load_obj
		load_candidates
		@objs = @obj.preferred_candidates.find(:all, :order => 'preferred_candidates.seniority_date desc')
		@export_fields = %w{id first_name last_name address address2 city state zip_code seniority_date salary_group wage wage_per activity}
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		sheet.row(0).concat(@export_fields)
		@objs.each_with_index { |o, i|
			@export_fields.each_with_index { |f, j|
				sheet[i + 1, j] = o.instance_eval(f) rescue nil
			}
		}
		data = StringIO.new
		book.write data
		send_data data.string, :filename => 'export.xls', :type => 'application/vnd.ms-excel'
	end

	def cert_upload
		load_obj
		@ca = @obj.preferred_candidates.find(params[:id2])
		@doc = Document.new :preferred_candidate => @ca, :uploaded_file => params[:upload]
		if @doc.save
			render :layout => false
		else
			render_nothing
		end
	end
	
	def document_delete
		load_obj
		@ca = @obj.preferred_candidates.find(params[:id2])
		@doc = @ca.documents.find params[:id3]
		@doc.destroy
		render_nothing
	end
	
	def ca_download
		load_obj
		@ca = @obj.preferred_candidates.find(params[:id2])
		@doc = @ca.documents.find params[:id3]
		send_file @doc.path, :filename => @doc.filename
	end

	def set_activity
		load_obj
		ca = @obj.preferred_candidates.find(params[:id2])
		ca.update_attribute :activity, params[:act]
		render_nothing
	end

	def cert_request
		load_obj
		@obj.update_attribute :status, 'requested'
		flash[:notice] = 'Certification request has been sent to HR. Once certified you will receive notification via email.'
		u = Agency.get_liaison(@obj.agency, @obj.department)
		if u
			Notifier.deliver_perf_request [u], @obj
		end
		redirect_to :action => :view, :id => @obj.id
	end
	
	def cert_certify
		load_obj
		@obj.update_attribute :status, 'certified'
		flash[:notice] = 'Preferred list status has been changed to certified. Agency users can now input actions and upload documents.'
		u = @obj.agency ? @obj.agency.get_users(@obj.department, nil, 'users.show_pref_lists = 1') : nil
		if u
			Notifier.deliver_perf_certify u, @obj
		end
		redirect_to :action => :view, :id => @obj.id
	end
	
	def cert_complete
		load_obj
		@obj.update_attribute :status, 'complete'
		flash[:notice] = 'Preferred list has been completed and notification has been sent to HR.'
		u = Agency.get_liaison(@obj.agency, @obj.department)
		if u
			Notifier.deliver_perf_complete [u], @obj
		end
		redirect_to :action => :view, :id => @obj.id
	end
	
end