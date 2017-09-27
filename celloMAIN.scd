add button to clear +stop both recorders
freqLag to pedal?



TODO BEFORE NEXT GIG:

VOLUME/COMPRESSION ON INPUT
-FIX DELAY TIME/analysis when pitch tracked  (dc when max time + pitch track)
(CHECK SCALING OF SLIDER!!AT MAX VALUE)

-FADE OUT ON PLAY/STOP LOOP


-better noise curve + separate smoothing control (scale also by noise amnt?)

-map freq smoothing somewhere
-TAPSEQ -polymode (mult/div clocks), -seqmode
-SIDECHAIN FX DRYWET TO AMP?



loop strings
increase noise +ringmod
crucnchy solder pad
bring in delay tones
tones
mallet+noise



BOW BUTTONS + HOLD pedal gates
PITCH PLAUYBACK  +REVERSE
PIEZO PRESSURE BARS on cello body



4x   STRING / PICKUP / MIC per SEQ
4x   PERC MOULDs



(
~path = "/Users/dan/!MASTERS/BLOG/2017/August/celloSC/";
// ~path = "/home/pi/celloSC/";
if (~sendOSC.isNil) { ~sendOSC = NetAddr.new("127.0.0.1", 88888); };

(~path +/+ "celloFXSYNTHS.scd").loadPaths[0];
(~path +/+ "celloRECSYNTHS.scd").loadPaths[0];

Server.default.options.memSize = 103936;
// Server.default.options.memSize = 207872;`
Server.default.waitForBoot({
	fork{
		if (~modBus.isNil) {
			~modBus = Bus.audio(s, 3);
			~inBus = Bus.audio(s, 2);
			~fxBus = Bus.audio(s, 2);
			~playBus = Array.fill(3, { Bus.audio(s, 2) });
			~mBus = Bus.audio(s, 2);
		};

		~inGroup = Group.new;
		~fxGroup = Group.after(~inGroup);
		~recGroup = Group.after(~fxGroup);
		~mGroup = Group.after(~recGroup);
		s.sync;


		~input = {arg amp = 1;
			// var sig = {SoundIn.ar(0)} ! 2;
			var sig = SoundIn.ar([0, 0]);
			sig = CompanderD.ar(sig, 0.3, 1, 0.27, 0.003, 0.14) * amp;
			//ADD EQ
			Out.ar(~inBus, sig);
			Out.ar(~fxBus, sig);
		}.play(~inGroup);

		s.sync;


		(~path +/+ "celloANALYSIS.scd").loadPaths[0];
		(~path +/+ "celloTAPSEQ.scd").loadPaths[0];
		(~path +/+ "celloRECORD.scd").loadPaths[0];
		s.sync;
		2.wait;


		(~path +/+ "celloFX.scd").loadPaths[0];
		(~path +/+ "celloPLAY.scd").loadPaths[0];
		s.sync;
		~fx.import; //import presets from file

		~mix = {arg inAmp = 1, fxMix = 1, verbMix = 0.5,  inVerb = 0, playVerb = 0, time = 1, feed = 0.6, ffreq = 20000;
			var inSig, pSig, rSig, local, outSig;
			inSig = SelectX.ar(fxMix, [In.ar(~inBus, 2), In.ar(~fxBus, 2)]) * inAmp;
			pSig = In.ar(~playBus[0], 2) + In.ar(~playBus[1], 2) +  In.ar(~playBus[2], 2);
			//REVERB
			rSig = (inSig * inVerb) + (pSig * playVerb);
			rSig = HPF.ar(rSig, 120);
			rSig = rSig + LocalIn.ar(2);
			7.do{  rSig = AllpassC.ar(rSig,  0.06, Rand(0.001, 0.06) * time.lag(0.05), 3);  };
			rSig = LPF.ar(rSig * feed, ffreq);
			LocalOut.ar(rSig.tanh);
			outSig = SelectX.ar(verbMix, [ (inSig+pSig), rSig ]).tanh;
			Out.ar(0,  outSig);
		}.play(~mGroup);

		s.sync;

		(~path +/+ "celloPEDALS.scd").loadPaths[0];
		(~path +/+ "celloBOW.scd").loadPaths[0];
		s.sync;
		(~path +/+ "celloBOWOSC.scd").loadPaths[0];
		s.sync;

		MIDIIn.connectAll;
		(~path +/+ "nkMap.scd").loadPaths[0];

	};
})
)

