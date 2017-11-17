class TableFormBuilder < ActionView::Helpers::FormBuilder    

	
	def submit(value = "Submit", options = {})
		return '' if @noform
		super(value, options)
	end

	def text_field(method, options = {})
		options[:readonly] = true if @noform
 		super(method, options)
	end
	
	def password_field(method, options = {})
		options[:readonly] = true if @noform
		super(method, options)
	end
	
	def hidden_field(method, options = {})
		super(method, options)
	end
	
	def file_field(method, options = {})
		options[:readonly] = true if @noform
		super(method, options)
	end
	
	def text_area(method, options = {})
		options[:readonly] = true if @noform
		super(method, options)
	end
	
	def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
		options[:disabled] = true if @noform
		super(method, options, checked_value, unchecked_value)
	end
	
	def radio_button(method, tag_value, options = {})
		options[:disabled] = true if @noform
		super(method, tag_value, options)
	end
	
	def select(method, choices, options = {}, html_options = {})
		html_options[:disabled] = true if @noform
		super(method, choices, options, html_options)
	end
	
	def grouped_collection_select(method, collection, group_method, group_label_method, option_key_method, option_value_method, options = {}, html_options = {})
		html_options[:disabled] = true if @noform
		super(method, collection, group_method, group_label_method, option_key_method, option_value_method, options, html_options)
	end
	
	def calendar_date_select(method, options = {})
		options[:readonly] = true if @noform
		#if @noform
		#	text_field method, options
		#else
			super method, options
		#end
	end
	
	attr :noform, true
	
	def tr_text_field(method, options = {})
		options[:size] ||= 60
		options[:readonly] = true if @noform
		tr method, text_field(method, trim_opts(options)), options
	end
	
	def tr_password_field(method, options = {})
		options[:size] ||= 60
		options[:readonly] = true if @noform
		tr method, password_field(method, trim_opts(options)), options
	end
	
	def tr_hidden_field(method, options = {})
		tr method, hidden_field(method, trim_opts(options)), options
	end
	
	def tr_file_field(method, options = {})
		options[:readonly] = true if @noform
		tr method, file_field(method, trim_opts(options)), options
	end
	
	def tr_text_area(method, options = {})
		options[:size] ||= '60x4'
		options[:readonly] = true if @noform
		tr method, text_area(method, trim_opts(options)), options
	end
	
	def tr_check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
		options[:disabled] = true if @noform
		tr method, check_box(method, trim_opts(options), checked_value, unchecked_value), options
	end
	
	def tr_radio_button(method, tag_value, options = {})
		options[:disabled] = true if @noform
		tr method, radio_button(method, tag_value, trim_opts(options)), options
	end
	
	def tr_submit(value = 'Submit', options = {})
		return '' if @noform
		tr nil, submit(value, trim_opts(options)), options
	end
	
	def tr_select(method, select_opts, options, opt2 = {})
		options[:disabled] = true if @noform
		tr method, select(method, select_opts, trim_opts(options), opt2), options
	end
	
	def tr_grouped_collection_select(method, collection, group_method, group_label_method, option_key_method, option_value_method, options = {}, html_options = {})
		options[:disabled] = true if @noform
		tr method, grouped_collection_select(method, collection, group_method, group_label_method, option_key_method, option_value_method, trim_opts(options), html_options), options
	end
	
	def tr_calendar_date_select(method, options = {})
		options[:readonly] = true if @noform
		tr method, calendar_date_select(method, trim_opts(options)), options
	end
	
	def tr_check(method, options = {})
		options[:disabled] = true if @noform
		'<tr>' +
			'<th class="nobr">' +
				options[:label].to_s +
				(options[:req] ? ' <span class="req">*</span>' : '') +
			'</th>' +
			'<td>' +
				'<label for="' + object_name.to_s + '_' + method.to_s + '">' + check_box(method, trim_opts(options)) + ' ' + options[:text].to_s + '</label>' +
				options[:after].to_s +
				(options[:help].nil? ? '' : '<div class="help">' + options[:help].to_s + '</div>') +
			'</td>' +
		'</tr>'
	end
	
	def tr(method, field, options = {})
		'<tr class="' + (options[:tr_class] ? options[:tr_class].to_s + ' ' : '' ) + err(method) + '">' +
			'<th class="nobr">' + 
				((method.nil? or options[:label].blank?) ? '' : label(method, options[:label].to_s + ':')) +
				(options[:req] ? ' <span class="req">*</span>' : '') +
			'</th>' +
			'<td>' + 
				options[:before].to_s +
				field + 
				options[:after].to_s +
				(options[:help].nil? ? '' : '<div class="help">' + options[:help].to_s + '</div>') +
			'</td>' + 
		'</tr>'
	end
	
	def err? method
		begin
			e = @template.instance_variable_get("@#{@object_name}").errors
			method2 = method.to_s.sub('_id', '')
			return e[method].present? || e[method2].present?
		rescue
			return false
		end
	end
	
	def err method
		return err?(method) ? 'err' : '' 
	end
	
	def trim_opts opts
		o = opts.clone
		o.delete :label
		o.delete :help
		o.delete :text
		return o
	end
	
end
