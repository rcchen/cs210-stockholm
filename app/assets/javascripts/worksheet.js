var storylyticsEditor;
var storylyticsMenu;

function StorylyticsEditor () {

	// Get the editor object
	var editor = document.getElementById('storylytics-editor');

	// This function responds to click events within the editor
	this.clickEvent = function() {

	}

	// Replace the selected text
	// See http://stackoverflow.com/questions/3997659/replace-selected-text-in-contenteditable-div
	this.replaceSelected = function(replacement) {
	   	
		var sel = window.getSelection();

		console.log(sel);

	}

	// Register event listeners
	editor.addEventListener("click", this.clickEvent, false);

}

function StorylyticsMenu() {

	// This function responds to the bold icon
	this.toggleBold = function() {

		// Get the selected text
		storylyticsEditor.replaceSelected('foobar');
	
	}

	// Get the menu object
	var menu = document.getElementById('storylytics-menu');

	// Get each of the buttons
	var bold = document.getElementById('bold');

	// Register event listeners
	bold.addEventListener("click", this.toggleBold, false);

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

	// Change the default contentEditable element to the p tag
	document.execCommand('defaultParagraphSeparator', false, 'p');

});
