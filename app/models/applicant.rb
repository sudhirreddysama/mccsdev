class Applicant < ActiveRecord::Base

	has_many :documents

	belongs_to :person
	belongs_to :exam
	belongs_to :app_status
	belongs_to :exam_site
	belongs_to :web_applicant
	belongs_to :web_exam
	belongs_to :disapproval
		
	belongs_to :agency
	belongs_to :department
		
	has_many :list_notes
	has_many :web_attachments, :through => :web_applicant
	has_many :messages
	has_many :cert_applicants
	
	has_many :applicant_notes
	
	has_many :taken_perfs, :dependent => :delete_all
	
	def label; "#{exam ? exam.exam_no : ''} #{person ? person.label : 'UNKNOWN'}"; end
	
	has_many :app_updates, :order => 'app_updates.created_at desc'
	
	validates_presence_of :person
	
	def new_taken_perfs
		@new_taken_perfs ||= taken_perfs
	end
	
	def gender
		@gender ||= person.gender
	end
	
	def gender= v
		@gender = v
		@update_gender = true
	end
	
	def set_gender
		if @update_gender
			person.update_attribute :gender, @gender
		end
	end
	after_save :set_gender
	
	def new_taken_perfs= v
		@new_taken_perfs = []
		v.each { |tp|
			if !tp.perf_test_id.blank? && (!tp.date_taken.blank? || !tp.perf_code_id.blank?)
				tp.perf_code_id = tp.perf_code_id.to_i unless tp.perf_code_id.blank?
				tp.perf_test_id = tp.perf_test_id.to_i
				tp.exam_id = exam_id
				tp.applicant_id = id
				tp.person_id = person_id
				@new_taken_perfs << TakenPerf.new(tp)
			end
		}
	end
	
	attr :save_new_taken_perfs, true
	
	def check_new_taken_perfs
		if @save_new_taken_perfs
			@new_taken_perfs ||= []
			
			self.taken_perfs = @new_taken_perfs
		end
	end
	after_save :check_new_taken_perfs
	
	def status_code; app_status.code if app_status; end
	def status_code= v; self.app_status = AppStatus.find_by_code v; end
	
	def site_name
		exam_site ? exam_site.name : ''
	end
	
	def site_address
		exam_site ? exam_site.full_address : ''
	end
	
	def site_address_inline
		exam_site ? exam_site.full_address_inline : ''
	end
	
	def generate_tiebreaker
		if tiebreaker.blank?
			self.tiebreaker = (0...8).map{ (65 + rand(26)).chr }.join
		end
	end
	before_save :generate_tiebreaker
	
	def taken_perfs_for_fields
		@taken_perfs_for_fields ||= taken_perfs.find(:all, :include => :perf_test, :order => 'perf_tests.name').to_a
	end
	
	def perf_test1_name; taken_perfs_for_fields[0].perf_test.name; end
	def perf_test1_date; taken_perfs_for_fields[0].date_taken.fmt; end
	def perf_test1_time; taken_perfs_for_fields[0].time_taken; end
	
	def perf_test2_name; taken_perfs_for_fields[1].perf_test.name; end
	def perf_test2_date; taken_perfs_for_fields[1].date_taken.fmt; end
	def perf_test2_time; taken_perfs_for_fields[1].time_taken; end
	
	def create_app_update
		if app_status_id_changed? && !new_record?
			s1 = app_status_id_was ? AppStatus.find(app_status_id_was).name : 'BLANK'
			s2 = app_status ? app_status.name : 'BLANK'
			au = app_updates.create({
				:user_id => Thread.current[:user_id],
				:text => "Status changed from #{s1} to #{s2}."
			})
		end
	end
	before_save :create_app_update
	
	def create_first_app_update
		s1 = web_applicant ? 'Application imported.' : 'Application created.'
		s2 = app_status ? app_status.name : 'BLANK'
		au = app_updates.create({
			:user_id => Thread.current[:user_id],
			:text => "#{s1} Status is #{s2}."
		})
	end
	after_create :create_first_app_update
	
	def exam_date
		alternate_exam_date || exam.given_at.to_date
	end
	
	def calculated_seniority_years
		d1 = seniority_date
		d2 = exam && exam.given_at.to_date	
		y = 0
		if d1 && d2
			y = d2.year - d1.year 
			if d1.month > d2.month
				y = y - 1
			elsif d1.month == d2.month && d1.day > d2.day
				y = y - 1
			end
		end
		return y
	end
	
	def calculated_seniority_points
		y = calculated_seniority_years
		if y >= 21
			return 5
		elsif y >= 16
			return 4
		elsif y >= 11
			return 3
		elsif y >= 6
			return 2
		elsif y >= 1
			return 1
		end
		return 0
	end
	
	include DbChangeHooks
	
end