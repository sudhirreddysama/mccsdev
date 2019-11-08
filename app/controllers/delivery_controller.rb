class DeliveryController < CrudController

	skip_before_filter :block_agency_users
	def check_access
		return true if @current_user.above_agency_level?
		return true if @current_user.agency_level? && @current_user.perm_cert_letters
		render_nothing and return false
	end
	before_filter :check_access, :except => :autocomplete

	def index
		@opt = {
			:order => 'deliveries.created_at desc'
		}		
		super
	end
	
	def new
		preview = params[:preview]
		if request.post? && preview
			params[:user_ids] ||= []
		end
		cond = ['deliveries.id is null' + ((request.post? && !preview) ? ' and (deliver_after is null or deliver_after <= now())' : '')]
		cond << 'messages.contact_id is null'
		cond << 'messages.user_id in (%s)' % params[:user_ids].map(&:to_i).join(',') unless params[:user_ids].blank?
		@messages = Message.find(:all, {
			:include => [:delivery, :applicant, :person],
			:conditions => get_where(cond),
			:order => 'people.last_name, people.first_name'
		})
		@postal_count = 0
		@email_count = 0
		@both_count = 0
		@messages.each { |m|
			u = m.person
			if m.force_postal
				m.delivered_via = 'postal'
				@postal_count += 1
			elsif u && u.contact_via == 'both'
				m.delivered_via = 'both'
				@both_count += 1
			elsif u && u.contact_via == 'email'
				m.delivered_via = 'email'
				@email_count += 1
			else
				m.delivered_via = 'postal'
				@postal_count += 1
			end
		}
		if request.post? && !preview
			if @messages.empty?
				flash[:errors] = ['No letters to deliver for the selected users.']
				redirect_to
				return
			end
			@obj = Delivery.create({ 
				:message_count => @messages.size, 
				:user_id => @current_user.id,
				:postal_count => @postal_count,
				:email_count => @email_count,
				:both_count => @both_count
			})
			@messages.each { |m|
				#if m.delivered_via == 'both' || m.delivered_via == 'email'
				#	Notifier.deliver_message m
				#end
				m.delivery_id = @obj.id
				m.save				
			}
			flash[:notice] = 'Delivery record created.'
			redirect_to :action => :view, :id => @obj.id
		end
	end
	
	def print
		f = TempfileExt.open 'delivery.pdf', 'tmp'
		f.close
		@messages = @obj.messages.find(:all, {
			:conditions => 'delivered_via != "email" or delivered_via is null',
			:include => :person,
			:order => 'people.last_name, people.first_name',
			:limit => params[:print][:limit].to_i,
			:offset => params[:print][:offset].to_i - 1
		})
		@messages.each { |m|
			m.ensure_rendered
		}
		paths = @messages.collect(&:path).join(' ')
		`pdftk #{paths} cat output #{f.path}`
		send_file f.path, :filename => "postal-delivery-#{@obj.id}.pdf", :disposition => 'inline', :type => 'application/pdf'
	end
	
end