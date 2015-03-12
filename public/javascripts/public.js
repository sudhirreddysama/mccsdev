var toggle_info;

(function($) {
	
	toggle_info = function(link) {
		link = $(link);
		var parts = link.attr('id').split('-');
		var which = parts[2];
		var id = parts[1];
		$(['notes', 'activity', 'residency']).each(function(i, label) {				
			if(label != which) {
				$('#obj-' + id + '-' + label).hide();
				$('#link-' + id + '-' + label).removeClass('open');
			}
		});
		$('#obj-'+ id + '-' + which).toggle();
		link.toggleClass('open');
	}

})(jQuery);