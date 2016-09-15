var nTest = 4;
var nTrain = 20;
var trial = -1;
var d = new Date();
var m = [1,2,3]; m = shuffle(m); m = m[0];
var subjID = '7' + Math.random().toString().substring(3,8);
var filename = 'data/' + subjID + '_' + d.getTime() + '_' + m +  '.csv';
var reward = 0;
var mode = 1;
var restaurants = ["Molina's Cantina", "Restaurante Arroyo", "El Coyote Cafe"];
var foods = ["food1", "food2","food3"];
var train = [0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3]; train = shuffle(train);
var test = [0,1,2,3]; test = shuffle(test);
var food = 0;
var context = 0;
var Test = 0;
var f = 0;

var r = [];
if (m==1) {
	r[0] = 1;
	r[1] = 0;
	r[3] = 1;
	r[4] = 0;
} else if (m==2) {
	r[0] = 1;
	r[1] = 0;
	r[3] = 0;
	r[4] = 1;
} else {
	r[0] = 1;
	r[1] = 1;
	r[3] = 0;
	r[4] = 0;
}

var train_cue = [];
train_cue[0] = 0;
train_cue[1] = 1;
train_cue[2] = 0;
train_cue[3] = 1;

var train_context = [];
train_context[0] = 0;
train_context[1] = 0;
train_context[2] = 1;
train_context[3] = 1;

var test_cue = [];
test_cue[0] = 0;
test_cue[1] = 0;
test_cue[2] = 2;
test_cue[3] = 2;

var test_context = [];
test_context[0] = 0;
test_context[1] = 2;
test_context[2] = 0;
test_context[3] = 2;

// Initialization
$(document).ready(function() {
 	$('#endExperiment').hide();
	$('#startGame').hide();
 	$('#buttons').hide();
	$('#food1').hide();
	$('#Instructions').hide();
	$('#feedback').hide();
	$('#submit').hide();
	$('#food1').hide();
	$('#food2').hide();
	$('#food3').hide();
	$('#smiley').hide();
	$('#sick').hide();
	$('#restaurant').hide();
	$('#button1').text("Sick");
	$('#button2').text("Not sick");
	$('#submit').text("Next");
				  
    $("#button1").click(function() {
		b = 1;
		Feedback();
	})
  
    $("#button2").click(function() {
		b = 0;
		Feedback();
	})
				  
	$("#submit").click(function() {
		NextTrial();
	})

});

function Feedback() {
	
	if (Test==0) {
		$('#button1').hide();
		$('#button2').hide();
		$('#submit').show();
		if (r[train[trial]]==1) {
			var outcome = 1;
			$('#sick').show();
			$('#title').text("The customer got sick!");
		} else {
			var outcome = 0;
			$('#smiley').show();
			$('#title').text("The customer didn't get sick!");
		}
		var result_string = outcome + ',' + context + ',' + f + ',' + b + '\n';
		$.post("post_results.php",{postresult: result_string, postfile: filename});
	} else {
		var outcome = -1;
		var result_string = outcome + ',' + context + ',' + f + ',' + b + '\n';
		$.post("post_results.php",{postresult: result_string, postfile: filename});
		NextTrial();
	}
	
}

function NextTrial() {
	trial++;
	$('#title').text("Predict whether the customer will get sick from this food.");
	$('#'+food).hide();
	$('#smiley').hide();
	$('#sick').hide();
	$('#button1').show();
	$('#button2').show();
	$('#submit').hide();
	
	if (Test==0 && trial==nTrain) {
		Test = 1;
		trial = 0;
	}
	
	if (Test==1) {
		f = test_cue[test[trial]];
		food = foods[f];
		context = test_context[test[trial]];
	} else {
		f = train_cue[train[trial]];
		food = foods[f];
		context = train_context[train[trial]];
	}
	
	$('#restaurant').text(restaurants[context]);
	$('#restaurant').show();
	$('#'+food).show();
	
	// end of experiment
	if (Test==1 && trial==nTest) {
		$('#buttons').hide();
		$('#startGame').hide();
		$('#Instructions').show();
		$('#title').hide();
		$('#restaurant').hide();
		$('#'+food).hide();
		$("#Instructions").text("You're done! \nYour code is " + subjID + ". Please return to the Mechanical Turk page to enter this code and get paid.");
	}
}

function StartGame() {
	$('#startGame').hide();
	$('#Instructions').hide();
	$('#buttons').show();
	NextTrial();
}

function StartExperiment() {
	$('#consent').hide();
	$('#startExperiment').hide();
	$('#Instructions').show();
	$('#startGame').show();
}

function shuffle(array) {
    var currentIndex = array.length
    , temporaryValue
    , randomIndex
    ;
    
    // While there remain elements to shuffle...
    while (0 !== currentIndex) {
        
        // Pick a remaining element...
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;
        
        // And swap it with the current element.
        temporaryValue = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = temporaryValue;
    }
    
    return array;
}