class VacancyCostData < ActiveRecord::Base
	
	belongs_to :vacancy_data, :primary_key => 'position_no', :foreign_key => 'position_no'
	
	set_table_name 'vacancy_cost_data'
	
	def autocomplete_json_data
		{
			:position_no => position_no,
			:sequence => sequence,
			:company_code => company_code,
			:business_area => business_area,
			:conrolling_area => conrolling_area,
			:object_type => object_type,
			:cost_center => cost_center,
			:order_no => order_no,
			:wbs_element => wbs_element,
			:fin_manage_area => fin_manage_area,
			:fund => fund,
			:functional_area => functional_area,
			:grant => grant,
			:funds_center => funds_center,
			:service_type => service_type,
			:service_category => service_category,
			:segment => segment,
			:budget_period => budget_period,
			:percentage => percentage
		}	
	end
	
end