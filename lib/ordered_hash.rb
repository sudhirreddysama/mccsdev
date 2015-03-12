class OrderedHash < Hash
	alias_method :store, :[]=
	alias_method :each_pair, :each

	def initialize
		@keys = []
	end

	def []=(key, val)
		@keys << key
		super
	end
	
	def delete(key)
		@keys.delete(key)
		super
	end
	
	def each
		@keys.each { |k| yield k, self[k] }
	end
	
	def each_key
		@keys.each { |k| yield k }
	end
	
	def each_value
		@keys.each { |k| yield self[k] }
	end
	
	attr :keys
	
end