$(function() {
	$('input.date').datepicker({changeMonth: true, changeYear: true}).attr('autocomplete', 'new-password');
	$('input.datetime').datetimepicker({changeMonth: true, changeYear: true, timeFormat: 'hh:mm tt'}).attr('autocomplete', 'new-password');
});

function agency_dept_div_params(params) {
	params.agency_id = obj_agency_id.val();
	params.department_id = obj_department_id.val();
	params.division_id = obj_division_id.val();
}

var init_org_ac = function(f, field, obj) {
	return init_autocomplete({
		input: f,
		params: function(p) {
			p.field = field
		},
		url: ROOT_PATH + 'vacancy_data/org_autocomplete',
		minLength: 0,
		item: function(i) {
			i.label = i[field] + ' - ' + i.organization;
			i.value = i[field];
		},
		resizeMenu: function() {
			this.menu.element.outerWidth(200);
		},
		select: (field != 'org_no' ? null : function(e, ui) {
			$(f).val(ui.item.value).effect('highlight').blur();
			if(obj) {
				$(obj.county_org_no).val(ui.item.county_org_no).effect('highlight');
				$(obj.cost_center).val(ui.item.cost_center).effect('highlight');
			}
		})
	});
}

var init_org_obj_ac = function(obj) {
	init_org_ac(obj.county_org_no, 'county_org_no', obj);
	init_org_ac(obj.org_no, 'org_no', obj);
	init_org_ac(obj.cost_center, 'cost_center', obj);
}

var set_position_fields_from_to = function(data_obj, fields_obj) {
	var i = data_obj;
	var obj = fields_obj;
	if(obj.position) obj.position.val(i.position).effect('highlight');
	if(obj.position_no) {
		obj.position_no.val(i.position_no).effect('highlight');
		obj.position_no.trigger('change');
	}
	if(obj.salary_group) obj.salary_group.val(i.salary_group).effect('highlight');
	if(obj.job_no) obj.job_no.val(i.job_no).effect('highlight');
	if(obj.cost_center) obj.cost_center.val(i.cost_center).effect('highlight');
	if(obj.org_no) obj.org_no.val(i.org_no).effect('highlight');
	if(obj.county_org_no) obj.county_org_no.val(i.county_org_no).effect('highlight');
	var flsat = obj.flsa_exempt_true;
	var flsaf = obj.flsa_exempt_false;
	if(flsat && flsaf) {
		if(i.flsa_exempt == 'E') {
			flsat.prop('checked', true);
		}
		else if(i.flsa_exempt == 'N') {
			flsaf.prop('checked', true);
		}
		else {
			flsat.prop('checked', false);
			flsaf.prop('checked', false);
		}	
	}
}

var init_position_ac = function(field, obj) {
	var f = obj[field];
	return init_autocomplete({
		input: f,
		url: ROOT_PATH + 'vacancy_data/autocomplete',
		minLength: 0,
		params: function(params) {
			agency_dept_div_params(params);
		},
		item: function(i) {
			i.label = i.position_no + ' ' + i.position;
			i.value = i[field];
		},
		select: function(e, ui) {
			var i = ui && ui.item;
			if(i) {
				set_position_fields_from_to(i, obj);
			}
			if(obj.cb) {
				obj.cb(i);
			}
			f.blur();
		},
		renderItem: function(ul, i) {
			return $('<li>')
				.append($('<div>').text(i.position_no + ' - ' + i.position))
				.append($('<div class="ac-extra">')
					.append(i.status ? '' : '<b style="color: #800;">VACANT</b> ')
					.append('<i>Grp:</i>&nbsp;').append($('<span>').text(i.salary_group + ' '))
					.append('<i>Org:</i>&nbsp;').append($('<span>').text(i.organization + ' '))
					.append('<i>Org#:</i>&nbsp;').append($('<span>').text(i.org_no + ' '))
					.append('<i>CC:</i>&nbsp;').append($('<span>').text(i.cost_center + ' '))
				)
				.appendTo(ul);
		}
	});
}

var init_position_obj_ac = function(obj) {
	init_position_ac('position', obj);
	init_position_ac('position_no', obj);
}

function init_work_sched_code_ac(f) {
	init_autocomplete({
		input: f,
		url: ROOT_PATH + 'form_county_hire/work_schedule_autocomplete',
		minLength: 0,
		item: function(i) {
			i.label = i.rule + ' - ' + i.text;
			i.value = i.rule;
		}
	});
}

