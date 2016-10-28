var votesForm = document.querySelector('#gamevotes');

function adjustRankToNeighbors(evt) {
	// If the dropped item was from the unranked list, it doesn't have an input box, so create one.
	var item = evt.item;
	var itemInput = item.querySelector('input');
	if (!itemInput) {
		itemInput = document.createElement('input');
		itemInput.type = 'number';
		item.appendChild(itemInput);
	}

	var newVal;
	var prevItem = item.previousElementSibling;
	var prevInput = prevItem && prevItem.querySelector('input');
	if (!prevInput) {
		newVal = 1000;
	} else {
		var nextItem = item.nextElementSibling;
		var nextInput = nextItem && nextItem.querySelector('input');
		if (!nextInput) {
			newVal = 0;
		} else {
			var maxVal = Number(prevInput.value);
			var minVal = Number(nextInput.value);
			newVal = Math.round((maxVal + minVal) / 2);
		}
	}
	itemInput.value = newVal;
	item.dataset.vote = newVal;

	onFormChanged(votesForm);
}

function makeUnranked(evt) {
	var item = evt.item;
	item.removeChild(item.querySelector('input'));
	unrankedSort.sort(unrankedSort.toArray().sort());
	onFormChanged(votesForm);
}

function onInputBlur(evt) {
	var input = evt.target;
	var gameEntry = input.parentNode;
	var newVal = Number(input.value);
	gameEntry.dataset.vote = newVal;

	// does it need to move up?
	var checkItem = gameEntry, checkVote, moveTo;
	while ((checkItem = checkItem.previousElementSibling) && (checkVote = checkItem.dataset.vote)) {
		if (newVal > Number(checkVote)) moveTo = checkItem;
		else break;
	}
	if (moveTo) {
		gameEntry.parentNode.insertBefore(gameEntry, moveTo);
	}

	// does it need to move down?
	checkItem = gameEntry; moveTo = null;
	while ((checkItem = checkItem.nextElementSibling) && (checkVote = checkItem.dataset.vote)) {
		if (newVal < Number(checkVote)) moveTo = checkItem;
		else break;
	}
	if (moveTo) {
		gameEntry.parentNode.insertBefore(gameEntry, moveTo.nextElementSibling);
	}

	onFormChanged(votesForm);
}

var rankedSort = Sortable.create(document.getElementById('theList'), {
	group: 'games',
	animation: 250,
	chosenClass: 'sortable-chosen',
	handle: 'span',
	onUpdate: adjustRankToNeighbors,
	onAdd: adjustRankToNeighbors,
});

var unrankedSort = Sortable.create(document.getElementById('unrankedList'), {
	group: 'games',
	sort: false,
	onAdd: makeUnranked,
});

function onAjaxLoad(e) {
	var xhr = e.target;
	if (xhr.status === 401) window.location = xhr.responseURL;
}

function submitFormAsJSON(form, data, onLoadend) {
	var req = new XMLHttpRequest();
	req.open(form.method, form.action);
	req.setRequestHeader('Content-Type', 'application/json');
	req.addEventListener('loadend', onLoadend);
	req.addEventListener('load', onAjaxLoad);
	req.send(JSON.stringify(data));
	return req;
}

function onSubmit(e) {
	e.preventDefault();

	// cancel the last one and resave
	var form = e.target;
	var curSave = currentSavingForms[form.action];
	if (curSave) {
		curSave.lastStart = 0;
		if (curSave.xhr) {
			curSave.xhr.abort();
			delete curSave.xhr;
		}
		if (curSave.timer)
			clearTimeout(curSave.timer);
			delete curSave.timer;
	}
	onFormChanged(e.target);
}

function onAutoSaveChange(e) {
	var autosaveCheckbox = e.target;
	submitFormAsJSON(autosaveCheckbox.form, {autosave: autosaveCheckbox.checked});
}

votesForm.addEventListener('submit', onSubmit, false);
document.querySelector('#autosave_check').addEventListener('change', onAutoSaveChange, false);


// autosave!
function autosaveNow(form, onLoadend) {
	var data = {};
	var gameEntries = document.querySelectorAll('#theList .game-entry');
	for (var i = 0; i < gameEntries.length; i++) {
		var entryData = gameEntries[i].dataset;
		data[entryData.id] = entryData.vote;
	}
	submitFormAsJSON(form, data, onLoadend);
}

// keyed by form.action
var saveIntervalMilliseconds = 1000;
var currentSavingForms = {};

function onFormChanged(form) {
	// called any time a vote changes.
	// saves things in the background.
	var curSave = currentSavingForms[form.action] || (currentSavingForms[form.action] = {});
	curSave.dirty = true;
	checkSaveForm();

	function checkSaveForm() {
		if (!curSave.dirty || curSave.xhr || curSave.timer) return;

		curSave.dirty = false;
		curSave.xhr = autosaveNow(form, function() {
			delete curSave.xhr;
			checkSaveForm();
		});
		curSave.timer = setTimeout(function() {
			curSave.timer = null;
			checkSaveForm();
		}, saveIntervalMilliseconds);
	}
}
