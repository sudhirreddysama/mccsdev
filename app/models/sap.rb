module SAP

	def self.logger
		Rails.logger
	end

	def self.employee_lookup_client
		Savon.client({
			:wsdl => 'http://sapdr1.monroecounty.gov:8000/sap/bc/srt/wsdl/flv_10002A111AD1/srvc_url/sap/bc/srt/rfc/sap/zhcm_ret_empno_ssn_sd/100/zhcm_ret_empno_ssn_sc/zhcm_ret_empno_ssn_sd?sap-client=100',
			#:wsdl => 'http://sapdr1.monroecounty.gov:8000/sap/bc/srt/wsdl/flv_10002A111AD1/srvc_url/sap/bc/srt/rfc/sap/zhcm_ret_empno_ssn_sd/100/zhcm_ret_empno_ssn_sc/zhcm_ret_empno_ssn?sap-client=100',
			:basic_auth => ['CONTRACKHQ', 'Monroe@01'],
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

end