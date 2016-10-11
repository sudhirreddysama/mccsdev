class CertApplicant < ActiveRecord::Base

	belongs_to :applicant
	belongs_to :cert
	belongs_to :cert_code
	belongs_to :person
	
	has_many :documents
	
	def date; 
		cert.certification_date; 
	end
	
	def self.appointed_from_other_cert_cron id = nil
		DB.query('
			select ca.id ca_id, ca2.id ca2_id from applicants a
			join cert_applicants ca on ca.applicant_id = a.id
				and ca.action_date <= date(now())
				' + (id ? 'and ca.id = ' + id.to_i.to_s : '') + '
			join app_statuses s on s.id = a.app_status_id	
				and s.appointed = 1
			join cert_codes cc on cc.id = ca.cert_code_id and cc.description != ""
			join certs c on c.id = ca.cert_id
				and c.completed_date is null
			join exams e on e.id = c.exam_id
			join exams e2 on if(e.continuous, e.current_exam_id = e2.current_exam_id, e.id = e2.id)
			join certs c2 on c2.exam_id = e2.id
				and c2.id != c.id
				and c2.completed_date is null
				and c2.certification_date <= date(now())
			join cert_applicants ca2 on ca2.cert_id = c2.id
			join applicants a2 on a2.id = ca2.applicant_id
				and a.person_id = a2.person_id
			left join cert_codes cc2 on cc2.id = ca2.cert_code_id 
				and cc2.description != ""
			where cc2.id is null
		').each_hash { |h|
			aoa ||= CertCode.find_by_code 'AOA'
			ca = CertApplicant.find(h.ca_id)
			ca2 = CertApplicant.find(h.ca2_id)
			logger.info "Setting Cert Code From CA #{ca.id} (#{ca.cert_id}) For CA #{ca2.id} (#{ca2.cert_id})"
			users = ca2.cert.agency ? ca2.cert.agency.get_users(ca2.cert.department) : []
			ca2.cert_code = aoa
			ca2.action_date = ca.action_date
			ca2.save
			if !users.empty?
				Notifier.deliver_cert_applicant_appointed users, ca2, ca
			end
		}
	end
	
	include DbChangeHooks
	
end