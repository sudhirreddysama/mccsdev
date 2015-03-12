module DbChangeHooks

	def save_db_change action, changed
		if !changed.empty?
			DbChange.create({
				:user => Thread.current[:current_user] ? Thread.current[:current_user].username : 'system',
				:action => action,
				:record => self,
				:changes_json => changed.to_json
			})	
		end
	end

	def save_db_change_create
		save_db_change 'new', changes
	end

	def save_db_change_update
		chg = changes.reject { |k, v| 
			v[0].blank? && v[1].blank? # Reject hanges from nil => ''
		}
		save_db_change 'edit', chg
	end
	
	def save_db_change_destroy
		save_db_change 'delete', attributes
	end

	def self.included(base)
    base.class_eval do
    	has_many :db_changes, :as => :record, :order => 'db_changes.created_at desc'
    	after_create :save_db_change_create
      before_update :save_db_change_update
      before_destroy :save_db_change_destroy
    end
  end

end