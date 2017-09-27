SynthDef(\recLoop, {arg inBus, posBus, bufnum, start, end, replyID = -1,
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
	// Out.ar(0, pSig);
}).add;

SynthDef(\recOnce, {arg inBus, bufnum, start, end, feed = 0.8,
	gate = 1, att = 0.01, rel = 0.1, replyID;
	var env, sig, pos;
	env = EnvGen.ar(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
	sig = InFeedback.ar(inBus, 2);
	pos = Phasor.ar(gate, BufRateScale.kr(bufnum), start, end, start);
	RecordBuf.ar(sig, bufnum, start, 1, feed, 1 ,0, doneAction: 2);
	SendReply.ar(Trig.ar(1-gate), '/newStep', pos, replyID);
}).add;


SynthDef(\playOnce, {arg outBus, mBus, bufnum, start, end,
	rate = 1, dur = 1, duty = 1, skew = 0.5, amp  = 1,
	ffreq = 12000, res = 0.1, fMix = 0,
	mSrc = 1, mDuty = 1, mSkew = 0.01,
	rateMod = 0, posMod = 0, endMod = 0, ffreqMod = 0;
	var env, mEnv, mSig, pos, sig;
	env = EnvGen.ar(Env.linen((dur * skew) * duty, 0, (dur * (1-skew)) * duty), doneAction: 2);
	// env = EnvGen.ar(Env.sine(dur*duty));
	mDuty = (dur * duty) * mDuty;
	mEnv = EnvGen.ar(Env.linen(mDuty * mSkew, 0, mDuty * (1-mSkew)));
	mSig = InFeedback.ar(mBus);
	mSig = Select.ar(mSrc, [mEnv, mEnv * mSig, mSig]);

	rate = rate + ((rate * mSig) * rateMod);
	end = (end + (end * mSig * endMod)).clip(start, BufFrames.ir(bufnum));
	pos = Phasor.ar(0, BufRateScale.ir(bufnum) * rate, start, end, start);
	pos = pos + ((pos * mSig) * posMod);
	sig = BufRd.ar(2, bufnum, pos) * env;

	ffreq = ffreq + ((ffreq * mSig) * ffreqMod);
	res = 1 - res;
	sig = SelectX.ar(fMix, [
		sig,
		BPF.ar(sig, ffreq, res, (res ** -1) * (400 / ffreq ** 0.5))
	]);

	OffsetOut.ar(outBus, (sig * env * amp).tanh);
}).add;


SynthDef(\playOnceMONO, {arg outBus, mBus, bufnum, start, end,
	rate = 1, dur = 1, duty = 1, skew = 0.5, amp  = 1,
	ffreq = 12000, res = 0.1, fMix = 0,
	mSrc = 1, mDuty = 1, mSkew = 0.01,
	rateMod = 0, posMod = 0, endMod = 0, ffreqMod = 0;
	var env, mEnv, mSig, pos, sig;
	env = EnvGen.ar(Env.linen((dur * skew) * duty, 0, (dur * (1-skew)) * duty), doneAction: 2);
	// env = EnvGen.ar(Env.sine(dur*duty));
	mDuty = (dur * duty) * mDuty;
	mEnv = EnvGen.ar(Env.linen(mDuty * mSkew, 0, mDuty * (1-mSkew)));
	mSig = InFeedback.ar(mBus);
	mSig = Select.ar(mSrc, [mEnv, mEnv * mSig, mSig]);

	rate = rate + ((rate * mSig) * rateMod);
	end = (end + (end * mSig * endMod)).clip(start, BufFrames.ir(bufnum));
	pos = Phasor.ar(0, BufRateScale.ir(bufnum) * rate, start, end, start);
	pos = pos + ((pos * mSig) * posMod);
	sig = BufRd.ar(1, bufnum, pos) * env;

	ffreq = ffreq + ((ffreq * mSig) * ffreqMod);
	res = 1 - res;
	sig = SelectX.ar(fMix, [
		sig,
		BPF.ar(sig, ffreq, res, (res ** -1) * (400 / ffreq ** 0.5))
	]);

	OffsetOut.ar(outBus, (sig * env * amp).tanh ! 2);
}).add;
