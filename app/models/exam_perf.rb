class ExamPerf < ActiveRecord::Base
	
	set_table_name 'exam_perfs'

	belongs_to :exam
	belongs_to :perf_test
	
	include DbChangeHooks
	
end