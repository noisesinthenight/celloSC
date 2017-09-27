SynthDef(\mod, {arg inBus, outBus, fBus, aBus, bufnum, lag = 0.2,
	track = 0, freqLag = 0, ampMod = 0, ampLag = 0, ampSkew = 0,
	t_start = 1, t_stop, ovr = 1, feed = 0, t_reset, rate = 1;
	var inSig, aSig, fSig, isRec, end, pos, pPos, pSig;
	inSig = K2A.ar(In.kr(inBus), 3).lag(lag);

	aSig = LagUD.kr(In.kr(aBus), ampLag * ampSkew, ampLag * (1 - ampSkew));
	fSig = In.kr(fBus);
	rate = Lag.kr(Select.kr(track, [ rate, fSig * rate ]), freqLag); //pitchTrack
	rate = rate + (rate * aSig * ampMod);


	isRec = SetResetFF.kr(t_start, t_stop);
	end = Gate.ar(Sweep.ar(t_start, BufSampleRate.ir(bufnum)), isRec);
	pos = Select.ar(isRec, [
		Phasor.ar(t_stop + t_reset, BufRateScale.kr(bufnum), 0, end, 0),
		end
	]).wrap(0, BufFrames.ir(bufnum));
	pPos = Phasor.ar(t_stop + t_reset, BufRateScale.kr(bufnum) * rate, 0, end, 0);
	isRec = (isRec + ovr).clip(0, 1);

	pSig = BufRd.ar(3, bufnum, pPos, 1, 4);
	inSig = LeakDC.ar(inSig + (pSig * feed)).tanh * isRec.clip(0,1).lag(0.01);
	BufWr.ar(inSig, bufnum, pos * isRec);

	Out.ar(outBus, pSig);
}).add;

~modBuf = Buffer.alloc(s, 3 * s.sampleRate, 3);
s.sync;
~mod = Synth(\mod, [\inBus, ~bow.accBus, \fBus, ~analysis[0].freqBus, \aBus, ~analysis[0].ampBus, \outBus, ~modBus, \bufnum, ~modBuf]);

//AUTO RECORD when bow is moving
~bow.isMovingFunc[0] = {arg msg;
	if (msg > 0) { ~mod.set(\t_start, 1) } { ~mod.set(\t_stop, 1) };
};

