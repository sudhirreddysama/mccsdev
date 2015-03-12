class Hash
	
	# Allows hash keys to be accessed like methods
	#
	# myhash.mykey = 'bubba'
	# render :text => myhash.mykey
	#
	def method_missing meth, *args
  	m = meth.id2name
  	if m =~ /=$/
  		self[m[0...-1]] = (args.length < 2 ? args[0] : args)
    else
			self[m] || self[m.to_sym]
		end
	end
	
	#
	# id is depreciated anyway.
	#
	def id
		self['id'] || self[:id]
	end
	
	def id= value
		self['id'] = value
	end
	
	#
	# Shortcut!
	#
	def + h
		merge h
	end
	
	#
	# Get the first key
	#
	def first_key
		keys.first
	end
	
	#
	# Get the first value.
	#
	def first
		self[first_key]
	end
	
end