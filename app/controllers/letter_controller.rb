class LetterController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.agency_level? && @current_user.perm_cert_letters && params[:action] == 'apply'
		render_nothing and return false
	end
	before_filter :check_access, :except => :autocomplete

	def index
		@filter = get_filter({
			:sort1 => 'letters.name',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'letters.id'],
			['Name', 'letters.name'],
			['Subject (Public)', 'letters.public_name']
		]
		cond = get_search_conditions @filter[:search], {
			'letters.id' => :left,
			'letters.name' => :like
		}
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => nil
		}
		
		@export_fields = %w{id name body}
		
		super
	end

	def print
		f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'
		html = render_to_string :template => 'message/print_pdf', :layout => false
		html = html.gsub('src="/hrapply/uploads', 'src="/home/rails/hrapply/public/uploads').gsub("<strong", "\n<strong") # fix for weird bug where bold text was smooshed against previous word.
		f.write html
		f.close
		f2 = TempfileExt.open 'wkhtmltopdf.pdf', 'tmp'
		`wkhtmltopdf --disable-smart-shrinking --footer-html /home/rails/mccs/letter-footer.html -s Letter -O Portrait --margin-left 1in --margin-right 1in --margin-top .5in --margin-bottom .5in #{f.path} #{f2.path}`
		f2.close
		send_file f2.path, :filename => "preview.pdf", :disposition => 'inline', :type => 'application/pdf'
	end

	def apply
		objs = {}
		if params[:obj_type]
			objs = {
				:applicant => nil,
				:person => nil,
				:exam => nil,
				:cert => nil,
				:web_exam => nil
			}
			to = params[:obj_type].titleize.gsub(' ', '').constantize.find params[:obj_id]
			case params[:obj_type]
				when 'applicant'
					objs[:applicant] = to
					objs[:person] = to.person
					objs[:exam] = to.exam
					objs[:web_exam] = to.web_exam
				
				when 'person'
					objs[:person] = to
				
				when 'web_exam'
					objs[:web_exam] = to				
			
				when 'exam'
					objs[:exam] = to
				
				when 'cert'
					objs[:cert] = to
					objs[:exam] = to.exam
			end
		end
		
		objs[:user] = @current_user
		
		@obj = Letter.find params[:id]
		txt = Letter.apply(@obj.body, objs)
		render :text => {:subject => @obj.name, :body => txt, :public_name => @obj.public_name}.to_json
	end
	




end