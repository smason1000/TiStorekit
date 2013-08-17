// Include the JS UI helpers.
// You can roll your own UI if you like and use the storekit module directly.
// Or include this helper library, modify it or overwrite any UI building functions.

var storekit_helper = require('storekit');

// open a single window
var window = Ti.UI.createWindow({
	backgroundColor:'white'
});

var start = Ti.UI.createButton({
	top: 20,
	left: 20,
	right: 20,
	color:'#222',
	title:'Start Checkout Flow',
	textAlign:'center',
	height: 34
});

window.add(start);

start.addEventListener("click", function (e) {
	storekit_helper.startCheckout({
		uidebug: false,
		identifiers: ["biz.pointersoft.shottracker"],
		restoreDetails: "You should do this stuff to restore your purchases.",
		success: function (product) {
			alert("TiStorekit.startCheckout.win - made purchase");
		},
		closed: function () { // Called when the checkout ends.
			alert("TiStorekit.startCheckout.closed");
		},
		error: function (e) { // There was an error.
			alert("TiStorekit.startCheckout.error\n"+
				JSON.stringify(e));
		}
	});
});

window.open();
