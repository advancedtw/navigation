﻿function PersonViewModel(stateController) {
	var self = this;
    self.stateController = stateController;
	self.id = ko.observable();
	self.name = ko.observable();
	self.personName = ko.observable();
	self.dateOfBirth = ko.observable();
	self.people = ko.observableArray();
	self.sortExpression = ko.observable();
	self.previous = ko.observable();
	self.next = ko.observable();
	self.last = ko.observable();
	self.totalCount = ko.observable();
	self.nameChange = function () {
		var data = stateController.stateContext.includeCurrentData({ name: self.name(), startRowIndex: null });
		stateController.refresh(data);
	};

	var personStates = stateController.dialogs.person.states;
	personStates.list.navigated = function (data) {
		var people = personSearch.search(data.name, data.sortExpression);
		var totalRowCount = people.length;
		people = people.slice(data.startRowIndex, data.startRowIndex + data.maximumRows);
		self.name(data.name);
		self.people(people);
		self.sortExpression(data.sortExpression.indexOf('DESC') === -1 ? 'Name DESC' : 'Name');
		self.previous(Math.max(0, data.startRowIndex - data.maximumRows));
		self.next(data.startRowIndex + data.maximumRows);
		var remainder = totalRowCount % data.maximumRows;
		self.last(remainder != 0 ? totalRowCount - remainder : totalRowCount - data.maximumRows);
		if (self.next() >= totalRowCount) {
			self.next(data.startRowIndex);
			self.last(data.startRowIndex);
		}
		self.totalCount(totalRowCount);
	};
	personStates.details.navigated = function (data) {
		self.id(data.id);
		var person = personSearch.getDetails(data.id);
		self.personName(person.name);
		self.dateOfBirth(person.dateOfBirth);
	};
	personStates.details.dispose = function () { self.id(null); };
};

var stateController = new Navigation.StateController([
	{ key: 'person', initial: 'list', states: [
		{ key: 'list', route: '{startRowIndex}/{maximumRows}/{sortExpression}', defaults: { startRowIndex: 0, maximumRows: 10, sortExpression: 'Name'}, trackTypes: false, title: 'Person Search', transitions: [
			{ key: 'select', to: 'details' }]},
		{ key: 'details', route: 'person', defaultTypes: { id: 'number' }, trackTypes: false, title: 'Person Details' }]}
]);
//stateController.historyManager.replaceQueryIdentifier = true;
ko.applyBindings(new PersonViewModel(stateController));
stateController.start();
