// TAPSEQ
(
SynthDef(\step, {arg inBus, mBus, outBus, bufnum, start, end, replyID,
	rec = 1, feed = 0.76, tfreq = 0, rate = 1, t_reset,
	mSrc = 0, mDuty = 1, mSkew = 0, rateMod = 0, tfreqMod = 0,
	envDur = 1, envSkew = 0.5, amp = 1;
	var env, mEnv, mSig, inSig, pSig, trig, pos, ppos;

	env = EnvGen.ar(Env.linen(envDur * envSkew, 0, envDur * (1 - envSkew)), doneAction: 2);
	mEnv = EnvGen.ar(Env.linen((envDur * mDuty) * mSkew, 0, (envDur * mDuty) * (1-mSkew)));
	mSig = InFeedback.ar(mBus);
	mSig = Select.ar(mSrc, [mEnv, mEnv * mSig, mSig]);
	tfreq = tfreq + (tfreq * mSig * tfreqMod);
	rate = rate + (rate * mSig * rateMod);

	// inSig = SoundIn.ar([0,1]);
	inSig = InFeedback.ar(inBus, 2);

	trig = Impulse.ar(tfreq) + t_reset;
	pos = Phasor.ar(trig, BufRateScale.kr(bufnum), start, end, start);
	// RecordBuf.ar(inSig, bufnum, start, 1, feed, rec, 1, trig);
	RecordBuf.ar(inSig, bufnum, start, 1, feed, rec, 1, t_reset);

	pSig = PlayBuf.ar(2, bufnum, rate, trig, start, 1);

	/*	ffreq = ffreq + ((ffreq * mSig) * ffreqMod);
	res = 1 - res;
	pSig = SelectX.ar(fMix, [
	pSig,
	BPF.ar(pSig, ffreq, res, (res ** -1) * (400 / ffreq ** 0.5))
	]);*/

	OffsetOut.ar(outBus, pSig * env * amp);
}).add;




~tap = () ! 2;

2.do{ arg id;
	//RECORDING
	~tap[id].bufnum = Array.fill(8, { Buffer.alloc(s, 6 * s.sampleRate, 2) });
	~tap[id].data = Array.fill(8, { [1, 1] });
	~tap[id].startTime = 0;  ~tap[id].lastTime = 0;
	~tap[id].index = -1;
	~tap[id].start = 0; ~tap[id].end = ~tap[id].bufnum.size;


	~tap[id].rec = {arg self, val;
		var currentTime = Main.elapsedTime;
		if (val > 0) {
			self.index = (self.index + 1).wrap(0, self.end - 1);
			self.startTime = currentTime;
			if ((self.index == 0) && ((self.startTime - self.lastTime) > 6))  {
				//first startTime to 0 if START was set more than 6 seconds ago
				self.lastTime = self.startTime;
			};
		} {
			self.data[self.index] = [self.startTime - self.lastTime, currentTime - self.startTime];
			self.lastTime = self.startTime;
			[self.index, self.data[self.index]].postln;
		};
	};


	~tap[id].setStart = {arg self;
		self.lastTime = Main.elapsedTime;
		self.index = -1;
	};

	~tap[id].clearData = {arg self;
		if (self.task.isPlaying) { self.task.stop };
		self.data = Array.fill(8, { [1, 1] });
		self.index = -1;
	};

	//just record duration
	~tap[id].recStep = {arg self, val, step;
		var currentTime = Main.elapsedTime;
		if (val > 0) {
			self.startTime = currentTime;
		} {
			self.data[step][1] = currentTime - self.startTime;
			self.data[(step + 1).wrap(0, self.data.size)][0] = currentTime - self.startTime;    //change previous step waittime
			// self.data[step] = [currentTime - self.startTime, currentTime - self.startTime];
		};
	};




	//PLAYBACK
	~tap[id].quantDiv = 0;
	~tap[id].speed = 1;
	// ~tap[id].duty = Array.fill(~tap[id].data.size, { 2 });
	~tap[id].dev = [0,0];
	~tap[id].func = [nil];
	~tap[id].mute = Array.fill(~tap[id].bufnum.size, { 0 });

	~tap[id].args = Array.fill(~tap[id].bufnum.size, {arg i;
		(
			instrument: \step, sustain: 0,
			inBus: ~fxBus, mBus: ~fxBus, outBus: ~playBus[2],
			bufnum: ~tap[id].bufnum[i], rec: 1,
			start: 0, end: ~tap[id].bufnum[i].numFrames,
			envDur: ~tap[id].data[i][1], envSkew: 0.5, duty: 2,
		);
	});

	~tap[id].playStep = {arg self, i;
		var tempTime = [1, 1];
		tempTime[0] = ~tap[id].data[i][0].round(~tap[id].quantDiv).clip(~tap[id].quantDiv, inf);     //quantise
		tempTime[1] = ~tap[id].data[i][1] * ~tap[id].args[i][\duty];                                                          //duty
		tempTime = tempTime * (~tap[id].speed * TempoClock.default.tempo).reciprocal;            //speed
		tempTime = tempTime + rrand(~tap[id].dev[0], ~tap[id].dev[1]);									            //deviation
		//PLAY SYNTH
		~tap[id].args[i][\envDur] = tempTime[1];
		// s.makeBundle(s.latency, { ~tap[id].args[i].play });
		//RUN FUNCTION
		if (~tap[id].func[0].notNil) { ~tap[id].func[0].(i, tempTime); };

	};


	~tap[id].task = Task.new({
		inf.do{arg i;
			// ~tap[id].data.size.do{arg i;
			var tempTime = [1, 1];
			var ii = i.wrap(0, ~tap[id].args.size);
			// var ii = (((i + ~tap[id].start) % ~tap[id].end) + ~tap[id].start) % ~tap[id].args.size;

			// ~tap[id].playStep(ii);

			tempTime[0] = ~tap[id].data[ii][0].round(~tap[id].quantDiv).clip(~tap[id].quantDiv, inf);    //quantise
			tempTime[1] = ~tap[id].data[ii][1] * ~tap[id].args[ii][\duty];                                                         //duty
			tempTime = tempTime * (~tap[id].speed * TempoClock.default.tempo).reciprocal;            //speed
			tempTime = tempTime + rrand(~tap[id].dev[0], ~tap[id].dev[1]);									            //deviation
			tempTime[0].clip(0.001, 16).wait;

			if (~tap[id].mute[ii] == 0) {
				//PLAY SYNTH
				// s.makeBundle(s.latency, { ~tap[id].args[id][ii].play });
				~tap[id].args[ii][\envDur] = tempTime[1];
				s.makeBundle(s.latency, { ~tap[id].args[ii].play });
			};

				//RUN FUNCTION
				if (~tap[id].func[0].notNil) { ~tap[id].func[0].(ii, tempTime); };
				// [ii, tempTime].postln;

			// };
		}
	});






	//PRESETS
	~tap[id].presets = Dictionary.new;
	~tap[id].store = {arg self, i;
		~tap[id].presets[i] = [
			~tap[id].args.deepCopy,
			~tap[id].data.deepCopy,
			~tap[id].speed.deepCopy,
			// ~tap[id].duty.deepCopy,
			~tap[id].dev.deepCopy,
			~tap[id].task.isPlaying
		];
	};
	~tap[id].recall = {arg self, i;
		if (id.isNil) { id = 0 };
		~tap[id].args = ~tap[id].presets[i][0].deepCopy;
		~tap[id].data = ~tap[id].presets[i][1].deepCopy;
		~tap[id].speed = ~tap[id].presets[i][2].deepCopy;
		// ~tap[id].duty = ~tap[id].presets[i][3].deepCopy;
		~tap[id].dev = ~tap[id].presets[i][3].deepCopy;
		if ((~tap[id].presets[i][4] == true) && (~tap[id].task.isPlaying == false)) { ~tap[id].task.play } { ~tap[id].task.stop };
	};

	~tap[id].store(0); //store init state


};
)




