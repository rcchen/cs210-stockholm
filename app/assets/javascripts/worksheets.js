var worksheetView;
var worksheet;
var worksheetToolbarView;
var footerView;

function convertSymbolToText(symbol) {
	if (symbol == '<') {
		return 'less than (<)';
	} else if (symbol == '<=') {
		return 'less than or equal (<=)';
	} else if (symbol == '=') {
		return 'equals (=)';
	} else if (symbol == '>=') {
		return 'greater than or equal (>=)';
	} else if (symbol == '>') {
		return 'greater than (>)';
	} else if (symbol == '!=') {
		return 'not equal (!=)';
	} else if (symbol == 'Contains') {
		return 'contains';
	}
}

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

var VisualizationFilterView = Backbone.View.extend({

	el: '#storylytics-modals',

	events: {
		'click .filter-remove': 		'removeFilter', 
	},

	initialize: function(options) {

		this.options = options || {};
		console.log(this);
		this.render();

	},

	render: function() {

		var _this = this;

		var template = _.template(document.getElementById('visualization-filter-template').innerHTML, {
			'attribute': _this.options.attribute,
			'condition': convertSymbolToText(_this.options.condition),
			'value': _this.options.value
		});

		//this.setElement(template);

		$('#filters').append(template);

		return this;

	},

	removeFilter: function(ev) {

 		// Find the parent view
        var parentView = $(ev.target).closest('.filter');

	    // Remove it
        parentView.remove();

	}

});

var VisualizationSettingsView = Backbone.View.extend({

	el: '#storylytics-modals',

	events: {
		'change #visualization-dataset': 		'setDatasetAttributes',
		'click #add-filter': 					'addFilter', 
	},

	initialize: function() {

		this.bind("shown", this.setDatasetAttributes);
		this.bind("ok", this.saveAttributes);
		this.bind("hidden", this.teardown);

		_.bindAll(this, 'beforeRender', 'render', 'afterRender');
		var _this = this;
		this.render = _.wrap(this.render, function(render) {
			_this.beforeRender();
			render();
			_this.afterRender();
			return _this;
		});
	},

	beforeRender: function() {

	},

	render: function() {

		var _this  = this;

		// Load the template
		var template = _.template(document.getElementById('visualization-settings-template').innerHTML, {
			'identifier': _this.model.get('identifier')
		});
		
		this.$el.html(template);

		return this;

	},

	afterRender: function() {

	},

	// Set all the dataset attributes
	setDatasetAttributes: function() {

		var _this = this;

		var datasetIdentifier;
		if (_this.model.get('dataset') == null) {
			datasetIdentifier = $('#visualization-dataset').val();
		} else {
			datasetIdentifier = _this.model.get('dataset');
		}

		// Retrieve the corresponding dataset
		var dataset = new Dataset({
			'id': datasetIdentifier
		});

		// Load it
		dataset.fetch({
			success: function() {
				console.log(dataset);
				var $filters = $('#filter-attribute');
				$filters.empty();
				var attrs = [];
				dataset.get('attrs').forEach(function(element, index, array) {
					attrs.push(element.id);
					$filters.append($('<option></option>')
						.attr('value', element.id).text(element.id));
				});
				$('#visualization-keys').tagit({
					availableTags: attrs,
					showAutocompleteOnFocus:true
				});
				$('#visualization-values').tagit({
					availableTags: attrs,
					showAutocompleteOnFocus:true
				});
				// Add in any existing tags
				// TODO: Check to see if they are in the data set

				var chart_options = jQuery.parseJSON(_this.model.get('chart_options'));
				if (chart_options['key'] != null) {
					$('#visualization-keys').tagit('createTag', chart_options['key']);

					console.log(chart_options['value']);

					$.each(chart_options['value'], function(i, val) {
						$('#visualization-values').tagit('createTag', val)
					});
				}
			},
			error: function(collection, response, options) {
				console.log('failure');
				console.log(response);
			}
		});

	},

	// Save attributes
	saveAttributes: function(modal) {

		var dataset = $('#visualization-dataset').val();
		var chart = $('#visualization-type').val();
		var keys = $('#visualization-keys').tagit('assignedTags');
		var values = $('#visualization-values').tagit('assignedTags');

		var obj = {};

		if (chart == 'bar' || chart == 'line' || chart == 'pie') {

			obj = {
				'key': keys[0],
				'value': values
			};

		}

		// Set and save
		this.model.set('dataset', dataset);
		this.model.set('chart_type', chart);
		this.model.set('chart_options', obj);
		this.model.save();

		console.log(this.model);

		// Remove the modal
		modal.close();

	},

	// Add a filter
	addFilter: function() {

		var attribute = $('#filter-attribute').val();
		var condition = $('#filter-condition').val();
		var value = $('#filter-value').val();

		var filterView = new VisualizationFilterView({
			'attribute': attribute,
			'condition': condition,
			'value': value
		});

	},

	teardown: function() {
		$('#storylytics-editor').after('<div id="storylytics-modals"></div>');
	}

});

var VisualizationView = Backbone.View.extend({

	initialize: function() {
		var _this = this;
		if (this.model.get('id') == undefined) {
			this.model.save(null, {
				success: function() {
					_this.render();
				}
			});			
		} else {
			this.model.fetch({
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

	// Handle focus to the visualization
	focusVisualization: function() {

		var _this = this;
		_this.model.fetch({
			success: function() {

				var visualizationSettings = new VisualizationSettingsView({
					model: _this.model
				});

				console.log(visualizationSettings);

				var visualizationSettingsTitle = 'Settings for ' + visualizationSettings.model.get('identifier');

				var modal = new Backbone.BootstrapModal({
					animate: true,
					escape: false,
					title: visualizationSettingsTitle,
					content: visualizationSettings
				}).open();

			}
		});

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

	initialize: function() {
		var _this = this;
		this.listenTo(this.model, 'change', this.render);
		this.model.fetch({
			success: function() {
				_this.el.innerHTML = _this.model.get('data');
				_this.activateVisualization();
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

	// Activate all existing visualizations
	activateVisualization: function() {

		// Get all instances of the Storylytics visualization
		$('.storylytics-visualization').each(function() {

			// Get the ID attribute
			var identifier = $(this).attr('id');

			// Generate the new object
			var visualization = new Visualization({
				'id': identifier
			});

			// Create a view backed by that model
			var visualizationView = new VisualizationView({
				model: visualization
			});

		});

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
