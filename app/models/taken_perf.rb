class TakenPerf  < ActiveRecord::Base

	set_table_name 'taken_perfs'

	belongs_to :exam
	belongs_to :applicant
	belongs_to :person
	belongs_to :perf_code
	belongs_to :exam_perf
	belongs_to :perf_test
	
	def result_code; perf_code.code if perf_code; end
	def result_code= v; self.perf_code = PerfCode.find_by_code v; end
	
	def create_app_update
		if applicant && perf_code_id_changed?
			c1 = perf_code_id_was ? PerfCode.find(perf_code_id_was).label : 'BLANK'
			c2 = perf_code ? perf_code.label : 'BLANK'
			e = perf_test ? perf_test.name : 'UNKOWN PERFORMANCE TEST'
			au = applicant.app_updates.create({
				:user_id => Thread.current[:user_id],
				:text => "#{e}: Result changed from #{c1} to #{c2}."
			})
		end
	end
	before_save :create_app_update
	
	include DbChangeHooks
	
end