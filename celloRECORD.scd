// USE SendReply INSTEAD OF .getSynchronous ??? IS IT FASTER ???

(
// fork{
SynthDef(\recLoop, {arg inBus, posBus, outBus, bufnum, start, end, replyID = -1,
	t_pos, rec = 0, ovr = 0, feed = 0.76, t_reset, rate = 1;
	var inSig, pos, pSig;
	inSig = InFeedback.ar(inBus, 2);

	pos = Phasor.ar(t_reset, BufRateScale.ir(bufnum), start, end, start);
	pos = pos.wrap(start, end);

	rec = (rec + ovr).clip(0,1);
	pSig = BufRd.ar(2, bufnum, (pos*rate).wrap(start,end), 4);
	BufWr.ar((inSig + (pSig * feed)) * rec.lag(0.01), bufnum, pos * rec);

	SendReply.ar(Trig.ar((HPZ1.ar(pos) < 0), 0.005), '/loop', rec, replyID);
	SendReply.ar(Trig.ar(t_pos), '/pos', [pos], replyID);
	Out.kr(posBus, pos);
	// Out.ar(outBus, pSig);
}).add;

s.sync;

~recLoop = () ! 2;
~newLoopFunc = nil;
~loopFunc = nil;

~recLoop.size.do{arg i;
	~recLoop[i].length = 12 * s.sampleRate;
	~recLoop[i].bufnum = Buffer.alloc(s, ~recLoop[i].length, 2);
	~recLoop[i].posBus = Bus.control(s, 1);
	s.sync;

	~recLoop[i].synths = 	Synth(\recLoop, [
		\inBus, ~fxBus, \posBus, ~recLoop[i].posBus, \outBus, ~playBus[i], \replyID, i,
		\bufnum, ~recLoop[i].bufnum, \start, 0, \end, ~recLoop[i].length
	], ~recGroup);



	//METHODS
	~recLoop[i].inBus = {arg self, val; self.synths.set(\inBus, val) };
	~recLoop[i].rec = {arg self, val;
		if (val > 0) {
			self.length = self.bufnum.numFrames;
			self.synths.set(\start, 0, \end, self.length, \t_reset, 1, \rec, val);
		} {
			// self.length =  self.posBus.getSynchronous;
			self.synths.set(\t_pos, 1, \rec, val);
			if (~newLoopFunc.notNil) {  ~newLoopFunc.([i, self.length]) };
		};
	};

	~recLoop[i].append = {arg self, val;
		if (val > 0) {
			self.synths.set(\start, self.length, \end, self.bufnum.numFrames, \t_reset, 1)
		} {
			// self.length = self.posBus.getSynchronous;
			self.synths.set(\t_pos, 1);
			self.synths.set(\start, 0, \end, self.length, \t_reset, 1);
			if (~newLoopFunc.notNil) {  ~newLoopFunc.([i, self.length]) };
		};
		self.synth.set(\rec, val);
	};



	~recLoop[i].double = {arg self;
		self.bufnum.copyData(self.bufnum, self.length, 0, self.length);
		self.length = (self.length * 2).clip(0, self.bufnum.numFrames);
		self.synths.set(\end, self.length);
		if (~newLoopFunc.notNil) {  ~newLoopFunc.([i, self.length]) };
	};

	~recLoop[i].half = {arg self;
		self.length = self.length * 0.5;
		self.synths.set(\end, self.length);
		if (~newLoopFunc.notNil) {  ~newLoopFunc.([i, self.length]) };
	};

	/*
	//copy all buffers into one buffer sequentially
	~recLoop[i].join = {arg self;
	var len = 0;
	self.bufnum.do{arg b, i;
	b.copyData(self.bufnum, len, 0, self.length[i]);
	len = len + self.length[i];
	};
	self.length = len;
	if (~newLoopFunc.notNil) {  ~newLoopFunc.([i, self.length) };
	};

	//mix all buffers to one buffer
	~recLoop[i].mix = {arg self;
	var arr = Array.fill(self.bufnum.size, { 0 });
	fork{
	self.bufnum.do{arg b, i;   b.loadToFloatArray(action: {arg array; arr[i] = array;})   };
	s.sync;
	self.bufnum.loadCollection(arr.sum);
	self.length = self.length.maxItem;
	if (~newLoopFunc.notNil) {  ~newLoopFunc.([i, self.length) };
	};
	*/
};



OSCdef(\newLoop, {arg msg;
	msg.postln;
	~recLoop[msg[2]].length = msg[3];
	~recLoop[msg[2]].synths.set(\start, 0, \end, msg[3], \t_reset, 1);
}, '/pos');

OSCdef(\loop, {arg msg;
	if (~loopFunc.notNil) { ~loopFunc.([msg[2], msg[3]]) };
	if (~sendOSC.notNil) {
		fork{
			~sendOSC.sendMsg("/LED/loop"++msg[2], 1);
			0.1.wait;
			~sendOSC.sendMsg("/LED/loop"++msg[2], 0);
		}
	};
}, '/loop')


// }
)



/*
~recLoop[0].inBus(~inBus)
~recLoop[0].bufnum
~recLoop[0].length
~recLoop[0].posBus.getSynchronous
~recLoop[0].synths.set(\posBus, ~recLoop[0].posBus)
~recLoop[0].synths.get(\end,{arg v; v.postln})


~recLoop[0].rec(0)
~recLoop[0].append(0)
~recLoop[0].double(0)
~recLoop[0].half(0)

~recLoop[0].bufnum.plot
~newLoopFunc = {arg m; m.postln}
~loopFunc = {arg m; m.postln}

// record pre/post fx
// ~recLoop.synths.collect(_.set(\inBus, ~inBus)); ~playLoop[0].args([\outBus, ~fxBus])
// ~recLoop.synths.collect(_.set(\inBus, ~fxBus));  2.do{arg i; ~playLoop[i].args([\outBus, ~playBus[i]]) };
*/