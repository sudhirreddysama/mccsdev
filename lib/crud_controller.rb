class CrudController < ApplicationController

	def options
		@model = params[:controller].camelize.constantize
		if params[:sc]
			@smodel = params[:sc].camelize.constantize
			@sobj = @smodel.find params[:sid]
			@assoc = @sobj.send @model.to_s.tableize
		end
	end
	
	def index
		fetch_objs
		template if !params[:export]
	end
	
	def fetch_objs
		@opt ||= {}
		if @paginate != false && !params[:export]
			@opt[:per_page] ||= 25
			@opt[:page] ||= params[:page]
			@objs = (@assoc || @model).paginate(:all, @opt)
		else
			@objs = (@assoc || @model).find(:all, @opt)
			if params[:export]
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
		end
	end
	
	def build_obj
		if params[:sc]
			@obj = @assoc.build params[:obj]
		else
			@obj = @model.new params[:obj]
		end	
	end
	
	def save_redirect
		redirect_to @redirect || (params[:another] ? {} : {:action => :view, :id => @obj.id})
		if params[:upload_ids]
			@docs = Document.find(params[:upload_ids], :conditions => {:user_id => @current_user.id, :temporary => true})
			@docs.each { |d|
				d.update_attributes :temporary => false, @model.to_s.underscore => @obj
			}
		end
	end
	
	def new
		@obj.http_posted = true
		if request.post? and @obj.save
			flash[:notice] = 'Record has been saved.'
			save_redirect
			return
		end
		template
	end
	
	before_filter :build_obj, :only => [:new]
	
	def load_obj
		if params[:sc]
			@obj = @assoc.find params[:id]
		else
			@obj = @model.find params[:id]
		end
	end
	
	before_filter :load_obj, :only => [:edit, :view, :delete, :duplicate, :print, :change_log]
	
	def view
		template
	end
	
	def edit
		@obj.http_posted = true
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'Record has been saved.'
			save_redirect
			return
		end
		template
  end
  def notes
    if request.post? and @obj.update_attributes params[:obj]
      flash[:notice] = 'Record has been saved.'
      save_redirect
      return
    end
    template
  end
  
  #def social_media
  #  @obj.http_posted = true
  #  if request.post? and @obj.update_attributes params[:obj]
  #    flash[:notice] = 'Record has been saved.'
  #    save_redirect
  #    return
  #  end
  #  template
  #end
	
	def delete
		if request.post? and @obj.destroy
			flash[:notice] = 'Record has been deleted.'
			redirect_to :action => :index
			return
		end
		template
	end
	
	def duplicate
		@original,@obj = @obj,@obj.clone
		@obj.attributes = params[:obj] if request.post?
		new
	end
	
	def sort
		input = params[:order] || params[:objs]
		input.each_with_index { |oid, sort|
			@model.update oid.to_i, :sort => sort
		}
		render_nothing		
	end
	
	def init_form
	end
	
	before_filter :init_form, :only => [:edit, :new, :social_media]
	
	def print
		@opt ||= {}
		render_pdf render_to_string(:layout => false), "#{@obj.label}.pdf", @opt
	end
	
	def change_log
		@objs = @obj.db_changes.paginate(:all, :page => params[:page], :per_page => 50)
		template
	end
	
	
	
	
end