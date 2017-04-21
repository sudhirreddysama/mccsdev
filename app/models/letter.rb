class Letter < ActiveRecord::Base

	VARS = {
		'Exam/List' => [
			'exam.exam_no',
			'exam.title',
			'exam.established_date.short',
			'exam.established_date.long',
			'exam.valid_until.short',
			'exam.valid_until.long',
			'exam.salary',
			'exam.fee.two_decimals',
			'exam.fee.no_decimals',
			'exam.calculator',
			'exam.exam_length',
			'exam.given_at.short',
			'exam.given_at.long',
			'exam.given_at.time',
			'exam.deadline.short',
			'exam.deadline.long',
			'exam.deadline.time'
		],
		'Applicant' => [
			'person.first_name',
			'person.last_name',
			'person.full_name',
			'person.full_mailing_address',
			'person.full_mailing_address_inline',
			'person.full_residence_address',
			'person.full_residence_address_inline',
			'person.ssn_last4',
			'applicant.raw_score',
			'applicant.base_score',
			'applicant.veterans_credits',
			'applicant.other_credits',
			'applicant.final_score',
			'applicant.pos',
			'applicant.rank',
			'applicant.disapproval_reason',
			'applicant.site_name',
			'applicant.site_address',
			'applicant.site_address_inline',
			'applicant.perf_test1_name',
			'applicant.perf_test1_date',
			'applicant.perf_test1_time',			
			'applicant.perf_test2_name',
			'applicant.perf_test2_date',
			'applicant.perf_test2_time',
			'applicant.user1',
			'applicant.user2',
			'applicant.user3',
			'applicant.user4',
			'applicant.user5',
			'applicant.exam_date.short',
			'applicant.exam_date.long'
		],
		'Certification' => [
			'cert.title',
			'cert.job.name',
			'cert.department.name',
			'cert.agency.name',
			'cert.school_district.name',
			'cert.town.name',
			'cert.village.name',
			'cert.fire_district.name',
			'cert.certification_date.short',
			'cert.certification_date.long',
			'cert.salary_range',
			'cert.job_type',
			'cert.job_time'
		],
		'Web Post' => [
			'web.no',
			'web.name',
			'web.exam_date.short',
			'web.exam_date.long',
			'web.deadline.short',
			'web.deadline.long'
		],
		'User' => [
			'user.name',
			'user.fax',
			'user.email',
			'user.email2'
		]
	}

	validates_presence_of :name
	
	def label; name_was; end
	
	def self.apply txt, objs
	
		applicant = objs[:applicant]
		person = objs[:person]
		exam = objs[:exam]
		web = objs[:web_exam]
		cert = objs[:cert]
		user = objs[:user]
		
		exam = cert.exam if cert && !exam
		person = applicant.person if applicant && !person
		exam = applicant.exam if applicant && !exam
		exam = cert.exam if cert && !exam
		
		vars = []
		vars << 'Exam/List' if exam
		vars << 'Applicant' if applicant || person
		vars << 'Certification' if cert
		vars << 'Web Post' if web
		vars << 'User' if user
		
		vars.each { |scope|
			VARS[scope].each { |var|
				val = eval(var) rescue nil
				txt = txt.gsub("$$#{var}$$", nl2br_h(val))
			}
		}
		return txt
	end
	
	def self.current_date; Time.now.to_date; end
	
	def self.nl2br_h s
		ERB::Util.html_escape(s.to_s).to_s.gsub(/\n/, '<br />')
	end
	
	def deliver_after; nil; end
	
	include DbChangeHooks
	
end