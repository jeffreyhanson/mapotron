Shiny.addCustomMessageHandler("jsCode",
	function(message) {
		console.log(message)
		eval(message.code);
	}
	);

Shiny.addCustomMessageHandler("update_var",
	function(message) {
		eval(message.var + \' = \' + message.val);
	}
	);


var is_dirty=false;
var auto_send=false;
function exit_page(event) {
	if (is_dirty && !auto_send) {
		return \'You have made changes to the data without downloading or emailing it -- if you leave before performing either of these actions all data will be lost.\'
	}
}
window.onbeforeunload = exit_page;

Shiny.addCustomMessageHandler("download_file",
	function(message) {
		var link = document.createElement("a");
		link.download = "spatialdata.zip";
		link.href = message.message;
		link.click();
	}
);

Shiny.addCustomMessageHandler("enable_button", 
	function(message) {
		$("#" + message.btn).removeAttr("disabled");
	}
);

Shiny.addCustomMessageHandler("disable_button", 
	function(message) {
		$("#" + message.btn).prop(\"disabled\",true);
	}
);
			
var enterTextInputBinding = new Shiny.InputBinding();
	$.extend(enterTextInputBinding, {
	find: function(scope) {
		return $(scope).find(\'.enterTextInput\');
	},
	getId: function(el) {
		//return InputBinding.prototype.getId.call(this, el) || el.name;
		return $(el).attr(\'id\')
	},
	getValue: function(el) {
		return el.value;
	},
	setValue: function(el, value) {
		el.value = value;
	},
	subscribe: function(el, callback) {
		$(el).on(\'keyup.textInputBinding input.textInputBinding\', function(event) {
			if(event.keyCode == 13) { //if enter
				callback()
			}
		});	
	},
	unsubscribe: function(el) {
		$(el).off(\'.enterTextInputBinding\');
	},
	receiveMessage: function(el, data) {
		if (data.hasOwnProperty(\'value\'))
			this.setValue(el, data.value);
		if (data.hasOwnProperty(\'label\'))
			$(el).parent().find(\'label[for=\' + el.id + \']\').text(data.label);
		$(el).trigger(\'change\');
	},
	getState: function(el) {
		return {
			label: $(el).parent().find(\'label[for=\' + el.id + \']\').text(),
			value: el.value
		};
	},
	getRatePolicy: function() {
		return {
			policy: \'debounce\',
			delay: 250
		};
	}
});

Shiny.inputBindings.register(enterTextInputBinding, \'shiny.enterTextInput\');
