//NANOKONTROL MAPPINGS

(
var shift = 0;
var analysisPost = 0;

var noiseScale = 0, noiseVal = [4000,6000,150];
var modScale = 0, modVal = [12,60,1];


var recMode = [0,0,0];  //recMode:  0 == toggle, 1 == onsets
var recPost = [1,1];
var ovrTime = [0,0];   //if ovr held then clear buffer
var clrTime = [0,0];

var recFunc = {arg val, id;
	if ((val > 0) && (~recLoop[id].bufnum.notNil)) { ~recLoop[id].bufnum.zero };
	~recLoop[id].rec(val);
	~nkOUT.control(3, id+57, val*127);  				                                                        //LED FEEDBACK
	if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/rec"++id, val); };  				//LED FEEDBACK
};

/*var ovrFunc = {arg val, id;
	if (val > 0) { ovrTime[id] = Main.elapsedTime; } {
		if ((Main.elapsedTime - ovrTime[id]) > 0.38) {
			//HELD ---clear buffer
			~recLoop[id].bufnum.zero;
			~recLoop[id].synths.set(\ovr, 0);
			~nkOUT.control(3, id+53, 0); 				                                                //LED FEEDBACK
			if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++id, 0); };  				//LED FEEDBACK			("clear buffer "++id).postln;
		} {
			//PUSHED  ---toggle overdub on/off
			~recLoop[id].synths.get(\ovr, {arg v;
				v = 1 - v;
				~recLoop[id].synths.set(\ovr, v);
				~nkOUT.control(3, id+53, v*127); 				                                                //LED FEEDBACK
				if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++id, v); };  				//LED FEEDBACK
			})
		};
	}
};*/
var ovrFunc = {arg val, id;
	if (val > 0) {
		~recLoop[id].synths.get(\ovr, {arg v;
			v = 1 - v;
			~recLoop[id].synths.set(\ovr, v);
			~nkOUT.control(3, id+53, v*127); 				                                                //LED FEEDBACK
			if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++id, v); };  				//LED FEEDBACK
		})
	};
};

// var clrFunc = {arg id; ~recLoop[id].bufnum.zero;};
//HOLD TO DISABLE OVERDUB
var clrFunc = {arg id, val;
	var currentTime = Main.elapsedTime;
	if (val > 0) {
		~recLoop[id].bufnum.zero; //clear buffer when pressed
		clrTime[id] = currentTime;
	} {
		//overdub off is held
		if ((currentTime - clrTime[id]).abs > 0.4) {
			~recLoop[id].synths.set(\ovr, 0);
			~nkOUT.control(3, id+53, 0);
			if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/ovr"++id, 0); };
		};
	}
};





~onsetFunc = {arg msg;
	2.do{arg i;   if (recMode[i] > 0) {  recFunc.(msg[3], i)  };   };    // ~recLoop ONSET RECORD
	// if (recMode[2] > 0) { ~recSeq.rec(msg[3]); }; // ~recSeq ONSET RECORD
};







~nkOUT = MIDIOut.newByName("nanoKONTROL Studio", "CTRL");

