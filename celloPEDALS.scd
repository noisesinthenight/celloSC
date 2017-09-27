// KILL SWITCH!!!! for making large  jumps in value, temporary disable all gates
// var val = 1; ~pedals.gates[0].collect(val)
// resets all to 1

// ADD QUANTISATION subdivisions, resolution

// DELAY MAPPING
// ~pedals.gates[1][2] = 1
// ~pedals.scale[1][2]
//
// ~pedals.val[1][2]
// ~pedals.env[1][2].at(~pedals.val[1][2])
// ~pedals.env[1][2] = Env.pairs([[0, 0.01], [0.09, 0.16],[0.16, 0.33], [0.3, 0.5], [0.5, 0.8], [0.74, 1.5], [1, 6]], \exp)
// ~pedals.env[1][2] = Env.pairs([[0, 0.01], [0.09, 0.16],[0.16, 0.33], [0.3, 0.5], [0.5, 0.8], [0.74, 1.5], [1, 6]], \sin)
// ~pedals.env[1][2].plot

//REVERB MAPPING
// ~pedals.gates[1][3] = 1
// ~pedals.setVal(0.3, 1, 3)

(
var slots = [4, 5];
~pedals = (
	func: Array.fill(2, {arg i; Array.fill(slots[i], { nil }); }),
	val: Array.fill(2, {arg i; Array.fill(slots[i], { 1 }); }),
	scale: Array.fill(2, {arg i; Array.fill(slots[i], { 1 }); }),
	gates: Array.fill(2, {arg i; Array.fill(slots[i], { 0 }); }),

	env: [
		[
			Env.pairs([[0, 392.23], [1, 3136]], \exp),
			Env.pairs([[0, 0.03], [0.24, 13], [0.56, 60], [0.6, 100], [1, 8000]], \exp),
			Env.pairs([[0, 220], [1, 12000]], \exp),
			Env.pairs([[0, 392.23], [1, 16000]], \exp)
		], [
			Env.pairs([[0, 0], [1, 1]], \lin),
			Env.pairs([[0, 0.01], [0.25,0.18], [1, 1]], \lin),
			Env.pairs([[0, 0.01], [0.09, 0.16],[0.16, 0.33], [0.3, 0.5], [0.5, 0.8], [0.74, 1.5], [1, 6]], \exp),
			Env.pairs([[0, 0], [1, 1]], \lin),
			Env.pairs([[0, 0], [1, 1]], \lin)
		]
	],


	setVal: {arg self, val_, x_, y_;
		if (y_.isNil) {
			self.gates[x_].do{arg v, i;
				if (self.gates[x_][i] > 0) {
					self.val[x_][i] = val_;
					if (self.func[x_][i].notNil) {  self.func[x_][i].( self.val[x_][i] * self.scale[x_][i] );  };
					// self.func[x_][i].( self.env[x_][i].at(self.val[x_][i] * self.scale[x_][i]) );
				};
			};
		} {
			if (self.gates[x_][y_] > 0) {
				self.val[x_][y_] = val_;
				if (self.func[x_][y_].notNil) {  self.func[x_][y_].( self.val[x_][y_] * self.scale[x_][y_] );  };
			};
		}
	},

	setScale: {arg self, val_, x_, y_;
		if (y_.isNil) {
			self.scale[x_][i] = val_;
			if (self.func[x_][i].notNil) {  self.func[x_][i].( self.val[x_][i] * self.scale[x_][i] );  };
		} {
			self.scale[x_][y_] = val_;
			if (self.func[x_][y_].notNil) {  self.func[x_][y_].( self.val[x_][y_] * self.scale[x_][y_] );  };
		}
	},


	presets: Dictionary.new,
	store:{arg self, id_;
		if (id_.isNil) {id_ = self.presets.size};
		self.presets[id_] = [
			self.val.deepCopy,
			self.scale.deepCopy,
			self.gates.deepCopy,
		];
	},
	recall:{arg self, id_;
		if (self.presets[id_].notNil) {
			self.val = self.presets[id_][0].deepCopy;
			self.scale = self.presets[id_][1].deepCopy;
			self.gates = self.presets[id_][2].deepCopy;
		}
	}

);



//LEFT
~pedals.func[0][0] = {arg val;  ~fx.args([\freq, ~pedals.env[0][0].at(val), \transpose, val*2], 0); };
~pedals.func[0][1] = {arg val;  ~fx.args([\freq, ~pedals.env[0][1].at(val), \transpose, val*2], 1); };
~pedals.func[0][2] = {arg val;  ~fx.args([\ffreq, ~pedals.env[0][2].at(val), \ftranspose, val*2], 2); };
~pedals.func[0][3] = {arg val;  ~mix.set(\ffreq, ~pedals.env[0][3].at(val)); }; //reverb filter
//RIGHT
~pedals.func[1][0] = nil;
~pedals.func[1][1] = {arg val;  ~fx.args([\duty, ~pedals.env[1][1].at(val)], 1); };
~pedals.func[1][2] = {arg val;  ~fx.args([\time, ~pedals.env[1][2].at(val), \transpose, (1-val)*2], 2); };
~pedals.func[1][3] = {arg val;
	~mix.set(
		\inVerb, val.linlin(0,0.5, 0,1), \playVerb, val.linlin(0,0.7, 0,0.95),
		\time, val.linexp(0.3,1,0.25,0.76), \feed, val.explin(0.1, 1, 0.12, 0.9),
		\verbMix, val*0.94
	);
};

~pedals.func[1][4] = {arg val;  ~input.set(\amp, val*val); };



OSCdef(\pedals, {arg msg;
	msg[2] = msg[2] / 1023;
	msg.postln;
	case
	{msg[1] == 17} { ~pedals.setVal(msg[2], 0); }
	{msg[1] == 18} { ~pedals.setVal(msg[2], 1); };
}, '/pedals')
)

