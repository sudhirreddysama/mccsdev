class AppointmentController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'appointments.appointed_date',
			:dir1 => 'desc'
		})
		@orders = [
			['ID', 'appointments.id'],
			['Appointed Date', 'appointments.appointed_date'],
			['Last Name', 'people.last_name'],
			['First Name', 'people.first_name'],
			['Title', 'jobs.name'],
			['Department', 'departments.name'],
			['Agency', 'agencies.name'],
			['Exam No.', 'exams.exam_no'],
		]
		cond = get_search_conditions @filter[:search], {
			'appointments.id' => :left,
			'people.first_name' => :like,
			'people.last_name' => :like,
			'jobs.name' => :like,
			'departments.name' => :like,
			'agencies.name' => :like,
			'exams.exam_no' => :like,
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => [:job, :person, :agency, :department, :exam]
		}
		super
	end

end