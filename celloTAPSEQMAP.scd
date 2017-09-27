~lp.post = 1



//set looppoints mode
TEST OVERDUB PER STEP
TEST AMP MAPPING
TEST ~setArgsRel   ---should be ONLY FOR seqButtons,  step args keep their relative values

TEST ONSET RECORDING
(
~recFlag = 0;
~onsetFunc = {arg msg;
	var id = msg[2], on = msg[3];
	if (~recFlag > 0) { ~tap[id].rec(on); };
};

~lp.setFunc(64, {arg k, v;
	if (v > 0) {
		// ~tap[0].clearData();
		~recFlag = 1;
		~tap[0].setStart();
	} {
		~recFlag = 0;
	};
});
)


~analysis.synths[0].set(\thresh, 0.9)



+LOOPER FUNCTIONALITY   +POLYPHONIC MODE (launch looping synth? use \sustain?,  timer per synth, just loop one step?mono)
start time gets reset to 0 when recordin time data for single steps
start time for step is actually time to wait until play that step (time between last step and this step)
0 == 7
1 == 0
2 == 1
etc

IMPROVE SYNTHDEF -GRAINS/WARP FOR OVERLAPPED RETRIGGERS
/*
// ZOOM MODE FOR GUI  --seqs OR steps
~but = [64,65,66,67,68,69,70,71];
~zoom = 0;

~but.do{arg val, i;
	~lp.setFunc(val, {arg k, v;
		if (~zoom > 0) {
			//show steps
		} {
			//show seqs
		}
	});
};
*/




