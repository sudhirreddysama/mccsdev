class WebExamPrice < ActiveRecord::Base
	
	set_table_name 'hr_apply_online.exam_prices'
	
	belongs_to :web_exam, :foreign_key => 'exam_id'
	
end