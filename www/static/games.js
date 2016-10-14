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
}

function makeUnranked(evt) {
	var item = evt.item;
	item.removeChild(item.querySelector('input'));
	unrankedSort.sort(unrankedSort.toArray().sort());
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

function onSaved() {
}

function onSaveError() {
}

function onSubmit(e) {
	e.preventDefault();

	var data = {};
	var gameEntries = document.querySelectorAll('#theList .game-entry');
	for (var i = 0; i < gameEntries.length; i++) {
		data[gameEntries[i].dataset.id] = gameEntries[i].dataset.vote;
	}

	var req = new XMLHttpRequest();
	req.addEventListener('load', onSaved);
	req.addEventListener('error', onSaveError);
	req.open('POST', '/games');
	req.setRequestHeader('Content-Type', 'application/json');
	req.send(JSON.stringify(data));
}

document.querySelector('form').addEventListener('submit', onSubmit, false);
