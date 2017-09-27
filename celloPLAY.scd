(
~play = () ! 2;
~play.size.do{arg i;
	~play[i].events = Array.fill(8, {arg ii;
			(
				instrument: \playOnce,
				outBus: ~playBus[i], modBus: ~modBus.subBus(i),
				bufnum: ~recLoop[i].bufnum, start: 0, end: ~recLoop[i].length,
				rate: 1, dur: ~recLoop[i].length / s.sampleRate, duty: 4, skew: 0.3, amp: 1
			);
	});

	~play[i].start = 0;
	~play[i].end = ~play[i].events.size;
	~play[i].speed = 1;
	~play[i].reverse = 0;
	~play[i].random = 0;
	~play[i].args = {arg self, args_, id;
		if (args_.isNil) { self.events } {
			if (id.notNil) {
				self.events[id].putPairs(args_);
			} {
				self.events.size.do{arg i;   self.events[i].putPairs(args_);  }
				// self.events = args_.deepCopy;
			}
		}
	};

	~play[i].task = Routine.new({
		inf.do{
			~play[i].events.size.do{arg ii;
				var waitTime;
				if (~play[i].random > 0) {
					ii = rrand(~play[i].start, ~play[i].end) % ~play[i].events.size;
				} {
					ii = (((ii+~play[i].start) % ~play[i].end) + ~play[i].start) % ~play[i].events.size;
				};

				// ~play[i].events[ii].play;
				s.makeBundle(s.latency, { ~play[i].events[ii].play });

				waitTime = ~play[i].events[ii][\dur] * ~play[i].speed.reciprocal;
				// [i, waitTime, speed].postln;
				waitTime.yield;
				waitTime.clip(0.03125, 30).wait;
			};
		}
	});



};


//LINK TO  ~recLoop
~newLoopFunc = {arg msg;
	// msg.postln;
	~play[msg[0]].args.collect(_.[\end] = msg[1]);
	~play[msg[0]].args.collect(_.[\dur] = msg[1] / s.sampleRate);
};

~loopFunc = {arg msg; ~play[msg[0]].task.next; };
)


/*
~recLoop.bufnum[0].zero
~recLoop.rec(1, 0)
~recLoop.rec(0, 0)
~recLoop.synths[0].set(\ovr, 1, \feed, 0.6)
~play[0].args[0].play

~play[0].task.play
~play[0].task.stop

~play[0].args([\duty, 2, \skew, 0.5])
~play[0].args([\ffreq, {exprand(120, 3300)}])
~play[0].args([\res, 0.7, \fMix, 0.1])
~play[0].args([\rateMod, 1, \posMod, , \ffreqMod, 0])
~play[0].args([\mSrc, 0.5, \mDuty, {rrand(0.19, 0.06)}, \mSkew, 0, \mBus, 0])

~play[0].args.collect(_.[\duty] = 3)
~play[1].args.collect(_.[\mSrc] = 1)
~play[1].args.collect(_.[\mBus] = ~modBus.subBus(1))
~play[1].args.collect(_.[\mDuty] = 0.5)
~play[0].args.collect(_.[\mSkew] = 0.9)
~play[1].args.collect(_.[\rateMod] = 6)
~play[0].args.collect(_.[\rate] = 1)
~play[1].args.collect(_.[\rate] = Scale.phrygian.ratios.choose )
~play[0].args.collect(_.[\rate] = Scale.phrygian.ratios.choose.neg * {[1, 12, 4].choose * 0.5})
~play[0].args.collect(_.[\skew] = {rrand(0.5, 0.9)})

~recLoop.synths[0].set(\end, ~recLoop.length[0] * 1.5)

(
[0, 4].do{arg v;
~play[0].args([\ffreq, {exprand(60, 120)}, \rate, 0.5, \duty, 0.1, \skew, 0], v)
};
[1, 6].do{arg v;
~play[0].args([\ffreq, {exprand(660, 12000)}, \fMix, 0.6, \rate, 2, \duty, 0.01, \skew, 0], v)
}
)
// --set immediately
// --set on next step
// --set on next repetition
// --SET SEQ ARGS FOR ONLY ONE REPEAT THEN GO BACK TO PREVIOUS !!





~pedals.gates[1][4] = 1


MAP TO LAUNCHPAD


// -   -   -   PLAY   -    -   - //

//SUBDIVISION SEQ
(
x = {arg divs = 4, id = 0;
var arr = Array.fill(divs, {arg i;
(
instrument: \playOnce,
bufnum: ~recLoop.bufnum[id],
start: ~recLoop.length[id] * (i / divs),
end: ~recLoop.length[id] * ((i+1)/divs),
dur: (~recLoop.length[id] /s.sampleRate) / divs,
duty: 2, skew: 0.5, amp: 1,
)
});
~play[id].end(arr.size);
~play[id].args(arr);
// ~play.args.size.do{arg i;   ~play.args[i].putPairs(arr);  };
// ~play.args = arr;

// ~play[0].args.do{arg v, i;  v.putPairs(arr[i]) };  // <<<< should merge not replace OR optional then can use as reset
// ~e = arr;
arr.postln;
}
)

x.(12, 0)
~play.args.size



*/
// COLLECT FREQUENCIES make scale/note pool


// SEQUENCE ARG CHANGES
// --set immediately
// --set on next step
// --set on next repetition
// --SET SEQ ARGS FOR ONLY ONE REPEAT THEN GO BACK TO PREVIOUS !!
// ----momentary for transposing rate
//
// plug launchpad into cello for creating patterns, more detail ---monome modules  " : ) "
//
// polyphonic  ringmod (hold pitches)


// MAKE KICK + SNARE SYNTHDEFS
// --trigger with multiband onsets?
//
//
// RESET PLAYBACK WHEN ONSET??
// ~onsetFunc = {~recLoop.set(\t_reset, 1)}
//
// ONSET TRIGGERS RECORDING -fixed duration?
// PEDALS == RATE + AMPLITUDE OF PLAYBACK
// BOW == MODULATION

/*
~play[0].task.next
~play[0].task.play

I WONDER IF DRUMMERS PERCIEVE REGULARITY IN THINGS
CYCLES, REPETITION
EVERYTHIN IN RELATION TO REPETITION?
not E V E R Y T H I N G obviously
OR JUST A SENSE OF MOMENTUM
HOW IS IT DIFFERENT
MAYBE IT ISNT
JUST
P     U     L     S      E
*/

