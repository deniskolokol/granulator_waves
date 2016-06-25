(
SynthDef(\sfgrain, {arg bufnum=0, pan=0.0, startPos=0.0, amp=0.1, dur=0.08, lev=0.6;
var grain;

grain= PlayBuf.ar(
			1,
			bufnum,
			BufRateScale.kr(bufnum), //2 * BufRateScale.kr(bufnum),
			1,
			//BufFrames.ir(bufnum)*startPos, 0)*(EnvGen.kr(Env.perc(0.04,dur),doneAction:2)-0.001
			BufFrames.ir(bufnum)*startPos, 0)*(EnvGen.kr(Env.perc(0.03, dur, lev),doneAction:2)-0.001
		);
Out.ar(0,Pan2.ar(grain, pan))}).send(s);
)


b = Buffer.read(s,"sounds/a11wlk01.wav");

Synth(\sfgrain,[\bufnum, b.bufnum, \startPos,rrand(0.0,1.0),\amp, exprand(0.005,0.1), \pan, 1.0.rand2]);


//schedule 200/300 random soundfile playback grains over time, with random offset positions into the soundfile and increasing/lowering the density over time

//increase
(
{
200.do{arg i;
var timeprop = 1-(i/199.0)**3,
	graindur = exprand(0.1, timeprop);

	Synth(\sfgrain,[\bufnum, b.bufnum, \startPos,exprand(0.3,timeprop),\amp, exprand(0.1,0.8), \pan, 0.9.rand2, \dur, graindur, \lev, 1-timeprop]);
	round(graindur, 0.001).postln;
	exprand( (timeprop*0.1).max(0.01), timeprop*0.3 ).wait
};
}.fork
)

//decrease
(
{
300.do{arg i;
var timeprop = (i/299.0)**3,
	graindur = exprand(0.1, timeprop);

	Synth(\sfgrain,[\bufnum, b.bufnum, \startPos,exprand(0.3,timeprop),\amp, exprand(0.1,0.8), \pan, 0.9.rand2, \dur, graindur, \lev, 1-timeprop]);
	round(graindur, 0.001).postln;
	exprand( (timeprop*0.1).max(0.01), timeprop*0.3 ).wait
};
}.fork
)


b.free;
