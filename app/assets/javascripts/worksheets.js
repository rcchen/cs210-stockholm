var worksheetView;
var worksheet;
var worksheetToolbarView;
var footerView;

var Worksheet = Backbone.Model.extend({

	urlRoot: '/worksheets/',

	initialize: function() {
		this.on('change', this.updateOptions);
	},

	updateOptions: function() {

	}

});

var Visualization = Backbone.Model.extend({

	urlRoot: '/visualizations/'

});

var Dataset = Backbone.Model.extend({

	urlRoot: '/dataset/'

});

var FooterView = Backbone.View.extend({

	el: 'footer',

	events: {
		'change #visualization-dataset': 		'changeDataset',
	},

	changeDataset: function() {

		// Get the identifier
		var e = document.getElementById('visualization-dataset');
		var datasetIdentifier = e.options[e.selectedIndex].value;

		// Retrieve the corresponding dataset
		var dataset = new Dataset({
			'id': datasetIdentifier
		});

		// Load it
		dataset.fetch({
			success: function() {
				console.log(dataset.get('attrs'));
			}
		});

	}

});

var VisualizationView = Backbone.View.extend({

	initialize: function() {
		var _this = this;
		if (this.model.isNew()) {
			this.model.save(null, {
				success: function() {
					_this.render();
				}
			});			
		}
	},

	render: function() {

		var _this = this;

		// Load the template
		var template = _.template(document.getElementById('visualization-template').innerHTML, {
			'identifier': _this.model.get('identifier')
		});

		// Append the template into the editor window
		document.execCommand('insertHTML', null, template);

		// Manually add the contenteditable attribute
		var obj = document.getElementById(this.model.get('identifier'));
		obj.setAttribute('contenteditable', 'false');

		// Set the el to this object
		this.setElement(obj);

	},

	events: {
		'click': 			'focusVisualization', 
	},

	// Give focus to the visualization
	focusVisualization: function() {

		console.log('focusing');
		if (!$('footer').is(':visible')) {
			$('footer').slideToggle('slow');
		}

		footerView.changeDataset();
		
	}	

});

var WorksheetView = Backbone.View.extend({

	el: '#storylytics-editor',

	keyboardEvents: {
		'command+s': 		'save',
		'ctrl+s': 			'save',
		'command+e': 		'justifyCenter',
		'ctrl+e': 			'justifyCenter',
		'command+1': 		'insertVisualization', 
		'ctrl+1': 			'insertVisualization',
		'command+2': 		'insertImage', 
		'ctrl+2':  			'insertImage'
	},

	events: {
		'click': 			'disableEditBar'
	},

	initialize: function() {
		var _this = this;
		this.listenTo(this.model, 'change', this.render);
		this.model.fetch({
			success: function() {
				_this.el.innerHTML = _this.model.get('data');
			}
		});
	},

	render: function() {

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

	// Center justify text
	justifyCenter: function(e) {

		// Override the browser default
		e.preventDefault();

		// Execute justifyCenter
		document.execCommand('justifyCenter', false, null);

	},

	// Insert an image into the document
	// Currently inserts the image at the top of the document.
	insertImage: function(imageURL) {

		// Prompt for an image URL
		var imageURL = prompt("Image URL?");

		// If we get a URL, insert
		if (imageURL) {
		
			// Insert the image tag
			document.execCommand('insertImage', false, imageURL);

		}

	},

	// Insert a visualization into the document
	insertVisualization: function() {

		// Access the worksheet from here
		var _worksheet = worksheet;

		// Create a new instance of the visualization model
		var visualization = new Visualization();

		// Create a view backed by this visualization
		var visualizationView = new VisualizationView({
			model: visualization
		});

	},

	disableEditBar: function() {

	}

});

var WorksheetToolbarView = Backbone.View.extend({

	el: '#storylytics-menu',

	events: {
		'click #addImage': 'addImage',
	},

	addImage: function() {

		worksheetView.insertImage();

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
