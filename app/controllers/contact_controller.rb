class ContactController < CrudController

  def index
    @filter = get_filter({
                             :sort1 => 'contacts.lastname',
                             :dir1 => 'desc'
                         })
    @orders = [
        ['Last Name', 'contacts.lastname'],
        ['First Name', 'contacts.firstname']
    ]
    cond = get_search_conditions @filter[:search], {
        'contacts.lastname' => :like,
        'contacts.firstname' => :like
    }
    @opt = {
        :conditions => get_where(cond),
        :order => get_order_auto,
        :include => nil,
    }
    super
  end


end


