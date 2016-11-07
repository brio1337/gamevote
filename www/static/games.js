var votesForm = document.getElementById('gamevotes');
var autosaveCheckbox = document.getElementById('autosave_check');

function adjustRankToNeighbors(evt) {
	// If the dropped item was from the unranked list, it doesn't have an input box, so create one.
	var item = evt.item;
	var itemInput = item.querySelector('input');
	itemInput.setAttribute('form', 'gamevotes');

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

	onVotesChanged();
}

function makeUnranked(evt) {
	var item = evt.item;
	item.querySelector('input').removeAttribute('form');
	unrankedSort.sort(unrankedSort.toArray().sort());
	onVotesChanged();
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

	onVotesChanged();
}

function onVotesChanged() {
	onFormChanged(votesForm, autosaveCheckbox.checked);
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

function onAutosaveChange(e) {
	onFormChanged(autosaveCheckbox.form, true);
	if (autosaveCheckbox.checked) checkSaveForm(votesForm);
}
autosaveCheckbox.addEventListener('change', onAutosaveChange);

votesForm.addEventListener('submit', onSubmit);

function onSubmit(e) {
	e.preventDefault();

	// cancel the last one and resave
	var form = e.target;
	var curSave = currentSavingForms[form.action];
	if (curSave) {
		if (curSave.xhr) {
			curSave.xhr.abort();
			delete curSave.xhr;
		}
		if (curSave.timer) {
			clearTimeout(curSave.timer);
			delete curSave.timer;
		}
	}
	onFormChanged(e.target, true);
}

function formDataToJSON(form) {
	var data = {};
	var formData = new FormData(form);
	for (var pair of formData.entries()) data[pair[0]] = pair[1];
	return JSON.stringify(data);
}

// keyed by form.action
var saveIntervalMilliseconds = 1000;
var currentSavingForms = {};

function getFormSaverForForm(form) {
	var saver = currentSavingForms[form.action];
	if (saver) return saver;
	return currentSavingForms[form.action] = {};
}

function checkSaveForm(form) {
	var formSaver = getFormSaverForForm(form);
	if (!formSaver.dirty || formSaver.xhr || formSaver.timer) return;

	formSaver.dirty = false;
	var xhr = formSaver.xhr = new XMLHttpRequest();
	xhr.open(form.method, form.action);
	xhr.setRequestHeader('Content-Type', 'application/json');
	xhr.addEventListener('load', onLoad);
	xhr.addEventListener('loadend', onLoadend);
	xhr.send(formDataToJSON(form));

	formSaver.timer = setTimeout(onDelayTimer, saveIntervalMilliseconds);

	function onLoad() {
		var xhr = formSaver.xhr;
		if (xhr.status >= 400) window.location = xhr.responseURL;
	}

	function onLoadend() {
		delete formSaver.xhr;
		checkSaveForm(form);
	}

	function onDelayTimer() {
		delete formSaver.timer;
		checkSaveForm(form);
	}
}

function onFormChanged(form, checkSave) {
	// save things in the background, keeping track of outstanding saves, and batching with a timer.
	var formSaver = getFormSaverForForm(form);
	formSaver.dirty = true;
	if (checkSave) checkSaveForm(form);
}

// winner fetcher
function fetchWinner() {
	var xhr = new XMLHttpRequest();
	xhr.open('get', '/winner');
	xhr.addEventListener('load', onLoadWinner);
	xhr.addEventListener('loadend', setTimeout.bind(null, fetchWinner, 5000));
	xhr.send();
}

function onLoadWinner(e) {
	var xhr = e.target;
	var winners = xhr.responseText.split('\n');
	if (winners.length <= 1) {
		document.getElementById('one-winner').style.display = 'block';
		document.getElementById('multiple-winners').style.display = 'none';
		document.getElementById('winner-game').textContent = winners.length === 1 ? winners[0] : 'No result';
	} else {
		document.getElementById('one-winner').style.display = 'none';
		document.getElementById('multiple-winners').style.display = 'block';
		var winnersDiv = document.getElementById('multiple-winners');
		var winnerDivs = winnersDiv.querySelectorAll('div');
		for (var i = 0; i < winnerDivs.length; i++) winnersDiv.removeChild(winnerDivs[i]);
		for (var i = 0; i < winners.length; i++) {
			var winnerDiv = document.createElement('div');
			winnerDiv.textContent = winners[i];
			winnersDiv.appendChild(winnerDiv);
		};
	}
}

fetchWinner();
