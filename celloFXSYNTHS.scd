// extmod/noise
// ampmod
//noiseBus scales noise
// 0.5.linexp(0.3,0.98,1, 0.01)

(
SynthDef(\filter, {arg inBus, fBus, aBus, nBus, mBus,
	track = 0, transpose = 1, freqFreeze = 0, freqLag = 0, freqSkew = 0.45,
	ampMod = 0, ampLag = 0, ampSkew = 0.12,
	extMod = 0, extSrc = 0, noise = 0, noiseLag = 0,
	freq = 12000, type = 0, gate = 1, fade = 0, mix = 0;
	var env, inSig, fSig, aSig, mSig, res;

	env = EnvGen.ar(Env.asr(fade, 1, fade), gate, doneAction: 2);
	inSig = In.ar(inBus, 2);
	fSig = Gate.kr(In.kr(fBus), 1-freqFreeze);
	fSig = LagUD.kr(fSig, freqLag * freqSkew, freqLag * (1 - freqSkew));
	aSig = LagUD.kr(In.kr(aBus), ampLag * ampSkew, ampLag * (1 - ampSkew)) * ampMod;
	mSig = In.ar(mBus) * extMod;
	mSig = Select.ar(extSrc, [
		mSig + aSig,
		mSig * aSig,
	]);


	freq = Select.kr((track+freqFreeze).clip(0,1), [ freq, fSig * transpose]); //pitchtrack
	freq = freq + (mSig * freq);

	noise = noise + (aSig * noise * ampMod*0.44);
	noise = noise * In.kr(nBus);  //scale by noisiness of analysis
	// freq = freq + (freq * LPF.ar(inSig, noiseLag.reciprocal) * noise);
	freq = freq + (freq * Lag.ar(inSig, noiseLag) * noise);

	freq = freq.fold(20, 20000);
	res = mix.linexp(0.46,1,1, 0.01); //map res to mix
	res = res.fold(0, 0.99);
	mix = mix * env;

	inSig = SelectX.ar(mix.linlin(0, 0.44, 0, 1), [
		inSig,
		SelectX.ar(type, [
			RLPF.ar(inSig, freq, res),
			RHPF.ar(inSig, freq, res)
		])
	]);

	ReplaceOut.ar(inBus, inSig.tanh);
}).add;


SynthDef(\ring, {arg inBus, fBus, aBus, nBus, mBus,
	track = 0, transpose = 1, freqFreeze = 0, freqLag = 0, freqSkew = 0.45,
	ampMod = 0, ampLag = 0, ampSkew = 0.12,
	extMod = 0, extSrc = 0, noise = 0, noiseLag = 0,
	freq = 12000, duty = 0.018, gate = 1, fade = 0, mix = 0;
	var env, inSig, fSig, aSig, mSig, rSig;

	env = EnvGen.ar(Env.asr(fade, 1, fade), gate, doneAction: 2);
	inSig = In.ar(inBus, 2);
	fSig = Gate.kr(In.kr(fBus), 1-freqFreeze);
	fSig = LagUD.kr(fSig, freqLag * freqSkew, freqLag * (1 - freqSkew));
	aSig = LagUD.kr(In.kr(aBus), ampLag * ampSkew, ampLag * (1 - ampSkew)) * ampMod;
	mSig = In.ar(mBus) * extMod;
	mSig = Select.ar(extSrc, [
		mSig + aSig,
		mSig * aSig,
	]);

	freq = Select.kr((track+freqFreeze).clip(0,1), [ freq, fSig * transpose]); //pitchtrack
	freq = freq + (mSig * freq);
	duty = duty + (aSig *duty * ampMod*0.75);

	// noise = noise + (aSig * noise * ampMod*0.44);
	// noise = noise * In.kr(nBus);  //scale by noisiness of analysis
	// freq = freq + (freq * LPF.ar(inSig, noiseLag.reciprocal) * noise);
	freq = freq + (freq * Lag.ar(inSig, noiseLag) * noise);

	freq = freq.fold(0.01, 20000);
	duty = duty.clip(0.0001, 1);

	rSig = LFGauss.ar(freq.reciprocal, duty);
	rSig = SinOsc.ar(freq) * rSig;
	// rSig = SinGrain.ar(Impulse.ar(freq* duty), freq.reciprocal * duty, freq);

	mix = mix * env;
	inSig = SelectX.ar(mix, [ inSig, inSig * rSig * 2 ]);
	// inSig = SelectX.ar(mix * duty.linlin(0.68,1,0,1), [inSig, FreqShift.ar(inSig, freq*2)]); //freqshift at 1st harmonic
	inSig = SelectX.ar(((mix+duty)*0.5).linlin(0.68,1,0,1), [inSig, FreqShift.ar(inSig, freq*2)]); //freqshift at 1st harmonic

	ReplaceOut.ar(inBus, inSig.tanh);
}).add;


SynthDef(\delay, {arg inBus, fBus, aBus, nBus, mBus,
	track = 0, transpose = 1, 	ftrack = 0, ftranspose = 1,
	freqFreeze = 0, freqLag = 0, freqSkew = 0.45,
	ampMod = 0, ampLag = 0, ampSkew = 0.12,
	extMod = 0, extSrc = 0, noise = 0, noiseLag = 0,
	time = 0.33, feed = 0.75, ffreq = 12000,
	inAmp = 0, gate = 1, fade = 0, mix = 0;
	var env, inSig, fSig, aSig, mSig, fdSig, dSig;

	env = EnvGen.ar(Env.asr(fade, 1, fade), gate, doneAction: 2);
	inSig = In.ar(inBus, 2);
	fSig = Gate.kr(In.kr(fBus), 1-freqFreeze);
	fSig = LagUD.kr(fSig, freqLag * freqSkew, freqLag * (1 - freqSkew));
	aSig = LagUD.kr(In.kr(aBus), ampLag * ampSkew, ampLag * (1 - ampSkew)) * ampMod;
	mSig = In.ar(mBus) * extMod;
	mSig = Select.ar(extSrc, [
		mSig + aSig,
		mSig * aSig,
	]);

	time = Select.kr((track+freqFreeze).clip(0,1), [ time, (fSig * transpose).reciprocal ]); //pitchTrack >> delay time
	time = time + (mSig * time);

	// noise = noise + (aSig * noise * ampMod*0.44);
	// noise = noise * In.kr(nBus);  //scale by noisiness of analysis
	// time = time + (time * LPF.ar(inSig, noiseLag.reciprocal) * noise);
	time = time + (time * Lag.ar(inSig, noiseLag) * noise);
	time = time.lag(0.04);
	time = time.fold(0.0001, 6);



	fdSig = LocalIn.ar(2) * feed;
	ffreq = Select.kr(ftrack, [ ffreq, (fSig * ftranspose) ]);
	ffreq = (ffreq+(aSig*ffreq*ampMod)).lag(0.03);
	ffreq = ffreq.clip(120, 12000);
	fdSig = RLPF.ar(fdSig, ffreq, 1);
	// dSig = DelayL.ar(((inSig*inAmp) + fdSig).tanh, 6, time);
	dSig = DelayC.ar((inSig + fdSig).tanh, 6, time);
	dSig = CompanderD.ar(dSig, 0.3, 1, 0.27, 0.0027, 0.14);
	// dSig = Compander.ar(dSig, inSig+dSig, 0.3, 1, 0.23, 0.0037, 0.14);  //DUCK COMPRESSION FOR incoming signal??
	// dSig = RLPF.ar(dSig, (ffreq+(aSig*ffreq*ampMod).lag2(0.03, 0.2)).lag(0.03), 1);

	//ADD dust injection / tap warble, flutter!!!!
	LocalOut.ar(dSig);

	mix = mix * env;
	inSig = SelectX.ar(mix, [ inSig, dSig]);
	ReplaceOut.ar(inBus, inSig.tanh);
}).add;

)