s.plotTree
~tap[0].setStart(1)
~tap[0].rec(1)
~tap[0].rec(0)
~tap[0].rec(1, 0)
~tap[0].rec(0, 0)
~tap[0].bufnum[0].plot
~tap[0].data[7]
~tap[0].args[0][\rec] = 0
~tap[0].args[0][\outBus] = 0
~tap[0].args[0].play
~tap[0].playStep(0)


~tap[0].task.play(doReset: true)
~tap[0].task.stop

TempoClock.default.schedAbs(TempoClock.default.nextBar, {~tap[0].task.play})
TempoClock.default.schedAbs(TempoClock.default.nextBar, {~tap[0].task.stop})

TempoClock.default.tempo = 1

~tap[0].speed = 1/6
~tap[0].dev = [-0.1, 0.1]
~tap[0].quantDiv = 0
~tap[0].start = 0
~tap[0].end = 8

~tap[0].args.collect(_[\rec] = 1)
~tap[0].args.collect(_[\feed] = 0.37)

~tap[0].args.collect(_[\amp] = 1)
~tap[0].args.collect(_[\duty] = rrand(0.1, 8))
~tap[0].args.collect(_[\outBus] = 0)

~tap[0].args.collect(_[\tfreq] = rand(0, 8))
~tap[0].args.collect(_[\rate] = 1/2)
~tap[0].args.collect(_[\rate] = Scale.dorian.ratios.choose * 4)
~tap[0].args.collect(_[\rate] = Scale.bartok.ratios.choose * 0.5)
~tap[0].args.collect(_[\rate] = rrand(1/2,2))

~tap[0].args.collect(_[\mDuty] = {rrand(0.01, 0.04)})
~tap[0].args.collect(_[\mSkew] = 0)
~tap[0].args.collect(_[\rateMod] = 0.1)
~tap[0].args.collect(_[\rateMod] = 120)
~tap[0].args.collect(_[\tfreqMod] = 100)

~tap[0].args.collect(_[\envSkew] = 0.01)


~tap[0].presets[1]
~tap[0].store(1)
~tap[0].recall(1)


s.meter
s.makeGui
*/