~mix.set(\inAmp, 0.5)


~input
~analysis[0]
~analysis[1]
~fx.synths

~tap[0]
~tap[1]
~recLoop[0]
~recLoop[1]

~pedals
~bow
~mod


~fx.args([\mix, 1])
celloANALYSIS.scd
HOW TO DEAL WITH MULTICHANNEL ANALYSIS +FX???     <  < < < < <  <  GROUP  ~analysis.aBus[i]    THEN ADD methods/busses for average of all inputs?
or would be FX PER STRING ????
// ADD STORING ONSETS+LINK TO RECSEQ

VOSIM for ringmod?



(
if (~sendOSC.notNil) {
	fork{loop{
		~sendOSC.sendMsg('/analysis',
			~analysis[0].freqBus.getSynchronous,
			~analysis[0].ampBus.getSynchronous,
			~analysis[0].noiseBus.getSynchronous,
			~analysis[1].freqBus.getSynchronous,
			~analysis[1].ampBus.getSynchronous,
			~analysis[1].noiseBus.getSynchronous,
		);
		~sendOSC.sendMsg('/loop',
			~recLoop[0].posBus.getSynchronous /~recLoop[0].length,
			~recLoop[1].posBus.getSynchronous /~recLoop[0].length,
		);
		0.1.wait;
	}}
};
)


~recLoop[0].rec(1)
~recLoop[0].rec(0)
~recLoop[0].synths.set(\ovr, 1, \feed, 0.6)
~play[0].task.reset
~play[0].task.play
~play[0].task.stop
~play[0].args[0].play
~recLoop[0].bufnum.zero

~recLoop[1].posBus.getSynchronous
s.meter
s.plotTree
s.makeGui





(
//EXPORT
f = File(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "text.txt", "w");
~fx.presets.size.do{arg id;
	f.write("% \n".format(id));
	~fx.presets[id].size.do{arg fx;
		~fx.presets[id][fx].keysValuesDo{arg k, v;
			[id, fx, k, v].postln;
			f.write("%,%,%,%".format(id,fx,k,v));
			f.write("\n");
		};
	};
};
f.close;
)


//IMPORT
(
CSVFileReader.read(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "text.txt").postcs.do{arg v, i;
	// [v, i].postln;
	if (v.size == 1) {
		~fx.presets[v[0].asInteger] = Array.fill(3, { Dictionary.new });
	} {
		// v[1].postln;
		~fx.presets[v[0].asInteger][v[1].asInteger][v[2].asSymbol] = v[3].asFloat;
	}
}
)


~fx.presets[0][0][\noise]   //doesnt work
~fx.presets[0][0]


/*f = File(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "text.txt", "w");
f.write(~fx.presets.asCompileString)
f.close
x = CSVFileReader.read(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "text.txt")
x[0][0]*/

~fx.export
~fx.import
~fx.presets.size

~fx.args([\mix, 1])
~fx.store(1)
~fx.recall(0)
~fx.presets[1][0][\mix]

~fx.args = ~fx.presets[1].deepCopy
~fx.args(~fx.presets[1][2], 2) ///this works  but recall doesnt

~fx.presets[1][0][\mix]
~fx.args[0][\mix]


//export
~fx.presets.writeArchive(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "text1.txt")
//import
~fx.presets = Object.readArchive(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "text1.txt")



~fx.args([\freqLag, 30])
~fx.args([\freqLag, 3.6])
~fx.args([\freqSkew, 0])
~fx.args([\freqSkew, 0.5])








Scale.directory
Scale.aeolian.ratios
Scale.bartok
Scale.choose
~play[0].args([\rate, 0.5])
~play[0].args([\amp, 1])
(
2.do{arg o;
~play[o].args.size.do{arg i;
		var fund = 0.25 * (i+1);
		// ~play[o].args([\rate, Scale.aeolian.ratios.choose * fund], i);
		// ~play[o].args([\rate, Scale.bartok.ratios.choose * fund], i);
		~play[o].args([\rate, Scale.gong.ratios.choose * fund], i);
		// ~play[o].args([\rate, Scale.harmonicMinor.ratios.choose * fund, \duty, 3, \skew, 0.9], i);
		// ~play[o].args([\duty, 8, \skew, 0.9], i);
}
}
)

~mix.set(\inAmp, 0.5)
~play[0].args([\duty, 6, \skew, 0.9])
~play.collect(_.speed = 0.25)


s.makeGui