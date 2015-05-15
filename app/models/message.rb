class Message < ActiveRecord::Base
	
	belongs_to :letter
	belongs_to :applicant
	belongs_to :person
	belongs_to :delivery
	belongs_to :user
	belongs_to :bulk_message
	
	validates_presence_of :subject, :body
	
	def label; subject_was; end
	
	#def has_email?; person && !person.email.blank?; end
	
	#def can_email?; has_email? && person.prefer_email; end

	def create_directories
		`mkdir messages/#{created_at.year}`
		`chmod 777 messages/#{created_at.year}`
		`mkdir messages/#{created_at.year}/#{created_at.month}`
		`chmod 777 messages/#{created_at.year}/#{created_at.month}`
	end
	
	def render_pdf
		if !body_full.blank? # Race condition where the HTML hasn't been saved yet but cron is running.
			create_directories
			f = TempfileExt.open 'wkhtmltopdf.html', 'tmp'			
			f.write body_full
			f.close
			`wkhtmltopdf9 --footer-html /home/rails/mccs/letter-footer.html -s Letter -O Portrait --margin-left 1in --margin-right 1in --margin-top .5in --margin-bottom .5in --ignore-load-errors #{f.path} #{path}`			
			update_attribute :rendered_pdf, true
		end
	end
	
	def ensure_rendered
		if !rendered_pdf
			render_pdf
		end
	end
	
	def path
		"messages/#{created_at.year}/#{created_at.month}/#{id}.pdf"	
	end
	
  def create_download_key
  	k = nil
  	begin
  		k = Array.new(8) { rand(9).to_s }.join
  	end while Message.find_by_download_key k
  	self.update_attribute :download_key, k
  end	
  
  after_create :create_download_key
	
	def clone
		c = super
		c.delivery_id = nil
		c.delivered_via = nil
		c.delivered_email = false
		c.rendered_pdf = false
		c.created_at = Time.now
		return c
	end
	
	def self.pending_render_count
		to_render = Message.count(:all, :conditions => 'messages.rendered_pdf = 0')
	end
	
	def self.pending_email_count
		to_email = Message.count(:all, :conditions => 'messages.delivered_email = 0 and messages.delivered_via in ("email", "both") and messages.delivery_id is not null')
	end
	
	def self.render_and_email_messages
		
		system = System.find(:first)
		if system.processing_letters
			return
		end
		system.update_attribute :processing_letters, true
		

		to_render = Message.find(:all, :limit => 10, :conditions => 'messages.rendered_pdf = 0', :include => :person)
		to_render.each { |m|
			m = Message.find m.id # In case the message was edited.
			m.render_pdf
		}
		
		to_email = Message.find(:all, :limit => 10, :conditions => 'messages.delivered_email = 0 and messages.delivered_via in ("email", "both") and messages.delivery_id is not null', :include => :person)
		to_email.each { |m|
			Notifier.deliver_message m
			m.update_attribute :delivered_email, true
		}
		
		system.update_attribute :processing_letters, false
		
	end
	
	include DbChangeHooks
	
end