// vacancy_obj, obj_vacancy_id, and set_vacancy_fields defined externally.
function init_vacancy_ac(f) {
	init_autocomplete({
		input: f,
		url: ROOT_PATH + 'vacancy/autocomplete',
		minLength: 0,
		params: function(params) {
			agency_dept_div_params(params);
		},
		item: function(i) {
			i.label = i.exec_approval_no;
			i.value = i.exec_approval_no;
		},
		select: function(e, ui) {
			f.blur();
			vacancy_obj = ui.item;
			set_vacancy_fields();
		},
		renderItem: function(ul, i) {
			return $('<li>')
				.append($('<div>').text((i.exec_approval_no || 'NA') + ' - ' + i.position))
				.append($('<div class="ac-extra">')
					.append('<i>Pos#:</i>&nbsp;')
					.append($('<span>').text(i.position_no + ' '))
					.append('<i>Grp:</i>&nbsp;')
					.append($('<span>').text(i.salary_group + ' '))
					.append('<i>Org#:</i>&nbsp;')
					.append($('<span>').text(i.org_no + ' '))
					.append('<i>CC:</i>&nbsp;')
					.append($('<span>').text(i.cost_center + ' '))
				)
				.appendTo(ul);
		}
	}).change(function(e) {
		var v = this.value;
		if(vacancy_obj && vacancy_obj.exec_approval_no != v) {
			vacancy_obj = null;		
			obj_vacancy_id.val('');
		}
	});
}

var cost_table_header, cost_table_lines, cost_rows;

var cost_visible_rows = function() {
	var last = 2;
	for(var i = 5; i >= 2; i--) {
		var l = cost_table_lines[i];
		if(l.cost_center.val() || l.order_no.val() || l.percent.val() || l.fund.val() || l.grant.val()) {
			last = i + 1;
			break;
		}
	}
	cost_rows.each(function(i, r) {
		$(r).toggle(i <= last);
	});
}
	
function init_cost_table(prefix) {
	for(var i = 0; i < 6; i++) {
		init_org_ac('#obj_' + prefix + '_cost_center' + (i + 1), 'cost_center');
	}
	cost_table_header = $('#cost-table-header');
	cost_table_lines = [];
	var cost_tbody = $('#cost-tbody');
	cost_rows = cost_tbody.find('tr');
	cost_rows.each(function(i, r) {
		var j = i + 1;
		cost_table_lines.push({
			cost_center: $('#obj_' + prefix + '_cost_center' + j),
			order_no: $('#obj_' + prefix + '_order_no' + j),
			percent: $('#obj_' + prefix + '_percent' + j),
			fund: $('#obj_' + prefix + '_fund' + j),
			grant: $('#obj_' + prefix + '_grant' + j)
		});
	});
	cost_tbody.on('change autocompletechange', function(e) { cost_visible_rows(); });
	$('#reload-cost').click(function(e) { 
		e.preventDefault();
		load_vacancy_cost_data();
	});
}

var cost_data_pos_no = '';
var load_vacancy_cost_data = function() {
	set_cost_data_pos_no(); // defined externally
	var pos_no = cost_data_pos_no;
	if(!pos_no) {
		return;
	}
	cost_table_header.addClass('busy-bg');
	$.ajax({
		url: ROOT_PATH + 'vacancy_data/vacancy_cost_data',
		data: {
			position_no: pos_no,
			agency_id: obj_agency_id.val(),
			department_id: obj_department_id.val(),
			division_id: obj_division_id.val()					
		},
		complete: function(xhr, status) {
			cost_table_header.removeClass('busy-bg');
		},
		success: function(data, status, xhr) {
			for(var i = 0; i < 6; i++) {
				var d = {};
				if(data && data[i]) {
					d = data[i];
				}
				l = cost_table_lines[i];
				l.cost_center.val(d.cost_center).effect('highlight');
				l.order_no.val(d.order_no).effect('highlight');
				l.percent.val(d.percentage).effect('highlight');
				l.fund.val(d.fund).effect('highlight');
				l.grant.val(d.grant).effect('highlight');
			}
			cost_visible_rows();
		},
		error: function(xhr, status, error) {
		}
	});
}








