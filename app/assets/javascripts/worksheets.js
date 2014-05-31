var worksheetView;
var worksheet;
var worksheetToolbarView;

var Worksheet = Backbone.Model.extend({

	urlRoot: '/worksheets/',

	initialize: function() {
		this.on('change', this.updateOptions);
	},

	updateOptions: function() {

	}

});

var Visualization = Backbone.Model.extend({

});

var WorksheetView = Backbone.View.extend({

	el: '#storylytics-editor',

	keyboardEvents: {
		'command+s': 		'save',
		'ctrl+s': 			'save'
	},

	initialize: function() {
		this.listenTo(this.model, 'change', this.render);
		this.model.fetch();
	},

	render: function() {

		// Only render data if it is not undefined
		if (this.model.get('data') != undefined) {
			this.el.innerHTML = this.model.get('data');
		} else {
			this.el.innerHTML = 'Start creating your story here';
		}

	},

	// Save the document
	save: function(e) {

		// Override the browser default
		e.preventDefault();
		
		// Synchronize the data model with the server
		this.model.set({
			'data': this.el.innerHTML
		});

		// Send over changed data
		this.model.save();

	},

	// Insert an image into the document
	insertImage: function(imageURL) {
		this.el.focus();
		document.execCommand('insertHTML', false, '<img src="' + imageURL + '" />');
	}

});

var WorksheetToolbarView = Backbone.View.extend({

	el: '#storylytics-menu',

	events: {
		'click #addImage': 'addImage',
	},

	addImage: function() {
		var imageURL = prompt("Image URL?");
		worksheetView.insertImage(imageURL);
	}

});

/*

var storylyticsEditor;
var storylyticsMenu;

var VisualizationToolbar = Backbone.View.extend({

	el: '#storylytics-editor',

	initialize: function() {
		this.render();
	},

	render: function() {
		var template = _.template($('#visualization-toolbar').html(), {});
		document.execCommand('innerHTML', false, template);
		console.log('rendered');
	}

});

function StorylyticsEditor () {

	// Get the editor object
	this.editor = document.getElementById('storylytics-editor');

	// This function responds to click events within the editor
	this.clickEvent = function() {

		console.log('clickity');

	}

	// Insert at the current caret position
	this.insertElement = function() {

		document.execCommand('insertHTML', false, '<p>POOPY</p>');

	}

	// Insert visualization object
	this.insertVisualization = function() {

		var visualizationToolbar = new VisualizationToolbar();

		// Insert visualization into the current position
		//document.execCommand('insertHTML', false, elem.outerHTML);

	}

	// Register event listeners
	this.editor.addEventListener("click", this.clickEvent, false);

}

function StorylyticsMenu() {

	// Get the menu object
	var menu = document.getElementById('storylytics-menu');

	// Register add visualization event
	var addVisualization = document.getElementById('addVisualization');

	this.createVisualization = function(event) {

		event.preventDefault();
		storylyticsEditor.insertVisualization();

	}
	
	addVisualization.addEventListener("click", this.createVisualization, false);

}

// When the DOM is ready, instantiate an editor instance on the main window
domready(function() {

	// Initialize new instances of the editor and menu
	storylyticsEditor = new StorylyticsEditor();
	storylyticsMenu = new StorylyticsMenu();

	// Set up all keyboard listeners
	Mousetrap.bind(['command+s', 'ctrl+s'], function(e) {
		e.preventDefault();
		console.log('saved!');
	});

	Mousetrap.bind(['command+1'], function(e) {
		e.preventDefault();
		storylyticsEditor.insertVisualization();
	});

	// Change the default contentEditable element to the p tag
	document.execCommand('defaultParagraphSeparator', false, 'p');

});
*/
