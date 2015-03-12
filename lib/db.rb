module DB

	# Bypasses all the ActiveRecord nonsense and lets you just execute a query. Variables can be easily escaped like so:
	#
	# query 'select * from whatever where id = %d and name = "%s" and some_float = "%f"', 1, 'bubba', 54.54
	#
	def self.query *args
		raw method('escape')[*args]
	end
	
	def self.raw q
		ActiveRecord::Base.connection.execute q
	end
	
	def self.esc s = ''
		ActiveRecord::Base.connection.quote_string(s.to_s)
	end
	
	def self.escape q, *args
		q % args.collect { |arg| ActiveRecord::Base.connection.quote_string arg.to_s }
	end
	
	def self.fetch_all res
		all = []
		res.each_hash { |r|
			all << r
		}
		all
	end
	
	def self.value(q, *args)
		res = query(q, *args).fetch_row
		res ? res[0] : nil
	end
	
end