MIDIdef.cc(\nk, {arg ...msg;
	//midichannel
	if (msg[2] == 3) {
	msg[0] = msg[0] / 127;

	if (msg[1] == 56) { shift = msg[0];   ~nkOUT.control(3, msg[1], msg[0]*127); };
	if (shift == 0) {
		~analysis[0].synths.get(\freqSus, {arg v; ~nkOUT.control(3, 52, v *127); }); //freqSus LED
		~recLoop[0].synths.get(\ovr, {arg v; ~nkOUT.control(3, 53, v *127); }); //is overdub LED
		~recLoop[1].synths.get(\ovr, {arg v; ~nkOUT.control(3, 54, v *127); });
		~recLoop[0].synths.get(\rec, {arg v; ~nkOUT.control(3, 57, v *127); }); //is recording LED
		~recLoop[1].synths.get(\rec, {arg v; ~nkOUT.control(3, 58, v *127); });

		case
		//FADERS
		{msg[1] == 0} { ~pedals.setScale(msg[0], 1,3) }  //reverb amnt
		{msg[1] == 1} { ~pedals.setScale(msg[0], 1,1); }  //ring duty
		{msg[1] == 2} { ~pedals.setScale(msg[0], 1,2); }  //delay time

		// {msg[1] == 3} { ~fx.args([\noise, msg[0].linexp(0,1,0.0001,18000)-0.0001]) }
		{msg[1] == 3} {  ~fx.args([\extMod, msg[0].linexp(0,1, 0.001, 1000)-0.001]) }
		{msg[1] == 4} {
			noiseScale = msg[0];
			// ~fx.args.size.do{arg i;  ~fx.args([\noise, noiseVal[i] * noiseScale, \noiseLag, msg[0].linexp(0,1, 0.5, 1/1024)], i); }
				~fx.args.size.do{arg i;  ~fx.args([\noise, noiseVal[i] * noiseScale, \noiseLag, ((1-msg[0])*(1-msg[0]))*1.96], i); }
		}

		{msg[1] == 5} { ~fx.args([\mix, msg[0]], 0) }  //filter mix
		{msg[1] == 6} { ~fx.args([\mix, msg[0]], 1) }  //ring mix
		{msg[1] == 7} { ~fx.args([\mix, msg[0], \inAmp, msg[0].linlin(0, 0.5, 0, 1)], 2) }  //delay mix




		//POTS
		{msg[1] == 8} { ~pedals.setScale(msg[0], 0,0); ~pedals.setScale(msg[0], 0,3); }  //filter freq + reverb ffreq
		{msg[1] == 9} { ~pedals.setScale(msg[0], 0,1); }  //ring freq
		{msg[1] == 10} { ~pedals.setScale(msg[0], 0,2); }  //delay ffreq

		// {msg[1] == 11} {~fx.args([\extMod, msg[0].linlin(0,1,-6,6)])}
		{msg[1] == 11} {
			modScale = msg[0] * msg[0] * msg[0];
			~fx.args.size.do{arg i;  ~fx.args([\ampMod, modVal[i] * modScale], i); }
		}
		{msg[1] == 12} {
				~fx.args([\ampLag, msg[0].linexp(0,1,0.001,220), \ampSkew, msg[0]*msg[0]*0.666, \freqLag, msg[0].linexp(0,1,0.1, 240), \freqSkew, msg[0] * msg[0] * 0.76])
		}

		{msg[1] == 13} {  ~fx.args([\type, msg[0]], 0); }  //filter type
		{msg[1] == 14} {}
		{msg[1] == 15} {~fx.args([\feed, msg[0]], 2); } //delay feed




		//BUTTONS
		//1st row  //pitch track
		{msg[1] == 16} {
			if (msg[0] == 0) { ~fx.args([\freq, ~analysis[0].freqBus.getSynchronous * ~fx.args[0][\transpose]], 0) };
			~fx.args([\track, msg[0]], 0);
			~nkOUT.control(3, msg[1], msg[0]*127);
		}
		{msg[1] == 17} {
			if (msg[0] == 0) { ~fx.args([\freq, ~analysis[0].freqBus.getSynchronous * ~fx.args[1][\transpose]], 1) };
			~fx.args([\track, msg[0]], 1);
			~nkOUT.control(3, msg[1], msg[0]*127);
		}
		{msg[1] == 18} {
			if (msg[0] == 0) { ~fx.args([\time, (~analysis[0].freqBus.getSynchronous * ~fx.args[2][\transpose]).reciprocal], 2) };
			~fx.args([\track, msg[0]], 2);
			~nkOUT.control(3, msg[1], msg[0]*127);
		}
		{msg[1] == 19} {
			~fx.args([\ftrack, msg[0]], 2);
			if (msg[0] == 0) { ~fx.args([\ffreq, ~analysis[0].freqBus.getSynchronous * ~fx.args[2][\ftranspose]], 2) };
			~nkOUT.control(3, msg[1], msg[0]*127);
		}


		{msg[1] == 20} { ~fx.store(0); ~pedals.store(1); "store 1".postln; }
		{msg[1] == 21} { ~fx.store(1); ~pedals.store(2); "store 2".postln;}
		{msg[1] == 22} { ~fx.store(2); ~pedals.store(3); "store 3".postln;}
		{msg[1] == 23} { ~fx.store(3); ~pedals.store(4); "store 4".postln;}
		//2nd row  //pitch freeze
		{msg[1] == 24} { ~fx.args([\freqFreeze, msg[0]], 0); ~nkOUT.control(3, msg[1], msg[0]*127); }
		{msg[1] == 25} { ~fx.args([\freqFreeze, msg[0]], 1); ~nkOUT.control(3, msg[1], msg[0]*127); }
		{msg[1] == 26} { ~fx.args([\freqFreeze, msg[0]], 2); ~nkOUT.control(3, msg[1], msg[0]*127); }
		{msg[1] == 27} {}

		{msg[1] == 28} { ~fx.recall(0); ~pedals.recall(1); "recall 1".postln; }
		{msg[1] == 29} { ~fx.recall(1); ~pedals.recall(2); "recall 2".postln; }
		{msg[1] == 30} { ~fx.recall(2); ~pedals.recall(3); "recall 3".postln; }
		{msg[1] == 31} { ~fx.recall(3); ~pedals.recall(4); "recall 4".postln; }
		//3rd row //left pedal gates
		{msg[1] == 32} { ~pedals.gates[0][0] = msg[0];  ~nkOUT.control(3, msg[1], msg[0]*127); }  //filter freq
		{msg[1] == 33} { ~pedals.gates[0][1] = msg[0]; ~nkOUT.control(3, msg[1], msg[0]*127); }  //ringfreq
		{msg[1] == 34} { ~pedals.gates[0][2] = msg[0]; ~nkOUT.control(3, msg[1], msg[0]*127); }  //
		{msg[1] == 35}  {}
		{msg[1] == 36}  {}
		{msg[1] == 37}  {}
		{msg[1] == 38}  {}
		{msg[1] == 39}  { ~fx.recall(0); ~pedals.recall(0); "recall 0: init".postln; }
		//4th row  //right pedal gates
		{msg[1] == 40} { ~pedals.gates[1][3] = msg[0]; ~nkOUT.control(3, msg[1], msg[0]*127); }  //reverb
		{msg[1] == 41} { ~pedals.gates[1][1] = msg[0]; ~nkOUT.control(3, msg[1], msg[0]*127); }
		{msg[1] == 42} { ~pedals.gates[1][2] = msg[0]; ~nkOUT.control(3, msg[1], msg[0]*127); }
		{msg[1] == 43} { ~fx.args([\extSrc, msg[0]]); ~nkOUT.control(3, msg[1], msg[0]*127); } //modulation amp, amp*ext, ext
		{msg[1] == 44} {}
		{msg[1] == 45} {}
		{msg[1] == 46} {}
			{msg[1] == 47} { ~fx.args([\inAmp, msg[0]]); ~nkOUT.control(3, msg[1], msg[0]*127)  }


		//TRANSPORT BUTTONS
		// {msg[1] == 48} { shift = msg[0];  }
			{msg[1] == 49} {  clrFunc.(0, msg[0]); }  //clear ~recLoop[0]
			{msg[1] == 50} {  clrFunc.(1, msg[0]); }  //clear ~recLoop[1]
		{msg[1] == 51} {}

		//analysis ONSET SAH PITCHTRACK
		{msg[1] == 52} {
			~analysis[0].synths.get(\freqSus, {arg v;
				~analysis[0].synths.set(\freqSus, 1 -v);
				~nkOUT.control(3, msg[1],  (1-v)*127);
				("freqSus: "++ (1-v)).postln;
			})
		}
		{msg[1] == 53} { ovrFunc.(msg[0], 0) }   // ~recLoop 0  OVERDUB
		{msg[1] == 54} { ovrFunc.(msg[0], 1) }   // ~recLoop 1  OVERDUB
		{msg[1] == 55} {}

		// {msg[1] == 56} { ~analysis[0].freqSus(msg[0]);	~nkOUT.control(3, msg[1], msg[0]*127); ("freqSus: "++msg[0]).postln}  //analysis ONSET SAH PITCHTRACK
		// {msg[1] == 57} {  if (recMode[0] == 0) {  recFunc.(msg[0], 0);  }; }  //RECORD 0
		// {msg[1] == 58} { if (recMode[1] == 0) {  recFunc.(msg[0], 1);  }; }  //RECORD 1
		{msg[1] == 57} { 	if (recMode[0] == 0) {  ~recLoop[0].synths.get(\rec, {arg v; recFunc.(1-v, 0)})  };  } //RECORD 0
		{msg[1] == 58} { 	if (recMode[1] == 0) {  ~recLoop[1].synths.get(\rec, {arg v; recFunc.(1-v, 1)})  };  }  //RECORD 1
		{msg[1] == 59} { recMode[2] = msg[2]; ~nkOUT.control(3, msg[1], msg[0]*127); }  //RECSEQ
		;

	} {

		////////////////////////// SHIFT MODE /////////////////////////////////
		~nkOUT.control(3, 52, analysisPost *127);
			// ~nkOUT.control(3, 53, recPost[0]*127); //recPostFX
			// ~nkOUT.control(3, 54, recPost[1]*127);
			~nkOUT.control(3, 49, (~play[0].args[0][\rate] > 1).asInteger * 127);
			~nkOUT.control(3, 50, (~play[1].args[0][\rate] > 1).asInteger * 127);
			~nkOUT.control(3, 53, (~play[0].args[0][\rate]< 1).asInteger * 127);
			~nkOUT.control(3, 54, (~play[1].args[0][\rate] < 1).asInteger * 127);
		~nkOUT.control(3, 57, recMode[0]*127); //onset (leds when enter shift mode
		~nkOUT.control(3, 58, recMode[1]*127);

		case
		//TRANSPORT BUTTONE
		// {msg[1] == 48} { shift = msg[0] }

		// 49, 50//HALF
		// 53, 54//DOUBLE


		{msg[1] == 52} {
			analysisPost = 1 - analysisPost;
			if (analysisPost > 0) { ~analysis[0].inBus(~fxBus); } { ~analysis[0].inBus(~inBus); };  //analysis input source  PRE/POST
			if (analysisPost > 0) { "POSTFX analysis".postln; } { "PREFX analysis".postln };
			~nkOUT.control(3, msg[1], analysisPost*127);
		}

			//DOUBLE PITCH
			{(msg[1] == 49) && (msg[0] > 0)} {
				~play[0].args.size.do{arg i;
					~play[0].args[i][\rate] = (~play[0].args[i][\rate] * 2).clip(0, 12);
				};
			}
			{(msg[1] == 50) && (msg[0] > 0)} {
				~play[1].args.size.do{arg i;
					~play[1].args[i][\rate] = (~play[1].args[i][\rate] * 2).clip(0, 12);
				};
			}
			//reset pitch 0
			{(msg[1] == 51) && (msg[0] > 0)} {
				~play[0].args.collect(_[\rate] = 1);
			}

			//HALF PITCH
			{(msg[1] == 53) && (msg[0] > 0)} {
				~play[0].args.size.do{arg i;
					~play[0].args[i][\rate] = (~play[0].args[i][\rate] / 2).clip(0, 12);
				};
			}
			{(msg[1] == 54) && (msg[0] > 0)} {
				~play[1].args.size.do{arg i;
					~play[1].args[i][\rate] = (~play[0].args[i][\rate] / 2).clip(0, 12);
				};
			}

			//reset pitch 1
			{(msg[1] == 55) && (msg[0] > 0)} {
				~play[1].args.collect(_[\rate] = 1);
			}

		// record pre/post fx
	/*	{(msg[1] == 53) && (msg[0] > 0)} {
			recPost[0] = 1 - recPost[0];
			if (recPost[0] > 0) {
					~recLoop[0].synths.collect(_.set(\inBus, ~fxBus));  2.do{arg i; ~play[i].args([\outBus, ~playBus[i]]) };
			} {
					~recLoop[0].synths.collect(_.set(\inBus, ~inBus)); 2.do{arg i; ~play[i].args([\outBus, ~fxBus]) };
			};
			~nkOUT.control(3, msg[1], recPost[0]*127);
		}
		{(msg[1] == 54) && (msg[0] > 0)} {
			recPost[1] = 1 - recPost[1];
			if (recPost[1] > 0) {
					~recLoop[1].synths.collect(_.set(\inBus, ~fxBus));  2.do{arg i; ~play[i].args([\outBus, ~playBus[i]]) };
			} {
					~recLoop[1].synths.collect(_.set(\inBus, ~inBus)); ~play[0].args([\outBus, ~fxBus]);
			};
			~nkOUT.control(3, msg[1], recPost[1]*127);
		}
*/
		//onset recording
		{msg[1] == 57} { recMode[0] = 1 - recMode[0]; ~nkOUT.control(3, msg[1], recMode[0]*127); } //ONSET RECORDING
		{msg[1] == 58} { recMode[1] = 1 - recMode[1]; ~nkOUT.control(3, msg[1], recMode[1]*127); } //ONSET RECORDING
		{(msg[1] == 59) && (msg[0] > 0)} {
		~play[0].args.collect(_[\rate] = 1);
		~play[1].args.collect(_[\rate] = 1);
			}
		;

	};
	}
});







