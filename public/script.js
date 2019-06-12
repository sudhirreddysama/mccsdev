

// Date string converters.
var mdy2ymd = function(mdy) {
	var parts = mdy.split('/');
	return parts[2] + '-' + parts[0] + '-' + parts[1];
}
var ymd2mdy = function(ymd) {
	var parts = ymd.split('-');
	return parts[1] + '/' + parts[2] + '/' + parts[0];
}


function init_autocomplete(opts) {
	var input = $(opts.input);
	var ac_options = {
		source: function(request, response) {
			input.addClass('busy-bg');
			if(opts.params) {
				opts.params(request);
			}
			$.ajax({
				url: opts.url,
				data: request,
				complete: function(xhr, status) {
					input.removeClass('busy-bg');
				},
				success: function(data, status, xhr) {
					if(data.data) {
						data = data.data;
					}
					for(var i = 0; i < data.length; i++) {
						if(opts.item) {
							opts.item(data[i]);
						}
					}
					response(data);
				},
				error: function(xhr, status, error) {
				}
			});
		},
		select: function(e, ui) {
			if(opts.select) {
				opts.select(e, ui);
			}
			else {
				input.val(ui.item.value).effect('highlight').blur();
			}
			e.preventDefault();
		}
	}
	if(opts.minLength !== undefined) {
		ac_options.minLength = opts.minLength;
	}
	var ac = input.autocomplete(ac_options);
	if(opts.minLength === 0) {
		ac.focus(function(e) {
			$(this).autocomplete('search', '');
		})
	}
	if(opts.renderItem) {
		ac.data('ui-autocomplete')._renderItem = opts.renderItem;
	}
	if(opts.resizeMenu) {
		ac.data('ui-autocomplete')._resizeMenu = opts.resizeMenu;
	}
	input.autocomplete('instance').previous = input.val(); // Bug workaround. blur() on an un-touched autocomplete will trigger a change event.
	input.attr('autocomplete', 'new-password');
	return input;
}


function init_select2(opts) {
	var select = $(opts.select);
	var search_box = null;
	var clearing = false;
	var select2_opts = {
		tags: !!opts.tags,
		closeOnSelect: !select.prop('multiple'),
		allowClear: true,
		placeholder: opts.placeholder || ' ',
		ajax: {
			url: opts.url,
			data: function(params) {
				search_box.addClass('busy-bg');
				if(opts.params) {
					opts.params(params);
				}
				return params;
			},
			processResults: function(data) {				
				search_box.removeClass('busy-bg');
				var items = data.data || data;
				if(opts.processData) {
					var items = opts.processData(items);
				}
				for(var i = 0; i < items.length; i++) {
					//items[i].title = ' ';
					if(opts.item) {
						opts.item(items[i]);
					}
				}
				//select.empty();
				return {
					results: items,
					pagination: {
						more: data.pages > data.page
					}
				}
			}
		}
	}
	if(opts.templateResult) {
		select2_opts.templateResult = opts.templateResult;
	}
	select.select2(select2_opts).on("select2:unselecting", function(e) { 
		var opts = $(this).data('select2').options;
		opts.set('disabled', true);
		setTimeout(function() { opts.set('disabled', false); }, 1);
	});
	search_box = select.data('select2').$dropdown.find('input');
	return select;
}