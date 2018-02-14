class ContactController < CrudController

  def index
    @filter = get_filter({
			:sort1 => 'contacts.lastname',
			:dir1 => 'desc'
		})
    @orders = [
			['Last Name', 'contacts.lastname'],
			['First Name', 'contacts.firstname'],
			['Department', 'departments.name']
    ]
    cond = get_search_conditions @filter[:search], {
			'contacts.lastname' => :like,
			'contacts.firstname' => :like,
			'departments.name' => :like
    }
    @opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => :department,
    }
		@export_fields = %w{id agency_id agency.name lastname firstname lastname_clean firstname_clean title email phone fax primary department_id department.name organization_name address address2 city state zip provisional_contact}
    super
  end


end


