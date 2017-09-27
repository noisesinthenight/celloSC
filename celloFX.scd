// ---interpolate presets  +  current >< preset
// ---use dictionary .softSet fotr pickup paramaeters
// ~fxArgs[0].softSet(\freq, 11000, 0.05)


var args = [
	//filter
	Dictionary.newFrom([
		\inBus, ~fxBus, \fBus, ~analysis[0].freqBus, \aBus,  ~analysis[0].ampBus, \nBus, ~analysis[0].noiseBus, \mBus, ~modBus.subBus(2),
		\track, 0, \transpose, 1, \ampMod, 0, \extMod, 0,
		\freqFreeze, 0, \freqLag, 0, \ampLag, 0, \ampSkew, 0.12,
		\freq, 12000, \type, 0, \res, 0.1, \noise, 0, \mix, 0
	]),
	//ring
	Dictionary.newFrom([
		\inBus, ~fxBus, \fBus,  ~analysis[0].freqBus, \aBus, ~analysis[0].ampBus, \nBus, ~analysis[0].noiseBus, \mBus, ~modBus.subBus(1),
		\track, 0, \transpose, 1, \ampMod, 0, \extMod, 0,
		\freqFreeze, 0, \freqLag, 0, \ampLag, 0, \ampSkew, 0.12,
		\freq, 12000, \duty, 1, \noise, 0, \mix, 0
	]),
	//delay
	Dictionary.newFrom([
		\inBus, ~fxBus, \fBus,  ~analysis[0].freqBus, \aBus, ~analysis[0].ampBus, \nBus, ~analysis[0].noiseBus, \mBus, ~modBus.subBus(0),
		\track, 0, \transpose, 1, \ftrack, 0, \ftranspose, 1, \ampMod, 0, \extMod, 0,
		\freqFreeze, 0, \freqLag, 0, \ampLag, 0, \ampSkew, 0.12,
		\time, 0.1, \feed, 0.7, \noise,  0,
		\ffreq, 12000, \res, 0, \mix, 0
	])
];

var keys = [\filter, \ring, \delay];
var presets = Dictionary.newFrom([0, args.deepCopy]);
var presetFile;
var synths = Array.newClear(3);

synths[2] = Synth(keys[2], args[2].asKeyValuePairs, ~fxGroup);
synths[1] = Synth(keys[1], args[1].asKeyValuePairs, ~fxGroup);
synths[0] = Synth(keys[0], args[0].asKeyValuePairs, ~fxGroup);

~fx = (
	// args: { args },
	presets: { presets },
	synths: { synths },
	args: {arg self, args_, id_, fade_;
		if (args_.isNil) { args } {

			if (id_.isNil) {
				//ITERATE THROUGH ALL
				args.size.do{arg i;
					args[i].putPairs(args_);
					// args_.keysValuesDo{arg k, v;   if (v.isNaN == false) { synths[i].set(k, v) };  };
					if (fade_.isNil) {
						args_.keysValuesDo{arg k, v;	 synths[i].set(k, v)  };
					}{
						synths[i].set(\fade, fade_, \gate, 0);
						// synths[i].release;
						synths[i] = Synth(keys[i], args[i].asKeyValuePairs, synths[i], '\addBefore');
						// synths[i].moveAfter(synths[i-1]);

					};
				};

			} {
				args[id_].putPairs(args_);
				// args_.keysValuesDo{arg k, v;   if (v.isNaN == false) { synths[id_].set(k, v); }; }
				if (fade_.isNil) {
					args_.keysValuesDo{arg k, v;    synths[id_].set(k, v)  };
				} {

					synths[id_].set(\fade, fade_, \gate, 0);
					// synths[id_].release;
					synths[id_] = Synth(keys[id_], args[id_].asKeyValuePairs, synths[id_], '\addBefore');
					// synths[id_].moveAfter(synths[id_-1]);
				};
			};

		}
	},
	store: {arg self, id_;
		if (id_.isNil) { id_ = presets.size };
		presets[id_] = args.deepCopy;
	},
	recall: {arg self, id_, fade_;
		if (presets[id_].notNil) {
			args = presets[id_].deepCopy;
			synths.do{arg v, i;  self.args(presets[id_][i], i, fade_);  };
		}
	},

	import: {arg self, path;
		if (path.isNil) {
			presets = Object.readArchive(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "fxpresets.txt")
		} {
			presets = Object.readArchive(path);
		};
	},
	export: {arg self, path;
		if (path.isNil) {
			presets.writeArchive(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "fxpresets.txt")
		} {
			presets.writeArchive(path);
		};
	},

);