//MAX GUI
OSCdef(\recMap, {arg msg;
	case
	{(msg[1] >= 0)  &&  (msg[1] <= 1)} {  if (recMode[msg[1]] == 0) {  recFunc.(msg[2], msg[1]);  } }
	{(msg[1] > 1)  &&  (msg[1] <= 3)} { ovrFunc.(msg[2], msg[1] - 2); }
	{(msg[1] > 3)  &&  (msg[1] <= 5)} { ~recLoop[msg[1] - 3].synths.set(\feed, msg[2]) }
	{(msg[1] > 5)  &&  (msg[1] <= 7)} { ~recLoop[msg[1] - 6].bufnum.zero }
	{(msg[1] > 7)  &&  (msg[1] <= 9)} { ~recLoop[msg[1] - 8].synths.set(\noise, msg[2]) }
	{(msg[1] > 9)  &&  (msg[1] <= 11)} {
		msg[1] =msg[1] - 10;
		case
		{msg[2] == 0} { ~recLoop[msg[1]].synths.set(\inBus, ~fxBus) }  //input
		{msg[2] == 1} {  ~recLoop[msg[1]].synths.set(\inBus, ~playBus[1]) }  //other looper
		{msg[2] == 2} { ~recLoop[msg[1]].synths.set(\inBus, ~mBus) }; //master
	}
	// {(msg[1] > 11)  &&  (msg[1] <= 13)} { ~recDouble.(msg[1] - 12) }
	// {(msg[1] > 13)  &&  (msg[1] <= 15)} { ~recHalf.(msg[1] - 14) }
	// {(msg[1] > 15)  &&  (msg[1] <= 17)} { ~recJoin.(msg[1] - 16) }

	//RECORDER MODE
	{(msg[1] > 17)  &&  (msg[1] <= 19)} { recMode[msg[1] - 18] = msg[2]; };

}, '/rec');