(
//modes: play, rec, speed(tap), set args,   reset counter, clear, speed(reset), overdub
var mode = 0, lastMode = 0;
var quantMode = 0;
var lastTime = 0;  //for tap tempo (seq speed)
var clockLastTime = 0; //for tap tempo (main clock)

var modeButtons = [112, 113, 114, 115, 96, 97, 98, 99];
var seqButtons = [8, 24, 40, 56];
var stepButtons = [
	Array.fill(8, {arg i; i }),
	Array.fill(8, {arg i; i + 16 }),
	Array.fill(8, {arg i; i + 32 }),
	Array.fill(8, {arg i; i + 48 }),
];

~held = Array.fill(~tap.size, { List.new; }); //for setting args


MIDIIn.connectAll;
~lp = LaunchPad.new;

//SET MODE
~lp.setColor(modeButtons[0], 112, 20);   //play
~lp.setColor(modeButtons[1], 10, 5);   //record
~lp.setColor(modeButtons[2], 47, 17);   //speed (tap)
~lp.setColor(modeButtons[3], 47, 17);   //set args

~lp.setColor(modeButtons[4], 112, 20);   //reset count/play
~lp.setColor(modeButtons[5], 10, 5);   //clear buffer+data/rec
~lp.setColor(modeButtons[6], 47, 17);   //reset speed
~lp.setColor(modeButtons[7], 10, 5);   //record audio / overdub


~lp.setState(modeButtons[mode], 1);

modeButtons.size.do{arg i;
	~lp.setState(modeButtons[i], 0);
	~lp.setFunc(modeButtons[i], {arg k, v;
		if (i < 4) {
			if (v > 0) { mode = i; lastMode = mode };   //TOGGLE first four
		} {
			if (v > 0) { mode = i } { mode = lastMode };   //MOMENTARY last four
		};

		if (i == 1) {  ~tap.collect(_.setStart());  };     //store record start time
		modeButtons.do{arg vv, ii;   	if (ii == mode) { ~lp.setState(vv, 1); } { ~lp.setState(vv, 0) }    };  //update leds

		case
		{mode == 0} { "play".postln }
		{mode == 1} { "rec".postln }
		{mode == 2} { "mute/tap speed".postln }
		{mode == 3} { "set args".postln }

		{mode == 4} { "reset play".postln }
		{mode == 5} { "reset buffer + data".postln }
		{mode == 6} { "reset speed".postln }
		{mode == 7} { "overdub/record audio".postln };

	});
};


//DOUBLE TEMPO
~lp.setFunc(72, {arg k, v;
	if (v > 0) { TempoClock.default.tempo = (TempoClock.default.tempo * 2).clip(1/8, 12) };
	~lp.setState(k, v);
});
//HALF TEMPO
~lp.setFunc(88, {arg k, v;
	if (v > 0) { TempoClock.default.tempo = (TempoClock.default.tempo / 2).clip(1/8, 12) };
	~lp.setState(k, v);
});


//TAP TEMPO
~lp.setColor(104, 10, 45);
~lp.setState(104, 0);
~lp.setFunc(104, {arg k, v;
	var currentTime = Main.elapsedTime;
	if (v > 0) {
		// if ((currentTime - clockLastTime) < 8) {
		TempoClock.default.tempo = (currentTime - clockLastTime).reciprocal.clip(1/8, 12);
		// };
		clockLastTime = currentTime;
	};
	~lp.setState(k, v);
});

//TOGGLE QUANT MODE
~lp.setColor(120, 47, 17);
~lp.setState(120, 0);
~lp.setFunc(120, {arg k, v;
	if (v > 0) {
		quantMode = 1 - quantMode;
		~lp.setState(k, quantMode);
	};
});




//SEQ BUTTONS
seqButtons.size.do{arg id;
	~lp.setFunc(seqButtons[id], {arg k, v;
		case
		//play
		{(mode == 0) && (v > 0)} {
			~lp.setColor(seqButtons[id], 100, 20);
			if (quantMode > 0) {
				if (~tap[id].task.isPlaying) {
					TempoClock.default.schedAbs(TempoClock.default.nextBar, {
						~tap[id].task.stop;
						~lp.setState(k, 0);
					});
				} {
					TempoClock.default.schedAbs(TempoClock.default.nextBar, {
						~tap[id].task.play(doReset: true);
						~lp.setState(k, 1);
					});
				};
			} {
				if (~tap[id].task.isPlaying) {
					~tap[id].task.stop;
					~lp.setState(k, 0);
				} {
					~tap[id].task.play;
					~lp.setState(k, 1);
				};
			};
		}
		//record
		{mode == 1} {
			~tap[id].rec(v);
			~lp.setColor(seqButtons[id], 10, 5);
			~lp.setState(k, v);
		}
		//tap speed
		{mode == 2} {
			var currentTime = Main.elapsedTime;
			if (v > 0) {
				~tap[id].speed = (currentTime - lastTime).reciprocal.clip(1/8, 8).postln;
				lastTime = currentTime;
			};
			~lp.setState(k, v);
		}
		//set args
		{mode == 3} {
			if (v > 0) {
				stepButtons[id].size.do{arg i; ~held[id].add(i);~held.postln; };
			} {
				stepButtons[id].size.do{arg i; ~held[id].remove(i); };
			};
			~held.postln;
		}

		//reset count
		{(mode == 4) && (v > 0)} {
			~lp.setColor(seqButtons[0], 100, 20);
			if (quantMode > 0) {
				TempoClock.default.schedAbs(TempoClock.default.nextBar, {  ~tap[id].task.reset;  });
			} {
				// ~tap[id].task.reset;
				~tap[id].task.stop;
				~tap[id].task.play(doReset:  true);
			};
			~lp.setState(k, v);
		}
		//reset buffer + data
		{(mode == 5) && (v > 0)} {
			~tap[id].bufnum.collect(_.zero);
			~tap[id].clearData();
		}
		//reset speed
		{(mode == 6) && (v > 0)} { ~tap[id].speed = 1; }

		//record audio / overdub
		{mode == 7} {
			if (v > 0) {
				~lp.setColor(k, 10, 0);
				// ~lp.setState(k, 1 - ~lp.getState(k));
				// ~tap[id].args.do{arg v, i;  ~tap[id].args[i][\rec] = ~lp.getState(k).postln;  };
				~tap[id].args.do{arg v, i; ~tap[id].args[i][\rec] = 1 - ~tap[id].args[i][\rec]; };
				~lp.setState(k, ~tap[id].args[i][\rec]);
			};
		}
		;


	});
};





//STEP BUTTONS
stepButtons.size.do{arg id;
	stepButtons[id].size.do{arg i;
		~lp.setColor(stepButtons[id][i], 100, 100);
		~lp.setState(stepButtons[id][i], 0);
		~lp.setFunc(stepButtons[id][i], {arg k, v;
			case
			{(mode == 0) && (v > 0)} {  ~tap[id].playStep(i);  }
			{mode == 1} {
				~lp.setColor(k, 10, 100);
				~tap[id].recStep(v, i);
				~lp.setState(k, v);
			}  //record step   (LIKE LOOPER)

			//mute on / off
			{(mode == 2) && (v > 0)} {
				~tap[id].mute[i] = 1 - ~tap[id].mute[i];
				if (~tap[id].mute[i] == 0) {
					~lp.setColor(k, 30, 100);   //NOT muted
				} {
					~lp.setColor(k, 33, 0); //muted
				};
				~lp.setState(k, 0);
			}
			//set args
			{mode == 3} {
				if (v > 0) {  ~held[id].add(i);  } {  ~held[id].remove(i);  };
				~lp.setState(k, v);
			}

			//reset step args ?
			// {(mode == 4) && (v > 0)} {  }
			//reset step buffer /clear
			{mode == 5} {
				~lp.setColor(k, 10, 100);
				if (v > 0) { ~tap[id].bufnum[i].zero; };
				~lp.setState(k, v);
			}
			{mode == 6} {  }
			//record audio /overdub
			{mode == 7} {
				if (v > 0) {
					~lp.setColor(k, 10, 100);
					~tap[id].args[i][\rec] = 1 - ~tap[id].args[i][\rec]; };
				~lp.setState(k, ~tap[id].args[i][\rec]);
			};

	});
};
};





//PRESETS
//store
[100, 101, 102, 103].do{arg val, i;
	~lp.setColor(val, 10, 5);
	~lp.setState(val, 0);
	~lp.setFunc(val, {arg k, v;
		if (v > 0) { ~tap.collect(_.store(i)) };
		~lp.setState(k, v);
	});
};
//recall
[116, 117, 118, 119] .do{arg val, i;
	~lp.setColor(val, 112, 20);
	~lp.setState(val, 0);
	~lp.setFunc(val, {arg k, v;
		if (v > 0) {
			if (quantMode > 0) {
				~tap.collect(_.recall(i));
			} {
				TempoClock.default.schedAbs(TempoClock.default.nextBar, {  ~tap.collect(_.recall(i));  });
			};
		};
		~lp.setState(k, v);
	});
};


//SEND OSC + LED
~tap.size.do{arg id;
	~tap[id].func[0] = {arg i, t;
		var ii = i + (id*16);
		fork{
			if (~sendOSC.notNil) {~sendOSC.sendMsg('/LED/tapClock', id, 1);};
			if (~lp.notNil) {
				if (~tap[id].mute[ii] == 0) {
					~lp.setColor(ii, 30, 100);   //NOT muted
				} {
					~lp.setColor(ii, 33, 0); //muted
				};
				~lp.setState(ii, 1);
			};
			t[1].wait;
			if (~sendOSC.notNil) {~sendOSC.sendMsg('/LED/tapClock', id, 0);};
			if (~lp.notNil) {
				if (~tap[id].mute[i] == 0) {
					~lp.setColor(ii, 100, 100);
				} {
					~lp.setColor(ii, 100, 0);
				};
				~lp.setState(ii, 0);
			}
		};
	};
};




TempoClock.default.schedAbs(0, {arg i, t;
	fork{
		if (~sendOSC.notNil) {  ~sendOSC.sendMsg('/LED/tempo', 1); };
		~lp.setState(104, 1);
		// 0.1.wait;
		(TempoClock.default.tempo.reciprocal * 0.5).wait;
		if (~sendOSC.notNil) {  ~sendOSC.sendMsg('/LED/tempo', 0); };
		~lp.setState(104, 0);
	};
	1.postln;
});




~setArgs = {arg key, val;
	~held.do{arg heldSteps, id;
		heldSteps.do{arg i, v;
			~tap[id].args[i][key] = val;
			[id, i, key, val].postln;
		};
	};
};

~setArgsRel =  {arg key, val;
	~held.do{arg heldSteps, id;
		heldSteps.do{arg i, v;
			~tap[id].args[i][key] = ~tap[id].args[i][key] * val;
			[id, i, key, val].postln;
		};
	};
};


MIDIdef.cc(\nk2, {arg ...msg;
	if (msg[2] == 4) {                                   //scene 2
		msg[0] = msg[0] / 127;
		msg.postln;
		case
		//FADERS
		{msg[1] == 0} { ~setArgs.(\tfreq, msg[0].linexp(0,1, 1/32, 20)) }
		{msg[1] == 1} { ~setArgs.(\rate, msg[0].linexp(0,1,1/12,12)) }
		{msg[1] == 2} { ~setArgs.(\tfreqMod, msg[0]*msg[0]*120) }
		{msg[1] == 3} { ~setArgs.(\rateMod, msg[0]*msg[0]*120) }
		{msg[1] == 4} { ~setArgs.(\mDuty, msg[0]*1.5) }
		{msg[1] == 5} { ~setArgs.(\mSkew, msg[0]) }

		{msg[1] == 6} { ~setArgs.(\duty, msg[0].linexp(0,1,1/64,6)) }
		{msg[1] == 7} {
			~held.do{arg hs, id;
				if (hs.size > 0) { ~tap[id].speed = msg[0].linlin(0,1,1/8,6) };
			};
		}
		//POTS
		{msg[1] == 8} {  ~setArgsRel.(\tfreq, msg[0 * 2]) }
		{msg[1] == 9} {  ~setArgsRel.(\rate, msg[0] * 2) }
		{msg[1] == 10} {  ~setArgsRel.(\tfreqMod, msg[0] * 2) }
		{msg[1] == 11} {  ~setArgsRel.(\rateMod, msg[0] * 2) }
		// {msg[1] == 12} {  ~setArgs.(\mDuty, msg[0]) }
		// {msg[1] == 13} {  ~setArgs.(\mSkew, msg[0]) }
		{msg[1] == 14} {  ~setArgs.(\amp, msg[0]) }
		{msg[1] == 15} {  TempoClock.default.tempo = msg[0].linexp(0,1, 1/8, 6)  }
		//BUTTONS
		;
	};
});
)

~mix.set(\inAmp, 0)


s.plotTree