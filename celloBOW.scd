// "https://www.sensestage.eu/documentation/sections/software/creating_configuration_file.html"      //create config file
// pydongui.py     <<< launch in terminal

var buttonVal = Array.fill(8, {0});
var buttonFunc = Array.fill(8, { nil });

var pressure = 0;

var accBus = Bus.control(s, 3);
var acc = [0,0,0], lastAcc = Array.fill(18, { [0,0,0] });
var avg = [0,0,0], lastAvg = [0,0,0];
var count = -1;

var thresh = 0.0012, isMovingFunc = [nil];
var isMoving = [0,0,0], lastisMoving = [0,0,0];
var isMovingSum = 0;
// var startTimes = [0,0,0], durations = [0,0,0];


OSCdef(\bee, {arg msg;
	//BUTTONS
	buttonVal.size.do{arg i;
		msg[i+2] = 1 - msg[i+2];                                   //invert value (because using pullup resistors)
		if (msg[i+2] != buttonVal[i]) {
			buttonVal[i] = msg[i+2];
			if (buttonFunc[i].notNil) { buttonFunc[i].( buttonVal[i] ) };
		}
	};

	//PRESSURE
	pressure = msg[10];

	//ACCELEROMETER
	msg[12] = 1 - msg[12];                       //invert Y axis
	acc = (msg[11.. 13] - 0.5) * 10;          //store and scale acceleration values

	//calculate average
	count = (count + 1) % lastAcc.size;   //increment counter
	lastAcc[count] = acc;                            //store previous XYZ values in array
	avg = lastAcc.sum / lastAcc.size;      //find average


	//isMoving
	3.do{arg i;
		isMoving[i] = ((avg[i] - lastAvg[i]).abs > thresh).asInteger;
		lastisMoving[i] = isMoving[i];
		// direction = avg.isNegative.asInteger;  //find direction of movement
	};
	lastAvg = avg;

	//isMovingFunc
	if (isMoving.sum.clip(0,1) != isMovingSum) {  if (isMovingFunc.notNil) { isMovingFunc[0].( isMoving.sum.clip(0,1) ); };  };
	isMovingSum = isMoving.sum.clip(0, 1);

	accBus.setn(acc);

	if (~sendOSC.notNil) {
		~sendOSC.sendMsg('/bow/acc', acc[0], acc[1], acc[2]);
		~sendOSC.sendMsg('/bow/avg', avg[0], avg[1], avg[2]);
		~sendOSC.sendMsg('/bow/pressure', pressure);
		~sendOSC.sendMsg('/bow/isMoving', isMoving[0], isMoving[1], isMoving[2]);
		~sendOSC.sendMsg('/bow/isMovingSum', isMovingSum);
		~sendOSC.sendMsg('/bow/accSum', (acc.sum / acc.size).abs);
	}
}, '/minibee/data');


~bow = (
	button: { buttonVal },
	buttonFunc: { buttonFunc },
	pressure: { pressure },
	acc: { acc },
	avg: { avg },
	accBus: { accBus},

	isMoving: { isMoving },
	isMovingSum: { isMovingSum },
	thresh: {arg self, val;  if (val.isNil) { thresh } { thresh = val };  },
	isMovingFunc: { isMovingFunc },
);





//MAPPINGS
~bow.buttonFunc[0] = {arg val; ~pedals.gates[1][4] = val; "AMP".postln }; //amp
~bow.buttonFunc[1] = {arg val; ~pedals.gates[0][0] = val; "FILTER".postln };   //filter
~bow.buttonFunc[3] = {arg val; ~pedals.gates[0][1] = val; ~pedals.gates[1][1] = val; "RING".postln };  //ringmod
~bow.buttonFunc[2] = {arg val; ~pedals.gates[0][2] = val; ~pedals.gates[1][2] = val; "DELAY".postln };  //delay

// ~bow.buttonFunc[4] = {arg val; ~pedals.gates[0][3] = val;  ~pedals.gates[1][3] = val; "VERB".postln }; //verb
~bow.buttonFunc[4] = {arg val;
		~recLoop[0].synths.set(\ovr, 0);
		~nkOUT.control(3, 53, 0); 				                                                //LED FEEDBACK
	if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++0, 0); };  				//LED FEEDBACK	if (val > 0) { ~recLoop[0].bufnum.zero };  ~recLoop[0].rec(val);

		if (val > 0) { ~recLoop[0].bufnum.zero };  ~recLoop[0].rec(val);

	~nkOUT.control(3, 57, val*127);  				                                                        //LED FEEDBACK
	if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/rec"++0, val); };  				//LED FEEDBACK
	"REC 0".postln
};

~bow.buttonFunc[5] = {arg val;
	~recLoop[0].synths.set(\ovr, val);
	~nkOUT.control(3, 53, val*127); 				                                                //LED FEEDBACK
	if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++0, val); };  				//LED FEEDBACK
	"OVR 0".postln
};

~bow.buttonFunc[6] = {arg val;
		~recLoop[1].synths.set(\ovr, 0);
		~nkOUT.control(3, 54, 0); 				                                                //LED FEEDBACK
	if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++1, 0); };  				//LED FEEDBACK

	if (val > 0) { ~recLoop[1].bufnum.zero };  ~recLoop[1].rec(val);
		~nkOUT.control(3, 58, val*127);  				                                                        //LED FEEDBACK
	if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/rec"++1, val); };  				//LED FEEDBACK
	"REC 1".postln;
};

~bow.buttonFunc[7] = {arg val;
			~recLoop[1].synths.set(\ovr, val);
			~nkOUT.control(3, 54, val*127); 				                                                //LED FEEDBACK
			if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++1, val); };  				//LED FEEDBACK
	"OVR 1".postln
};





~bow.isMovingFunc[0] = {arg msg;
	if (msg > 0) { ~mod.set(\t_start, 1) } { ~mod.set(\t_stop, 1) };
}