// OSCdef(\recSeqMap, {arg msg;
// 	case
// 	{msg[1] == 0} {
// 		if (recMode[2] == 0) {  ~recSeq.rec(msg[2]);  };
// 		if (~sendOSC.notNil) { ~sendOSC.sendMsg("/LED/rec2", msg[2]); };
// 	}
// 	{msg[1] == 1} {  if (msg[2] > 0) { ~playSeq.task.play } { ~playSeq.task.stop };  }
// 	{msg[1] == 2} { ~playSeq.random(msg[2]) }
// 	{msg[1] == 3} { ~recSeq.maxSteps(msg[2].clip(0, ~recSeq.bufnum.size)) }
// 	{msg[1] == 4} { ~playSeq.startStep(msg[2]) }
// 	{msg[1] == 5} { ~playSeq.endStep(msg[2]) }
// 	{msg[1] == 6} { ~playSeq.speed(msg[2]) }
// 	{msg[1] == 7} { ~playSeq.args.collect(_[\duty] = msg[2]) }
// 	{msg[1] == 8} { recMode[2] = msg[2]; }
// }, '/seq');








//INDIVIDUAL SCALING PER FX
OSCdef(\fxMap, {arg msg;
	case
	{(msg[1] >= 13) && (msg[1] < 17)} {
		var i = msg[1] - 13;
		noiseVal[i] = msg[0];
		~fx.args([\noise, noiseVal[i] * noiseScale], i);
	}

	{(msg[1] >= 17) && (msg[1] < 20)} {
		var i = msg[1] - 17;
		modVal[i] = msg[0];
		~fx.args([\extMod, modVal[i] * modScale], i);
	}
	{(msg[1] >= 20) && (msg[1] < 23)} { ~fx.args([\extSrc, msg[0]], msg[1] - 20) }


	{(msg[1] >= 23) && (msg[1] < 26)} { ~fx.args([\freqLag, msg[0]], msg[1] - 23); }
	{(msg[1] >= 29) && (msg[1] < 32)} { ~fx.args([\ampLag, msg[0]], msg[1] - 29); }
	{(msg[1] >= 32) && (msg[1] < 35)} { ~fx.args([\ampSkew, msg[0]], msg[1] - 32); };

	//ADD GLOBAL freqLAG and ampLAG ???
}, '/fx');


