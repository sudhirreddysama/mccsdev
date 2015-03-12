/*
Copyright (c) 2003-2011, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/




CKEDITOR.stylesSet.add('my_styles', [
	{name: 'Inline Variable', element: 'span', attributes: {'class': 'ivar ivar-N'}},
	{name: 'Block Variable', element: 'div', attributes: {'class': 'bvar bvar-N'}},
	{name: 'Inline Option', element: 'span', attributes: {'class': 'iopt iopt-N'}},
	{name: 'Block Option', element: 'div', attributes: {'class': 'bopt bopt-N'}}
]);

CKEDITOR.editorConfig = function( config )
{
	// Define changes to default configuration here. For example:
	// config.language = 'fr';
	// config.uiColor = '#AADC6E';
	
	
	
	config.filebrowserBrowseUrl = '/elfinder/elfinder.php.html';
	
	
	config.toolbar = 'MyToolbar';
	config.stylesSet = 'my_styles';
    config.toolbar_MyToolbar =
    [
        ['Source','Maximize','-','Cut','Copy','Paste','PasteText','PasteFromWord'],
        ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
        ['Image','Table','HorizontalRule','SpecialChar'],
        ['Styles','Format'],
        ['Bold','Italic','Strike'],
        ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
        ['Link','Unlink','Anchor'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock']
    ];	
    
		config.toolbar_DeadSimple =
    [
        /*['Source','Bold','Italic','Strike','Format','RemoveFormat'],
        ['NumberedList','BulletedList','Outdent','Indent','Blockquote']*/
    ];
	
		config.skin = 'v2';
		config.width = 700;
		config.height = 200;
		/*config.enterMode = CKEDITOR.ENTER_DIV;*/

	
};


