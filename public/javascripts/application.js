
// parseFloat but returns 0 instead of NaN
function toFloat(v) {
	v = parseFloat(v);
	return (isNaN(v) ? 0 : v);
}



// Create a sortable table that posts the order to the given url.
function init_sortable_table(tbl, url) {
	Sortable.create($(tbl), {
		tag: 'tr', 
		handle: 'move',
		starteffect: function(tr) { $(tr).addClassName('busy-bg'); },
		endeffect: function(tr) {
			odd_even($A($(tbl).select('tr')));
			new Ajax.Request(url, {
				parameters: Sortable.serialize($(tbl), {tag: 'tr', name: 'order'}),
				onComplete: function() {
					$(tr).removeClassName('busy-bg');
				}
			});
		}
	});
}


// Add 'odd' and 'even' class names to a list of nodes.
function odd_even(nodes) {
	for(var i = 0; i < nodes.length; ++i) {
		cycle = (i + 1) % 2;
		$(nodes[i]).addClassName(cycle ? 'odd' : 'even');
		$(nodes[i]).removeClassName(cycle ? 'even' : 'odd');
	}
}


// Setup in-page tabs.
jQuery(function($) {
	
	var activate = function() {
		var a = $(this);
		var links = $(this).parent('.tabs').find('a');
		links.removeClass('active');
		links.each(function(i, link) {
			$($(link).attr('href')).hide();
		});
		$(this).addClass('active');
		$($(this).attr('href')).show();	
	}
	
	$('.tabs.inpage').each(function(i, tabs) {
		tabs = $(tabs);
		tabs.find('a').click(activate);		
		tabs.find('.active').click();
	});
	
	$('.toggler').each(function(i, grp) {
		var h4 = $(grp).find('h4');
		$(h4).click(function() {
			$(grp).toggleClass('hidden');
		});
	});
	
});



// Strip commas from certain numeric fields.
jQuery(function($) {
	var f = function(e) {
		var i = $(e);
		i.val(i.val().replace(',', ''));
	}
	$('.nocomma').change(function(e) { f(this); });
	$('.nocomma').each(function(i, e) { f(e); })
});


// Simple checkbox toggling of visual elements.
function chk_toggle(chk, el) {
	var flip = arguments[2];
	var tgl = function() {
		if(flip) {
			$(el)[$(chk).checked ? 'hide' : 'show']();
		}
		else {
			$(el)[$(chk).checked ? 'show' : 'hide']();
		}
	}
	$(chk).observe('change', tgl);
	return tgl;
}








// Set the value of a select element.
function set_select_value(v, e) {
	$(e).select('option').find(function(opt, i) {
		if(opt.readAttribute('value') == v) {
			e.selectedIndex = i
			return true;
		}
		return false;
	});
}













// Insert value in text area at cursor.
jQuery.fn.extend({
insertAtCaret: function(myValue){
  return this.each(function(i) {
    if (document.selection) {
      this.focus();
      sel = document.selection.createRange();
      sel.text = myValue;
      this.focus();
    }
    else if (this.selectionStart || this.selectionStart == '0') {
      var startPos = this.selectionStart;
      var endPos = this.selectionEnd;
      var scrollTop = this.scrollTop;
      this.value = this.value.substring(0, startPos)+myValue+this.value.substring(endPos,this.value.length);
      this.focus();
      this.selectionStart = startPos + myValue.length;
      this.selectionEnd = startPos + myValue.length;
      this.scrollTop = scrollTop;
    } else {
      this.value += myValue;
      this.focus();
    }
  })
}
});




// Capitalize input field.
function capitalize_input(i) {
	i.value = i.value.toString().toUpperCase();
}

// Make sure inputs with class="ucase" always have capitalized values. Also in CSS use input.ucase { text-transform: uppercase; }
jQuery(function($) {
	inputs = $('input.ucase, textarea.ucase');
	inputs.change(function(e) {
		capitalize_input(this);
	});
	inputs.each(function(i, e) {
		capitalize_input(e);
	});
})



// Auto enable "coolfieldset"
jQuery(function($) {
	$('.coolfieldset').coolfieldset({collapsed: true, animation: false});
});

// Popup select text fields.

jQuery(function($) {
	$('.popup-select-text').each(function(i, link) {
		link = $(link);
		link.click(function(e) {
			e.preventDefault();
			window.cb = function(val) {
				$(pop).dialog('close');
				$('#' + link.attr('id').substring(7)).val(val);
				pop = null;
			}
			var w = 800;
			var h = 500;
			var pop = $('<iframe src="' + link.attr('href') + '" />').dialog({
				title: 'Select Record',
				width: w,
				height: h,
				modal: true,
				overlay: {
					opacity: 0.8,
					background: 'black'
				},
				close: function() {
					pop = null;
				}
			}).width(w).height(h).dialog('option', 'position', 'center');
		});
	});
});



function enable_arrow_keys_for_table_inputs(col_count, opt) {

	(function($) {
	
		var typing = false;
		
		if(!opt) opt = {}
		
		$('.cell').focus(function(e) {
			this.select();
			typing = false;
		});
		
		var last_mouseup_id = null;
		$('.cell').mouseup(function(e) {
			var cell = $(this);
			var id = cell.attr('id');
			if(id != last_mouseup_id) {
				e.preventDefault();
			}
			else {
				typing = true;
			}
			last_mouseup_id = id;
		});
		
		$('.cell').blur(function(e) {
			last_mouseup_id = null;
		});
		
		$('.cell').change(function(e) {
			var cell = $(this);
			var id = cell.attr('id');
			var parts = id.split('-');
			var row = parseInt(parts[1]);
			var col = parseInt(parts[2]);			
			if(opt.change) opt.change(cell, id, row, col, cell.val());
			window.input_dirty = true;
		})
		
		$('.cell').keydown(function(e) {
			var cell = $(this);
			var id = cell.attr('id');
			var parts = id.split('-');
			var row = parseInt(parts[1]);
			var col = parseInt(parts[2]);
			var go = null;
			var caret = cell.caret();
			switch(e.which) {
				case 37: // left
					if(!typing || caret.start == 0) {
						if(col == 1) {
							go = $('#cell-' + (row - 1) + '-' + col_count);
						}
						else { 
							go = $('#cell-' + row + '-' + (col - 1));
						}
					}
 					break;
				case 38: // up
					go = $('#cell-' + (row - 1) + '-' + col);
					break;
				case 39: // right
					if(typing && !(caret.end == cell.val().length)) {
						break;
					}
				case 13: // return
					if(col == col_count) {
						go = $('#cell-' + (row + 1) + '-1');
					}
					else { 
 						go = $('#cell-' + row + '-' + (col + 1));
 					}
 					break;
				case 40: // down
					go = $('#cell-' + (row + 1) + '-' + col);
					break;
				default:
					typing = true;				
			}	
			if(go) {
				e.preventDefault();
				go.focus();
			}

		});
		
	})(jQuery);
	
}


