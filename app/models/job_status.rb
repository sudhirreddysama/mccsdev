class JobStatus < ActiveRecord::Base

	def self.code_select_options old_val, txt = :name
		cond = old_val.blank? ? 'active = 1' : DB.escape('active = 1 or code = "%s"', old_val)
		opts = JobStatus.find(:all, :order => 'sort', :conditions => cond).map { |o|
			[o.send(txt), o.code]
		}
		opts = [[old_val, old_val], *opts] if !old_val.blank? && !opts.rassoc(old_val)
		opts
	end

end