var storylyticsEditor;
var storylyticsMenu;

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

		// Construct a visualization object from the DOM
		var elem = document.createElement('div');
		elem.className = 'storylytics-element storylytics-visualization';

		// Construct a toolbar for the visualization

		// Insert visualization into the current position
		document.execCommand('insertHTML', false, elem.outerHTML);

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
