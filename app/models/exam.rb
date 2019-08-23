class Exam < ActiveRecord::Base
  has_many :documents
	
	belongs_to :job
	belongs_to :exam_site

	has_many :applicants
	has_many :exam_perfs
	
	has_many :list_notes, :through => :applicants
	has_many :certs
	has_many :taken_perfs
	
	has_many :exam_site_assignments
	
	belongs_to :current_exam, :class_name => 'Exam', :foreign_key => :current_exam_id
	belongs_to :original_exam, :class_name => 'Exam', :foreign_key => :original_exam_id
	
	has_many :past_exams, :class_name => 'Exam', :foreign_key => :current_exam_id
	has_many :later_exams, :class_name => 'Exam', :foreign_key => :original_exam_id	
	
	has_many :bulk_messages
	
	has_one :bandscore
	
	validates_presence_of :exam_no
	
	validates_uniqueness_of :exam_no
	
	def label; "#{exam_no_was} #{title_was}"; end
	
	def site; exam_site; end
	
	def new_exam_sites
		@new_exam_sites ||= exam_site_assignments.find(:all, :order => 'sort')
	end
	
	def new_exam_sites= v
		@new_exam_sites = []
		i = 0;
		v.each { |s|
			unless s.exam_site_id.blank?
				s[:sort] = i;
				i += 1;
				@new_exam_sites << ExamSiteAssignment.new(s)
			end
		}
	end
	
	def handle_before_validation
		self.cr_group = self.cr_group.to_i
	end
	before_validation :handle_before_validation
	
	attr :save_new_exam_sites, true
	
	def check_new_exam_sites
		self.exam_site_assignments = @new_exam_sites if @save_new_exam_sites
	end
	after_save :check_new_exam_sites
	
	def new_perf_test_ids
		@new_perf_test_ids ||= exam_perfs.find(:all).collect(&:perf_test_id)
	end
	
	def new_perf_test_ids= v
		@new_perf_test_ids = v.map(&:to_i)
	end
	
	attr :save_new_perf_test_ids, true
	
	def check_new_perf_test_ids
		self.exam_perfs = (@new_perf_test_ids || []).collect { |id| ExamPerf.new(:perf_test_id => id) } if @save_new_perf_test_ids
	end
	after_save :check_new_perf_test_ids
	
	# This makes sure ALL continuous recruitment exams have a current_exam_id that points to the most recently established exam, and
	# and original_exam_id that points to the original exam.
	def set_current_exam_ids
		DB.query('update exams set current_exam_id = null where continuous = 0 or established_date is null or valid_until is null')
		DB.query('
			update exams e
			join (
				select e.id, e.title, e.exam_type, e.cr_group, e.established_date from exams e 
				join (
					select title, exam_type, cr_group, max(established_date) established_date from exams 
					where continuous = 1 and established_date is not null and valid_until is not null
					group by title, exam_type, cr_group
				) e2 on e2.established_date = e.established_date and e2.title = e.title and e2.exam_type = e.exam_type and e2.cr_group = e.cr_group
				where e.continuous = 1 and e.established_date is not null and e.valid_until is not null
			) e2 on e2.title = e.title and e2.exam_type = e.exam_type and e2.cr_group = e.cr_group
			set e.current_exam_id = e2.id
			where e.continuous = 1 and e.established_date is not null and e.valid_until is not null		
		')
		DB.query('
			update exams e
			join (
				select e.id, e.current_exam_id, e.established_date from exams e 
				join (
					select current_exam_id, min(established_date) established_date from exams 
					where current_exam_id is not null
					group by current_exam_id
				) e2 on e2.established_date = e.established_date and e2.current_exam_id = e.current_exam_id
				where e.current_exam_id is not null
			) e2 on e2.current_exam_id = e.current_exam_id
			set e.original_exam_id = e2.id
			where e.current_exam_id is not null
		')
	end
	after_save :set_current_exam_ids
	
	attr :send_pending_cert_email, true
	def check_pending_cert_exam_established
		if send_pending_cert_email.to_i == 1
			pending_certs.each { |c|
				Notifier.deliver_pending_cert_exam_established c, self
			}
		end
	end
	before_save :check_pending_cert_exam_established
	
	def pending_certs
		certs.find(:all, :conditions => '(certs.certification_date is null or certs.certification_date > date(now())) and certs.pending_date <= date(now())')
	end
	
	def calculator_prohibited?
		calculator == 'PROHIBITED'
	end
	
	def open_certs
		job ? job.open_certs : []
	end
	
	# Passed from popup select windows to parent window.
	def json_attributes
		{:established_date => established_date, :valid_until => valid_until}
	end
	
	def alt_prom_exams(agency = nil, department = nil, division = nil)
		return [] if exam_type == 'PROM' || exam_type == 'NCP' || !job
		cond = ['exams.exam_type in ("PROM", "NCP") and exams.established_date <= date(now()) and exams.valid_until >= date(now()) and job_id = %d' % job_id.to_i]
		cond << 'applicants.agency_id = %d' % agency.id if agency
		cond << 'applicants.department_id = %d' % department.id if department
		cond << 'applicants.division_id = %d' % division.id if division
		cond << 'app_statuses.eligible = "A"'
		Exam.find(:all, :conditions => "(#{cond * ') and ('})", :include => {:applicants => :app_status})
	end
	
	
	def calc_rank_and_pos
		
		duplicate_people = []
		
		self.no_applicants = 0
		self.no_passed = 0
		self.no_failed = 0
		self.no_rejected = 0
		self.no_absent = 0
		
		# If continuous, find applicants for all exams in the series.
		if continuous && current_exam_id
			cond = ('exams.current_exam_id = %d and exams.valid_until >= date(now())' % current_exam_id)
		else
			cond = ('exams.id = %d' % id)
		end
		
		# Find all applicants, not just those that passed, include the tiebreaker for sorting.
		# If an applicant has taken a CR exam more than once (with overlapping eligibility), their tiebreaker should be the same (I don't think this is true).
		apps = Applicant.find(:all, {
			:conditions => cond,
			:order => 'applicants.final_score desc, applicants.tiebreaker desc, exams.valid_until desc',
			:include => [:app_status, :department, :exam]
		})
		
		self.no_applicants = apps.size
		
		# Promotional exams are grouped by department. Group all applicants for normal exams under "ALL" (one group).
		groups = {}
		if sort_by_department
			apps.each { |a|
				n = a.department ? a.department.name : 'UNKNOWN'
				groups[n] ||= []
				groups[n] << a
			}
		else
			groups['ALL'] = apps
		end
		
		# Get the performance tests for this exam.
		ptests = exam_perfs.find(:all,  :include => :perf_test)
		
		# Get the performance tests TAKEN for this exam, index by applicant & perf_test.
		ptakens = TakenPerf.find(:all, {
			:include => [:perf_code, :exam],
			:conditions => cond
		}).index_by { |t| 
			"#{t.applicant_id}-#{t.perf_test_id}"
		}
		
		people_processed = {}
		
		# Loop through the groups.
		groups.each { |k, grp|
		
			# Each group starts pos = 1, rank = 1. Departments restart the pos, rank.
			pos = 1
			rank = 1
			last_score = nil
			grp.each { |a|
				
				# Find any performance tests that were taken for this exam for this applicant.
				# Ideally could just loop through the taken perfs without caring about the specific perf_test
				# (we just need to check if it was failed) but this way if for whatever reason there's a 
				# taken_perf but no perf_test on the exam, it'll be ignored.
				failed_perf = false
				a.perf_test_status = nil
				ptests.each { |pt|
					if pt.perf_test
						
						ptaken = ptakens["#{a.id}-#{pt.perf_test_id}"]
						
						# If performance test was not taken let them on the list anyway. Only exclude if they FAILED.
						if ptaken && ptaken.perf_code && ptaken.perf_code.pass_fail != 1
							failed_perf = true
							a.perf_test_status = 'F'
							break
						elsif !ptaken || !ptaken.perf_code
							a.perf_test_status = 'R'
						end

					end
				}				
				
				if !failed_perf
					person_done = people_processed[a.person_id]
					#people_processed[a.person_id] = true
				end

				as = a.app_status
				
				score_bad = a.final_score.to_f <= 60
				
				if person_done
					a.pos = 0
					a.rank = 0
					if as && as.eligible != 'N' && !failed_perf && !score_bad
						duplicate_people << a
					end
				else
					
					if as && as.eligible != 'N' && !failed_perf && !score_bad
						
						people_processed[a.person_id] = true
						
						self.no_passed += 1
						
						a.pos = pos
						pos += 1
						if last_score.nil? || last_score != a.final_score
							rank += 1
						end
						last_score = a.final_score
						a.rank = rank
					else
						a.pos = 0
						a.rank = 0
						
						if as && as.code == '-'
							self.no_absent += 1
						end
						
						if((as && as.code == 'F') || failed_perf || score_bad)
							self.no_failed += 1
						end
						
						if a.approved == 'N'
							self.no_rejected += 1
						end
						
					end
				end
				a.save
			}
		}
		return duplicate_people
	end
	
	def grey_on_master?
		return ((valid_until and valid_until < Time.now.to_date) || (!valid_until and given_at and given_at.advance(:years => 1) < Time.now.to_date))
	end
	
	def self.exams_and_sites_for(from, to, given_by)
		cond = [DB.escape('date(exams.given_at) between "%s" and "%s"', from.to_s, to.to_s)]
		cond << 'exams.given_by in (%s)' % given_by.map(&:to_i).join(', ') unless given_by.blank?
		where = '(' + cond.join(') and (') + ')'
		exams = Exam.find(:all, {
			:conditions => where,
			:order => 'exams.exam_no'
		});
		sites = ExamSite.find(:all, {
			:include => {:applicants => :exam},
			:conditions => where,
			:order => 'exam_sites.name',
			:group => 'exam_sites.id',
			:order => 'exam_sites.name'
		});		
		return exams, sites
	end
	
	include DbChangeHooks
	
end