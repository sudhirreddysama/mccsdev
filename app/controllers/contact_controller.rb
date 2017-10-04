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
    super
  end


end


