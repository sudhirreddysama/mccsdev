module SAP

	SOAP_AUTH = ['CONTRACKHQ', 'Monroe@01']

	def self.logger
		Rails.logger
	end

	def self.employee_lookup_client
		Savon.client({
			:wsdl => 'http://sapdr1.monroecounty.gov:8000/sap/bc/srt/wsdl/flv_10002A111AD1/srvc_url/sap/bc/srt/rfc/sap/zhcm_ret_empno_ssn_sd/100/zhcm_ret_empno_ssn_sc/zhcm_ret_empno_ssn_sd?sap-client=100',
			#:wsdl => 'http://sapdr1.monroecounty.gov:8000/sap/bc/srt/wsdl/flv_10002A111AD1/srvc_url/sap/bc/srt/rfc/sap/zhcm_ret_empno_ssn_sd/100/zhcm_ret_empno_ssn_sc/zhcm_ret_empno_ssn?sap-client=100',
			:basic_auth => SOAP_AUTH,
			:soap_version => 2
		})
	end

	def self.employee_lookup opt = {}
		client = employee_lookup_client
		res = {}
		begin
			data = {'IV_SSN' => opt.ssn.to_s.gsub(/[^\d]/, '')}
			request = client.operation(:zhcm_ret_prnum_int).build({:message => data})
			logger.info '------'
			logger.info request.pretty
			response = client.call(:zhcm_ret_prnum_int, {:message => data})
			logger.info response.http.body
			r = response.body[:zhcm_ret_prnum_int_response]
			code = r[:ev_ret_code]
			if code == 'S'
				res = r[:et_hr_act][:item]
				res = res.max_by { |i| i[:start_date] } if res.is_a?(Array)
				res[:success] = true
				res.delete :ssn
			else
				res[:success] = false
				res[:errors] = [r[:ev_message]]
			end
		rescue
			logger.info $!.inspect
			res[:success] = false
			res[:errors] = ['Invalid data submitted to SAP.']
		end
		return res
	end
	
	def self.submit_new_hire_client
		Savon.client({
			:wsdl => 'http://sapdr1.monroecounty.gov:8000/sap/bc/srt/wsdl/flv_10002A111AD1/srvc_url/sap/bc/srt/rfc/sap/zhcm_prehire_wsdl/100/zws_hcm_prehire_wsdl/zws_hcm_prehire_wsdl?sap-client=100',
			:basic_auth => SOAP_AUTH,
			:soap_version => 2
		})
	end
	
	def self.submit_new_hire o
		client = submit_new_hire_client
		res = {}
#		begin
			#SAP.submit_new_hire(FormCountyHire.find(158))
			c = o.classification.blank? ? nil : JobClass.find_by_description(o.classification)
			s = o.civil_service_status.blank? ? nil : JobStatus.find_by_code(o.civil_service_status)
			
			data = {
				'IsEmp' => {
					'SapId' => o.rehire_sap_no,
					'FristName' => o.first_name.to_s,
					'LastName' => o.last_name.to_s,
					'MiddleName' => o.middle_name.to_s,
					'Ssn' => o.ssn.to_s.gsub(/\D/, ''),
					'Gender' => o.gender == 'M' ? 1 : o.gender == 'F' ? 2 : '',
					'BirthDate' => o.birth_date ? o.birth_date.strftime('%Y%m%d') : '',
					'PosId' => o.position_no.to_s,
					'SapOrg' => o.org_no.to_s,
					'Zzclass' => c ? c.sap_code : '',
					'Zzstatus' => s ? s.sap_code : '',
					'HStreet' => [o.address, o.address2].reject(&:blank?) * ' ',
					'HCity' => o.address_city.to_s,
					'HState' => o.address_state.to_s,
					'HZipCode' => o.address_zip.to_s,
					'HPhoneNum' => o.phone.to_s.gsub(/\D/, ''),
					'CellPhone' => o.phone2.to_s.gsub(/\D/, ''),
					'MStreet' => [o.mail_address, o.mail_address2].reject(&:blank?) * ' ',
					'MCity' => o.mail_city.to_s,
					'MState' => o.mail_state.to_s,
					'MZipCode' => o.mail_zip.to_s,
					'WorkScCode' => o.work_schedule_code.to_s,
					'SalGroup' => o.salary_group.to_s,
					'SalStep' => o.salary_step.to_s,
					'HourlyRate' => '%.2f' % o.hourly_rate.to_s.gsub(/[^\d.]/, '').to_f,
					'EMail' => o.email,
					'THireDate' => o.effective_date ? o.effective_date.strftime('%Y%m%d') : '',
				}			
			}
			request = client.operation(:zhcm_prehire_interface).build({:message => data})
			logger.info '------'
			logger.info request.pretty
			p request.pretty
			response = client.call(:zhcm_prehire_interface, {:message => data})
			logger.info response.http.body
			p response.http.body
			r = response.body[:zhcm_prehire_interface_response]
			ret = r[:es_return]
			msg = ret[:msg]
			#if code == 'S'
			#	res = r[:et_hr_act][:item]
			#	res = res.max_by { |i| i[:start_date] } if res.is_a?(Array)
			#	res[:success] = true
			#	res.delete :ssn
			#else
			#	res[:success] = false
			#	res[:errors] = [r[:ev_message]]
			#end
			res[:msg] = msg
#		rescue
#			logger.info $!.inspect
			#res[:success] = false
			#res[:errors] = ['Invalid data submitted to SAP.']
#			res[:msg] = 'Invalid data submitted to SAP.'
		#end
		return res
	end

end