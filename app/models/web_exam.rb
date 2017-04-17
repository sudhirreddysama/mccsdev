class WebExam < ActiveRecord::Base
	
	WHO_MAY_APPLY_PRESETS = [
		'Promotional', 
		'Promotional - MC', 
		'Open to Public',
		'Open to Public - Residency Waived'
	]
	
	has_many :documents
	has_many :bulk_messages
	has_many :applicants
	
	has_one :web_exam_total, :foreign_key => 'id'
	
	set_table_name "#{HRAPPLYDB}.exams"
	
	has_and_belongs_to_many :users
	
	has_and_belongs_to_many(:web_new_categories, {
		:join_table => "#{HRAPPLYDB}.exams_new_categories", 
		:foreign_key => :exam_id, 
		:association_foreign_key => :new_category_id
	})
	
	belongs_to :web_exam_type, :foreign_key => 'exam_type_id'
	
	belongs_to :liaison, :class_name => 'User', :foreign_key => 'liaison_id'
	belongs_to :liaison2, :class_name => 'User', :foreign_key => 'liaison2_id'
	
	validates_presence_of :name, :web_exam_type
	
	def label; name_was; end

	def new_web_new_category_ids
		@new_web_new_category_ids ||= web_new_category_ids
	end
	
	def new_web_new_category_ids= v
		@new_web_new_category_ids = v.map(&:to_i)
	end
	
	def check_new_web_new_category_ids
		self.web_new_category_ids = @new_web_new_category_ids if @new_web_new_category_ids
	end
	after_save :check_new_web_new_category_ids
	
	def self.web_exam_deadline_cron
		User.find(:all, {
			:include => :liaison_web_exams,
			:conditions => 'date(' + HRAPPLYDB + '.exams.deadline) = date(now())'
		}).each { |u|
			Notifier.deliver_web_exam_deadline u, u.liaison_web_exams
		}
		# This does exactly the same as above but for liason2
		User.find(:all, {
			:include => :liaison2_web_exams,
			:conditions => 'date(' + HRAPPLYDB + '.exams.deadline) = date(now())'
		}).each { |u|
			Notifier.deliver_web_exam_deadline u, u.liaison2_web_exams
		}		
	end
	
	def clone
		c = super
		c.facebook_posted = false
		c.twitter_posted = false
		c.notified = false
		return c
	end
	
	include DbChangeHooks
	
end