OSCdef(\inputMap, {arg msg;
	case
	{msg[1] == 0} { ~input.set(\amp, msg[2]) }
	{msg[1] == 1} {
		case
		{msg[2] == 0} { ~analysis[0].set(\inBus, ~inBus) }
		{msg[2] == 1} { ~analysis[0].set(\inBus, ~fxBus) }
		{msg[2] == 2} { ~analysis[0].set(\inBus, ~mBus) }
	}
	{msg[1] == 2} { ~analysis[0].set(\freqSus, msg[2]) }
	// {msg[1] == 3} { ~analysis[0].set(\freqFreeze, msg[2]) }
	{msg[1] == 4} { ~analysis[0].set(\thresh, msg[2]) }

	// {msg[1] == 5} { ~analysis[0].set(\freqScale, msg[2]) }
	// {msg[1] == 6} { ~analysis[0].set(\ampScale, msg[2]) }
	// {msg[1] == 7} { freqLag = msg[2]; ~analysis[0].set(\freqAtt, freqLag * freqSkew, \freqRel, freqLag * (1-freqSkew)) }
	// {msg[1] == 8} { freqSkew = msg[2]; ~analysis[0].set(\freqAtt, freqLag * freqSkew, \freqRel, freqLag * (1-freqSkew)) }
	// {msg[1] == 9} { ampLag = msg[2]; ~analysis[0].set(\ampAtt, ampLag * ampSkew, \ampRel, ampLag * (1-ampSkew)) }
	// {msg[1] == 10} { ampSkew = msg[2]; ~analysis[0].set(\ampAtt, ampLag * ampSkew, \ampRel, ampLag * (1-ampSkew)) }
	;
}, '/input');





/*

//BOW RECORD BUTTONS
~bow.buttonFunc[0] = {arg val; if (recMode[0] == 0) {  recFunc.(val, 0);  }; };
~bow.buttonFunc[1] = {arg val; if (recMode[1] == 0) {  recFunc.(val, 1);  }; };
~bow.buttonFunc[2] = {arg val; ovrFunc.(val, 0); };
~bow.buttonFunc[3] = {arg val; ovrFunc.(val, 1); };

//pedal gates
//record bow data
//record + trigger grain train
*/
)



// ADD QUANTISE ON/OFF
// ~pedals.quantMode.collect(_.fill(1))

//TURN PAIRS ON AND OFF
// ~pedals.gates[0][0] = 1; ~pedals.gates[1][3] = 1; //filter + verb
// ~pedals.gates[0][1] = 1; ~pedals.gates[1][1] = 1; //ring
// ~pedals.gates[0][2] = 1; ~pedals.gates[1][2] = 1; //delay

// s.makeGui

// ~fx.args([\freqLag, 3])


