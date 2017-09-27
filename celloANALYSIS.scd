// ~analysis.aBus[i]  DO THIS SO CAN MAKE FUNCTIONS ABOUT AVG OF ALL INPUTS ?
// ~analysis.freq

// ADD TRANSFER FUNCTIONS
// DETECT STEEPNESS / SLOPE OF ATTACK (is it bowed or plucked)
// AVERAGE OVER DURATION OF ONSET when onset == 0


(
~analysis = () ! 2;

~analysis.size.do{arg i;
	~analysis[i].inBus = ~inBus.subBus(i);
	~analysis[i].aBus = Bus.control(s, 3);
	~analysis[i].freqBus = { ~analysis[i].aBus.subBus(0) };
	~analysis[i].ampBus = { ~analysis[i].aBus.subBus(1) };
	~analysis[i].noiseBus = { ~analysis[i].aBus.subBus(2) };


	~analysis[i].synths = 	{arg inBus, outBus, bufnum, replyID,
		thresh = 0.3, att = 0.033, rel = 0.16,
		onThresh = 6, onRel = 0.1, freqSus = 0;
		var inSig,   ampSig, above, onset,   chain, freqSig, hasFreq, noiseSig;
		// var pos;
		inSig = InFeedback.ar(inBus);
		inSig = HPF.ar(inSig, 60);

		//AMP
		ampSig = Amplitude.ar(inSig, att, rel).ampdb.linlin(-60, 0, 0, 1);
		above = ampSig > thresh;
		onset = Trig.ar(Slope.ar(ampSig).lag(onRel) > onThresh, 0.001);

		//FFT
		// #freqSig, hasFreq = Tartini.kr(inSig, thresh, 2048, 0, 1024, 0.5);
		chain = FFT(LocalBuf(4096, 1), inSig);
		#freqSig, hasFreq = FFTPeak.kr(chain);  //center frequency
		freqSig = Select.kr(freqSus, [freqSig, Latch.kr(freqSig, DelayN.ar(onset, 0.1, 0.1))]);
		noiseSig = SpecFlatness.kr(chain); //noise == 1, sine == 0


		//REC
		// pos = Phasor.ar(0, BufRateScale.kr(~tempBuf), 0, BufFrames.kr(~tempBuf));
		// BufWr.ar(SinOsc.ar(freqSig*6)*inSig, ~tempBuf, pos);
		// RecordBuf.ar(K2A.ar([freqSig, ampSig, noiseSig]), bufnum);

		//OUT
		Out.kr(outBus, [freqSig, ampSig, noiseSig]);
		SendReply.ar(Changed.ar(above), '/above', [above, freqSig, ampSig, noiseSig], replyID);
		// SendReply.ar(onset, '/onsets', [above, freqSig, ampSig, noiseSig, pos], replyID);
		SendReply.ar(onset, '/onsets', [above, freqSig, ampSig, noiseSig], replyID);
	}.play(args: [\inBus, ~analysis[i].inBus, \outBus, ~analysis[i].aBus, \replyID, i]);

};


OSCdef(\analysis0, {arg msg;
	// msg.postln;

	// STORE ONSETS HERE ! ! ! !


	//TRIGGER EXTERNAL FUNCTION
	// if (~onsetFunc.notNil) { ~onsetFunc.(msg); };
	// if (~sendOSC.notNil) { ~sendOSC.sendMsg('/LED/onset', msg[3]); }
}, '/onsets');


OSCdef(\analysis1, {arg msg;
	// msg.postln;


	//TRIGGER EXTERNAL FUNCTION
	if (~onsetFunc.notNil) { ~onsetFunc.(msg); };
	if (~sendOSC.notNil) { ~sendOSC.sendMsg('/LED/onset', msg[3]); }
}, '/above');


)



/*
~analysis[0].inBus
~analysis[0].aBus
~analysis[0].freqBus.getSynchronous
~analysis[0].ampBus.getSynchronous
~analysis[0].noiseBus.getSynchronous

~analysis[0].rec
~analysis[0].synths.set(\rel, 0.18)
*/


