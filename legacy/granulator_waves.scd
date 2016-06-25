//shortcuts:
// 		"-" (minus)			clear current preset
// 		"+" (plus) 			("=" actually) add/update preset to the current position
// 		<number>			start/pause
// 		Shift + <number>	restart
// 		Ctrl + <number>		stop
// 		Fn + <number>		update fileLists, check last element
// 		Q					global start / pause
// 		W					global re-start
// 		E 					global stop
// 		R					record / stop
// 		Alt + R				loop record
//		` 					fill all tasks randomly
//		Z X C V				fill task 1 2 3 4 randomly
//		A S D F				clean task 1 2 3 4
//		Ctrl + A S D F		copy content of 1 2 3 4 to buffer list
//		Alt + A S D F		paste content to 1 2 3 4 from buffer list

//v 0.3
//- to add function "all random" in all the slots and parameters (in given ranges for every parameter)
//- to add the possibility of choose the distribution method from:
//	  **3 increase
//	  **3 decrease (1-**3 is 180d mirroring of **3 increase!!!)
//	  sqrt increase
//	  sqrt decrease (1-.sqrt is is 180d mirroring of sqrt increase!!!)
//	  sin increase = 1 - sin( (i/(cycNum[j]-1))**2 * 0.5pi )
//	  sin decrease = sin( (i/(cycNum[j]-1))**2 * 0.5pi )
//	  linrand
//	  perlin noise
//!!!! dont forget ab/pre-sets and collapsing/expanding interface elements

//=== GUI & control ====
(
var w, hrIndex = 140, top = 80, wdIndex = 120;
var lbFontSm = Font("Helvetica", 9), lbFontLr = Font("Helvetica", 11);
var globalColor = Color.new(0.8, 0.4, 0.2, 0.2), rslColorBk = Color.new255(205, 104, 57), rslColorKn = Color.new255(139, 37, 0), lbColorFontSm = Color.new255(250, 240, 230), lbColorFontBg = Color.new255(26, 26, 26), btColorSt01 = Color.new255(255, 160, 122), btColorSt2 = Color.new255(139, 54, 38), genSlColor = Color.new255(110, 123, 139), btColorOff = Color.new255(250, 250, 250), btColorOn = Color.new255(43, 43, 43), btColorPlay = Color.new255(178, 34, 34), btColorStop = Color.new255(240, 230, 140), btColorPset0 = Color.new255(205, 200, 177), btColorPset1 = Color.new255(205, 92, 92), bgColorGray0 = Color.new255(149, 149, 154), slidColorProgress = Color.new255(123, 104, 238);
var	specVol = \db.asSpec,
	specRat = [-2, 2, \lin, 0.1].asSpec,
	specCyc = [0, 2000, \lin, 1, 1, "Cycl"].asSpec,
	specDur = [0.5, 10, \lin, 0.5, 1, "sec"].asSpec,
	specDisp = [0.1, 2.0, \lin, 0.1, 1, "sec"].asSpec;
var tmpBuffer, synthIn;
var channels = 52; // replace by ixi preferences
var chlistStereo, chlistMono;
var rslRunInd, rslRunIndList = List.new;
var distrMode = ["UP p3", "DW p3", "UP sqrt", "DW sqrt", "UP sin", "DW sin", "RN lin", "RN perl"];
var lbLabels, slCyc, slDisp, lbDisp, nbCyc, lbCyc, rslVol, stVolLo, stVolHi, btDirVol, lbVol, rslDur, stDurLo, stDurHi, btDirDur, lbDur, rslRat, stRatLo, stRatHi, btDirRat, lbRat, rslPos, stPosLo, stPosHi, btDirPos, lbPos, pmDistrMode;
var lbTask = List.new, pmChList = List.new, btDirWide = List.new, slWide = List.new, stWide = List.new, pmFileList = List.new;
var btLoop = List.new, btPlay = List.new, btRestart = List.new, btStop = List.new, btSlot = List.new;
var lbWide = List.new, lbFileList = List.new, lbLoop = List.new;
var lbLabelsList = List.new, slCycList = List.new, nbCycList = List.new, lbCycList = List.new, pmDistrModeList = List.new, slDispList = List.new, lbDispList = List.new;
var rslVolList = List.new, stVolLoList = List.new, stVolHiList = List.new, btDirVolList = List.new, lbVolList = List.new;
var rslDurList = List.new, stDurLoList = List.new, stDurHiList = List.new, btDirDurList = List.new, lbDurList = List.new;
var rslRatList = List.new, stRatLoList = List.new, stRatHiList = List.new, btDirRatList = List.new, lbRatList = List.new;
var rslPosList = List.new, stPosLoList = List.new, stPosHiList = List.new, btDirPosList = List.new, lbPosList = List.new;
var btPlayAll, btRestartAll, btStopAll, btSlotAll;
var theVolume;
var taskList = List.new;
var taskNum = 4; // number of tasks
var minimizeWaveSection, restoreWaveSection, defTask, loadFileList, updateDurCtlSpec;
var poolList, poolName, poolnamesarray, pool, poolindex, sndNameList = [], bufnumList = List.new, bufDurList = List.new, bufDurSpecList = List.new;
var slInputVol, nbInputVol, pmInputChan, slInputDur, nbInputDur, btInputRec, btInputLoop, rslInputDur, btPlayBuff;
var valList;
var psetButtList = List.new, psetNum = 50, psetList = Array.fill(psetNum, nil);
var presetsFile, psetChange, psetCurr = psetNum+1, saveSettings, restoreSettings;
var contCopy, contPaste, listTaskCont = Array.fill(21, nil); // task content for copy/paste
var contClean, fillRandom;
var ccResp; //MIDI


//pre-sets file
"Trying to open pre-sets file...".postln;
try{
	presetsFile = File("preferences/granwavepset.dk", "r");
	psetList = presetsFile.readAllString.interpret;
	"OK!".postln;
}{
	("Sorry, cannot open presets file"++String.scDir++"/preferences/granwavepset.dk" ++"!").postln;
	"Will be replaced on window close, so please take care of the current file (if any)!".postln;
	presetsFile = nil;
};

// channels lists
chlistStereo = Array.fill(trunc(channels / 2), nil);
chlistMono = Array.fill(channels, nil);
channels.do({ arg i;
	chlistMono.put(i, i.asSymbol);
	if( i < (channels / 2), { chlistStereo.put(i, (i*2).asSymbol ++ ", " ++ ((i*2)+1).asSymbol ); } );
	i=i+1;
});

//after stopping the recording to internal buffer var s is not local server anymore
if(s.serverRunning, { tmpBuffer = Buffer.alloc(s, s.sampleRate, 1) }); // 1 seconds 1 channel Buffer - default

w = SCWindow("GRAN WAVE", Rect(950, 40, 490, top+5+(taskNum*hrIndex)), resizable:false);

//main section
SCHLayoutView(w, Rect(0, 0, w.bounds.width, top+3))
	.background_(globalColor);
//pre-sets
psetNum.do({ |i|
	psetButtList.add(
		GUI.button.new(w, Rect(
				1+((if(i<(psetNum/2), {i}, {i-(psetNum/2)}))*19.5),
				2+((if(i<(psetNum/2), {0}, {1}))*20),
				19.5, 19 )
		)
			.font_(lbFontLr)
			.canFocus_(false)
			.states_([
				[(i+1).asSymbol, Color.black, btColorPset0], // 0 - no pre-set
				[(i+1).asSymbol, Color.black, Color.red(alpha:0.1)], // 1 - pre-set
				[(i+1).asSymbol, Color.white, btColorSt2] // 2 - pushed button
			])
			.value_(if(psetList[i] != nil, { 1 }, { 0 }))
			.action_({ psetChange.value(i) });
	);
});

//input - buffer pool
GUI.staticText.new(w, Rect(5, 47, 62, 15))
	.string_("buffer pool")
	.font_(lbFontSm);
poolList = GUI.popUpMenu.new(w,Rect(5, 60, 100, 15))
	.background_(Color.new255(255, 255, 255))
	.canFocus_(false)
	.font_(lbFontSm)
	.items_(if(XQ.poolNames == [], { ["no bufferPool"] }, { XQ.poolNames }))
	.action_({ |pm|
		loadFileList.value(pm.items[pm.value].asSymbol);
		taskNum.do({ |i| // update pos controlSpec
			updateDurCtlSpec.value(i);
		});
});
// separator
GUI.hLayoutView.new(w, Rect(109, 43, 1, top/2-2))
	.background_(Color.red(alpha:0.3));
GUI.hLayoutView.new(w, Rect(110, 43, 1, top/2-2))
	.background_(Color.red(alpha:0.1));

// input section
GUI.staticText.new(w, Rect(115, 47, 40, 15))
	.string_("input:")
	.font_(lbFontSm);
//input channel
pmInputChan = GUI.popUpMenu.new(w,Rect(115, 60, 30, 15))
		.background_(Color.new255(255, 255, 255))
		.canFocus_(false)
		.font_(lbFontSm)
		.items_(chlistMono);
//input vol
slInputVol = SCSlider(w,Rect(150, 48, 85, 13))
	.background_(Gradient(Color.red(alpha:0.0), Color.red(alpha:0.2), \h, 10))
	.knobColor_(Color.red(alpha:0.3))
	.value_(specVol.unmap(-1.0));
GUI.staticText.new(w, Rect(151, 49, 20, 13))
	.string_("vol")
	.font_(lbFontSm);
nbInputVol = GUI.numberBox.new(w,Rect(237, 48, 25, 13))
	.font_(lbFontSm)
	.value_(specVol.map(slInputVol.value));
GUI.staticText.new(w,Rect(217, 49, 15, 12))
	.string_(specVol.units)
	.font_(lbFontSm)
	.stringColor_(lbColorFontSm)
	.align_(\right);
slInputVol.action_({|v|
	nbInputVol.value_(specVol.map(v.value));
});
nbInputVol.action_({|v|
	slInputVol.value_(specVol.unmap(v.value));
});
//input duration
GUI.staticText.new(w, Rect(151, 63, 20, 13))
	.string_("dur")
	.font_(lbFontSm);
slInputDur = GUI.slider.new(w,Rect(150, 62, 85, 13))
	.background_(Gradient(Color.red(alpha:0.0), Color.red(alpha:0.2), \h, 10))
	.knobColor_(Color.red(alpha:0.3))
	.value_(specDur.unmap(1));
GUI.staticText.new(w,Rect(217, 63, 15, 12))
	.string_(specDur.units)
	.font_(lbFontSm)
	.stringColor_(lbColorFontSm)
	.align_(\right);
nbInputDur = GUI.numberBox.new(w,Rect(237, 62, 25, 13))
	.font_(lbFontSm)
	.value_(specDur.map(slInputDur.value));
slInputDur.action_({|v|
	nbInputDur.value_(specDur.map(v.value));
});
nbInputDur.action_({|v|
	slInputDur.value_(specDur.unmap(v.value));
});
//recording dur progress bar (range slider)
rslInputDur = GUI.rangeSlider.new(w, Rect(263, 66, 85, 15))
	.background_(Color.red(alpha:0.001))
	.knobColor_(slidColorProgress)
	.visible_(false)
	.canFocus_(false)
	.lo_(0)
	.hi_(0);
//record loop button
btInputLoop = GUI.button.new(w,Rect(313, 49, 25, 15))
	.font_(lbFontSm)
	.states_([
		["one", btColorOn, btColorOff],
		["loop", btColorOff, btColorOn]
	])
	.value_(0);
//record trigger button
btInputRec = GUI.button.new(w,Rect(265, 48, 45, 17))
	.font_(lbFontLr)
	.canFocus_(false)
	.states_([
		["REC", btColorPlay, btColorPset0],
		["STOP", btColorStop, btColorPlay]
	])
	.value_(0)
	.action_({ |bt|
		var routineRec, sp, cycles, cnt=0, loop=btInputLoop.value;
		if(bt.value == 1, {
			tmpBuffer.free;
			"problem here".postln;
			tmpBuffer = Buffer.alloc(s, s.sampleRate * nbInputDur.value, 1); // 1 channel Buffer
			synthIn = Synth.new(\syninbuff, [\bufnum, tmpBuffer.bufnum, \busnum, pmInputChan.value, \volIn, slInputVol.value, \loop, btInputLoop.value, \gate, specDur.map(slInputDur.value), \dur, specDur.map(slInputDur.value)]); //recording synth
			rslInputDur.visible_(true); rslInputDur.hi = 0;
			cycles = nbInputDur.value / 0.01;
			sp = [0, cycles, \lin, 0.1, 0].asSpec;
			routineRec = Routine({ |time|
				inf.do({
					cycles.do({ |i|
						{ cnt = i+1; rslInputDur.hi = sp.unmap(cnt) }.defer;
						0.01.wait;
					});
					if(loop == 0, { SystemClock.clear; { btInputRec.valueAction_(0); }.defer; });
					cnt = 0;
					0.1.wait;
				});
			});
			SystemClock.play(routineRec);
		}, {
			SystemClock.clear; synthIn.free;
		});
	});
//TEST - play buf button
btPlayBuff = GUI.button.new(w,Rect(340, 57, 15, 15))
	.font_(lbFontSm)
	.visible_(false)
	.states_([
		[">", btColorOn, btColorOff]
	])
	.value_(0)
	.action_({ |bt|
		{ Out.ar(0, Pan2.ar(
			PlayBuf.ar(1, tmpBuffer.bufnum, BufRateScale.kr(tmpBuffer.bufnum), 1, 0, 0), 0)
		)}.play(s);
	});
//play/pause ALL button
btPlayAll = GUI.button.new(w,Rect(355, 57, 45, 25))
	.font_(lbFontLr)
	.states_([
		[">>", btColorPlay, btColorStop],
		["||", btColorStop, btColorPlay]
	])
	.value_(0);
//restart ALL button
btRestartAll = GUI.button.new(w,Rect(402, 57, 30, 25))
	.font_(lbFontLr)
	.states_([
		[">", btColorPlay, btColorStop]
	])
	.value_(0);
//stop ALL button
btStopAll = GUI.button.new(w,Rect(434, 57, 30, 25))
	.font_(lbFontLr)
	.states_([
		["[]", btColorStop, genSlColor]
	])
	.value_(0);
//collapse/expand ALL button
btSlotAll = GUI.button.new(w, Rect(468, 57, 18, 18))
	.font_(lbFontLr)
	.states_([
		["-", btColorOn, btColorOff],
		["+", btColorOff, btColorOn]
	])
	.value_(0)
	.action_({|b|
		var bounds, q = 0;
		taskNum.do({|i|
			if(b.value==1, {
				if(btSlot[i].value == 0, { minimizeWaveSection.value(i); q = q + 1 });
			}, {
				if(btSlot[i].value == 1, { restoreWaveSection.value(i); q = q + 1 });
			});
			btSlot[i].value = btSlotAll.value;
		});
		//change window size
		if(b.value==1, {
			bounds = w.bounds; bounds.height = bounds.height - (hrIndex*q) + (60*q); w.bounds = bounds;
		}, {
			bounds = w.bounds; bounds.height = bounds.height + (hrIndex*q) - (60*q); w.bounds = bounds;
		});
	});
SCStaticText(w,Rect(353, 44, 50, 13))
	.string_('main dB')
	.font_(lbFontSm);
theVolume = SmoothSlider(w,Rect(396, 44, 90, 10))
	.background_(Color.red(alpha:0.1))
	.hilightColor_(Color.new255(139, 37, 0, 128))
	.knobColor_(rslColorKn)
	.value_(0.5);


//task interface
taskNum.do({arg i;
	var waveSection = 0;

	taskList.add(nil);

	//task indicator
	lbTask.add(
		SCStaticText(w,Rect(5+(wdIndex*waveSection), top+5+(i*hrIndex), 10, 15))
			.string_((i+1).asSymbol)
			.background_(Color.black)
			.font_(lbFontLr)
			.stringColor_(lbColorFontSm)
			.align_(\center);
	);

	rslRunInd = Array.fill(4, nil); // doubt - unclear if i can do it from the task
	lbLabels = Array.fill(4, nil);
	pmDistrMode = Array.fill(4, nil);
	slCyc = Array.fill(4, nil); nbCyc = Array.fill(4, nil); lbCyc = Array.fill(4, nil); slDisp = Array.fill(4, nil); lbDisp = Array.fill(4, nil);
	rslVol = Array.fill(4, nil); stVolLo = Array.fill(4, nil); stVolHi = Array.fill(4, nil); btDirVol = Array.fill(4, nil); lbVol = Array.fill(4, nil);
	rslDur = Array.fill(4, nil); stDurLo = Array.fill(4, nil); stDurHi = Array.fill(4, nil); btDirDur = Array.fill(4, nil); lbDur = Array.fill(4, nil);
	rslRat = Array.fill(4, nil); stRatLo = Array.fill(4, nil); stRatHi = Array.fill(4, nil); btDirRat = Array.fill(4, nil); lbRat = Array.fill(4, nil);
	rslPos = Array.fill(4, nil); stPosLo = Array.fill(4, nil); stPosHi = Array.fill(4, nil); btDirPos = Array.fill(4, nil); lbPos = Array.fill(4, nil);

	// group GUI
	4.do({ |j|
		//progress bar
		rslRunInd[j] = (
			SCRangeSlider(w, Rect(if(j==0,{15+(wdIndex*waveSection)},5+(wdIndex*waveSection)), top+5+(i*hrIndex), if(j==0,{105},{115}), 15))
				.background_(Color.red(alpha:0.001))
				.knobColor_(slidColorProgress)
				.canFocus_(false)
				.lo_(0)
				.hi_(0)
				.visible_(false);
		);

		// distribution mode
		pmDistrMode[j] = (
			GUI.popUpMenu.new(w,Rect(5+(wdIndex*waveSection), top+20+(i*hrIndex), 20, 17))
				.background_(Color.new255(255, 255, 255))
				.canFocus_(false)
				.font_(lbFontLr)
				.items_(distrMode)
				.value_( distrMode.size.rand ) // random distribution method
				// another approach can be sthn close to "ADSR" shape, e.g.
				// 3rd segment is perlin, the rest are 1(0)-UP**3, 2(1)-DW**3, 4(3)-DWsqrt
				//.value_( if(j == 2, {7}, {j}) )
		);

		// label of the distribution mode
		lbLabels[j] = (
			GUI.staticText.new(w,Rect(50+(wdIndex*waveSection), top+5+(i*hrIndex), 60, 15))
				.font_(lbFontLr)
				.align_(\right)
				.string_(distrMode.at(pmDistrMode[j].value))
		);

		//cycles group
		slCyc[j] = (
			SCSlider(w,Rect(32+(wdIndex*waveSection), top+20+(i*hrIndex), 68, 17))
				.background_(rslColorKn)
				.knobColor_(rslColorBk)
				.visible_(false)
				.value_(0)
		);
		nbCyc[j] = (
			SCNumberBox(w,Rect(28+(wdIndex*waveSection), top+20+(i*hrIndex), 25, 15))
				.font_(lbFontSm)
				.value_(slCyc[j].value);
		);
		lbCyc[j] = (
			SCStaticText(w,Rect(29+(wdIndex*waveSection), top+22+(i*hrIndex), 35, 12))
				.string_("Cycles")
				.font_(lbFontSm)
				.visible_(false)
				.stringColor_(lbColorFontSm);
		);
		slDisp[j] = (
			SCSlider(w,Rect(58+(wdIndex*waveSection), top+20+(i*hrIndex), 60, 15))
				.background_(rslColorKn)
				.knobColor_(rslColorBk)
				.value_(specDisp.map(0))
		);
		lbDisp[j] = (
			SCStaticText(w,Rect(100+(wdIndex*waveSection), top+22+(i*hrIndex), 35, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm)
				.string_(specDisp.map(slDisp[j].value));
		);

		//volume group
		btDirVol[j] = (
			GUI.button.new(w,Rect(5+(wdIndex*waveSection), top+40+(i*hrIndex), 15, 14))
				.font_(lbFontSm)
				.states_([
					[">", lbColorFontBg, btColorSt01],
					["<", lbColorFontBg, btColorSt01],
					["?", lbColorFontSm, btColorSt2]
				])
				.value_(0);
		); // direction if distribution button

		rslVol[j] = (
			GUI.rangeSlider.new(w,Rect(20+(wdIndex*waveSection), top+40+(i*hrIndex), 100, 15))
				.background_(rslColorBk)
				.knobColor_(rslColorKn)
		);
		stVolLo[j] = (
			GUI.staticText.new(w,Rect(21+(wdIndex*waveSection), top+42+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		stVolHi[j] = (
			GUI.staticText.new(w,Rect(86+(wdIndex*waveSection), top+42+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		lbVol[j] = (
			GUI.staticText.new(w,Rect(50+(wdIndex*waveSection), top+42+(i*hrIndex), 25, 12))
				.string_(specVol.units)
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm)
				.align_(\center);
		);
		//duration group
		btDirDur[j] = (
			GUI.button.new(w,Rect(5+(wdIndex*waveSection), top+60+(i*hrIndex), 15, 14))
				.font_(lbFontSm)
				.states_([
					[">", lbColorFontBg, btColorSt01],
					["<", lbColorFontBg, btColorSt01],
					["?", lbColorFontSm, btColorSt2]
				])
				.value_(0);
		); // direction if distribution button
		rslDur[j] = (
			GUI.rangeSlider.new(w,Rect(20+(wdIndex*waveSection), top+60+(i*hrIndex), 100, 15))
				.background_(rslColorBk)
				.knobColor_(rslColorKn)
		);
		stDurLo[j] = (
			GUI.staticText.new(w,Rect(21+(wdIndex*waveSection), top+62+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		stDurHi[j] = (
			GUI.staticText.new(w,Rect(90+(wdIndex*waveSection), top+62+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		lbDur[j] = (
			GUI.staticText.new(w,Rect(52+(wdIndex*waveSection), top+62+(i*hrIndex), 25, 12))
				.string_("dur,S")
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm)
				.align_(\center);
		);
		//rate group
		btDirRat[j] = (
			GUI.button.new(w,Rect(5+(wdIndex*waveSection), top+80+(i*hrIndex), 15, 14))
				.font_(lbFontSm)
				.states_([
					[">", lbColorFontBg, btColorSt01],
					["<", lbColorFontBg, btColorSt01],
					["?", lbColorFontSm, btColorSt2]
				])
				.value_(0);
		); // direction if distribution button
		rslRat[j] = (
			GUI.rangeSlider.new(w,Rect(20+(wdIndex*waveSection), top+80+(i*hrIndex), 100, 15))
				.background_(rslColorBk)
				.knobColor_(rslColorKn)
		);
		stRatLo[j] = (
			GUI.staticText.new(w,Rect(21+(wdIndex*waveSection), top+82+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		stRatHi[j] = (
			GUI.staticText.new(w,Rect(93+(wdIndex*waveSection), top+82+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		lbRat[j] = (
			GUI.staticText.new(w,Rect(52+(wdIndex*waveSection), top+82+(i*hrIndex), 25, 12))
				.string_("rate")
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm)
				.align_(\center);
		);
		//position group
		btDirPos[j] = (
			GUI.button.new(w,Rect(5+(wdIndex*waveSection), top+100+(i*hrIndex), 15, 14))
				.font_(lbFontSm)
				.states_([
					[">", lbColorFontBg, btColorSt01],
					["<", lbColorFontBg, btColorSt01],
					["?", lbColorFontSm, btColorSt2]
				])
				.value_(0);
		); // direction if distribution button
		rslPos[j] = (
			GUI.rangeSlider.new(w,Rect(20+(wdIndex*waveSection), top+100+(i*hrIndex), 100, 15))
				.background_(rslColorBk)
				.knobColor_(rslColorKn)
		);
		stPosLo[j] = (
			GUI.staticText.new(w,Rect(21+(wdIndex*waveSection), top+102+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		stPosHi[j] = (
			GUI.staticText.new(w,Rect(93+(wdIndex*waveSection), top+102+(i*hrIndex), 25, 12))
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm);
		);
		lbPos[j] = (
			GUI.staticText.new(w,Rect(52+(wdIndex*waveSection), top+102+(i*hrIndex), 25, 12))
				.string_("pos,S")
				.font_(lbFontSm)
				.stringColor_(lbColorFontSm)
				.align_(\center);
		);
		waveSection = waveSection + 1;
	});

	rslRunIndList.add(rslRunInd);
	lbLabelsList.add(lbLabels);
	pmDistrModeList.add(pmDistrMode);
	nbCycList.add(nbCyc); slCycList.add(slCyc); lbCycList.add(lbCyc); slDispList.add(slDisp); lbDispList.add(lbDisp);
	rslVolList.add(rslVol); stVolLoList.add(stVolLo); stVolHiList.add(stVolHi); btDirVolList.add(btDirVol); lbVolList.add(lbVol);
	rslDurList.add(rslDur); stDurLoList.add(stDurLo); stDurHiList.add(stDurHi); btDirDurList.add(btDirDur); lbDurList.add(lbDur);
	rslRatList.add(rslRat); stRatLoList.add(stRatLo); stRatHiList.add(stRatHi); btDirRatList.add(btDirRat); lbRatList.add(lbRat);
	rslPosList.add(rslPos); stPosLoList.add(stPosLo); stPosHiList.add(stPosHi); btDirPosList.add(btDirPos); lbPosList.add(lbPos);

	// channel list
	pmChList.add(
		GUI.popUpMenu.new(w,Rect(5, top+120+(i*hrIndex), 42, 15))
			.background_(Color.new255(255, 255, 255))
			.canFocus_(false)
			.font_(lbFontSm)
			.items_(chlistStereo)
	);
	//wide panorama slider
	btDirWide.add( // direction if distribution button
		GUI.button.new(w,Rect(53, top+120+(i*hrIndex), 15, 14))
			.font_(lbFontSm)
			.states_([
				[">", lbColorFontSm, genSlColor],
				["<", lbColorFontSm, genSlColor],
				["?", lbColorFontSm, btColorSt2]
			])
			.value_(0);
	);
	slWide.add(
		GUI.slider.new(w, Rect(70, top+120+(i*hrIndex), 80, 15))
			.background_(Gradient(bgColorGray0, genSlColor, \h, 10))
			.value_(0.7);
	);
	lbWide.add(
		GUI.staticText.new(w,Rect(71, top+121+(i*hrIndex), 20, 14))
			.string_("wide")
			.font_(lbFontSm);
	);
	stWide.add(
		GUI.staticText.new(w,Rect(130, top+121+(i*hrIndex), 25, 12))
			.font_(lbFontSm)
			.stringColor_(lbColorFontSm);
	);
	slWide[i].action_({|v|
		stWide[i].string_(round(v.value, 0.01));
	});
	//file
	lbFileList.add(
		GUI.staticText.new(w,Rect(155, top+121+(i*hrIndex), 25, 14))
			.string_("buffer")
			.font_(lbFontSm);
	);
	bufDurSpecList.add(nil);
	pmFileList.add(
		GUI.popUpMenu.new(w, Rect(180, top+120+(i*hrIndex), 120, 15))
			.background_(Color.new255(255, 255, 255))
			.canFocus_(false)
			.value_(i)
			.font_(lbFontSm)
			.action_({ |popup|
				var filepath, soundfile, selStart, selEnd, checkBufLoadTask, tmpBuf;
				if(popup.value != 0, {
					filepath = XQ.globalBufferDict.at(poolName)[0][popup.value-1].path; // 1st buffer is always internal
					selStart = XQ.globalBufferDict.at(poolName)[1][popup.value-1][0];
					selEnd = selStart + XQ.globalBufferDict.at(poolName)[1][popup.value-1][1]-1;
					soundfile = SoundFile.new;
					soundfile.openRead(filepath);
					if(soundfile.numChannels == 2, {
						tmpBuf = Buffer.readChannel(s, filepath, selStart, selEnd, [0]); //if it's stereo, read only left channel
					}, {
						tmpBuf = Buffer.read(s, filepath, selStart, selEnd); // make a right size buffer if only part of file is selected
					});
//					bufnumList[popup.value-1].free; bufnumList[popup.value-1] = tmpBuf.bufnum;
//					[popup.value-1, filepath, tmpBuf.numFrames, tmpBuf.sampleRate].postln;
//					bufDurList[popup.value-1] = XQ.globalBufferDict.at(poolName)[0][popup.value-1].numFrames / XQ.globalBufferDict.at(poolName)[0][popup.value-1].sampleRate; // buffer length in seconds
					soundfile.close;
				});
				updateDurCtlSpec.value(i); //update duration sliders
			});
	);

	//loop switcher
	lbLoop.add(
		GUI.staticText.new(w,Rect(310, top+121+(i*hrIndex), 20, 14))
			.string_("loop")
			.font_(lbFontSm);
	);
	btLoop.add(
		GUI.button.new(w,Rect(330, top+121+(i*hrIndex), 20, 14))
			.font_(lbFontSm)
			.states_([
				["off", btColorOn, btColorOff],
				["on", btColorOff, btColorOn]
			])
			.value_(0);
	);
	//play/pause button
	btPlay.add(
		GUI.button.new(w,Rect(355, top+118+(i*hrIndex), 45, 20))
			.font_(lbFontLr)
			.states_([
				[">>", btColorPlay, btColorStop],
				["||", btColorStop, btColorPlay]
			])
			.value_(0)
			.action_({|b|
				defTask.value(i, 1-b.value, btLoop[i].value); // params i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
			});
	);
	//restart button
	btRestart.add(
		GUI.button.new(w,Rect(402, top+118+(i*hrIndex), 30, 20))
			.font_(lbFontLr)
			.states_([
				[">", btColorPlay, btColorStop]
			])
			.value_(0)
			.action_({|b|
				defTask.value(i, 2, btLoop[i].value); // params i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
			});
	);
	//stop button
	btStop.add(
		GUI.button.new(w,Rect(434, top+118+(i*hrIndex), 30, 20))
			.font_(lbFontLr)
			.states_([
				["[]", btColorStop, genSlColor]
			])
			.action_({|b|
				defTask.value(i, 3, 0); // params i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
				btPlay[i].value = 0;
				4.do({ |j| rslRunIndList[i][j].visible_(false) }) // clear progress bars if any
			});
	);
	//slot button
	btSlot.add(
		GUI.button.new(w,Rect(468, top+122+(i*hrIndex), 15, 15))
			.font_(lbFontLr)
			.states_([
				["-", btColorOn, btColorOff],
				["+", btColorOff, btColorOn]
			])
			.value_(0)
			.action_({|b|
				var q = 0;
				if(b.value==1, { minimizeWaveSection.value(i) }, { restoreWaveSection.value(i) } );
				taskNum.do({ |j| if(btSlot[j].value != b.value, {q=q+1} ) });
				if(q==0, {btSlotAll.value = b.value});
			});
	);
});

taskNum.do({arg i;
	4.do({ |j|
		pmDistrModeList[i][j].action_({|v|
			lbLabelsList[i][j].string_(distrMode.at(v.value));
		});
		slCycList[i][j].action_({|v|
			nbCycList[i][j].value_(specCyc.map(v.value));
		});
		slDispList[i][j].action_({|v|
			lbDispList[i][j].string_(specDisp.map(v.value).asSymbol);
		});
		nbCycList[i][j].action_({|v|
			slCycList[i][j].value_(specCyc.unmap(v.value));
		});
		rslVolList[i][j].action_({|v|
			stVolLoList[i][j].string_(specVol.map(v.lo));
			stVolHiList[i][j].string_(specVol.map(v.hi));
		});
		rslDurList[i][j].action_({|v|
			stDurLoList[i][j].string_(round(v.lo, 0.01));
			stDurHiList[i][j].string_(round(v.hi, 0.01));
		});
		rslRatList[i][j].action_({|v|
			stRatLoList[i][j].string_(specRat.map(v.lo));
			stRatHiList[i][j].string_(specRat.map(v.hi));
		});
		rslPosList[i][j].action_({|v|
			if (bufDurSpecList[i] != nil, {
				stPosLoList[i][j].string_(bufDurSpecList[i].map(v.lo));
				stPosHiList[i][j].string_(bufDurSpecList[i].map(v.hi));
			}, {
				stPosLoList[i][j].string_(round(v.lo, 0.01));
				stPosHiList[i][j].string_(round(v.hi, 0.01));
			});
		});
	});
});

//global buttons actions
btPlayAll.action_({|b|
	taskNum.do({arg i;
		btPlay[i].value_(b.value);
		defTask.value(i, 1-b.value, btLoop[i].value); // params i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
	})
});
btRestartAll.action_({
	taskNum.do({arg i;
		defTask.value(i, 2, btLoop[i].value); // params i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
	})
});
btStopAll.action_({
	taskNum.do({arg i;
		btPlay[i].value_(0);
		defTask.value(i, 3, 0); // params i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
		4.do({ |j| rslRunIndList[i][j].visible_(false) }) // clear progress bars if any
	});
	btPlayAll.value = 0;
});

// shortcuts
w.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
	var	modifClean= #[0, 256, 10486016, 10485760], // no modifiers
		modifShift= #[262401, 262145, 131076, 131332, 131330, 131074],  // modifiers - Shift
		modifCmd= #[11534600, 11534608, 11534344, 11534352], // modifiers - Command
		modifCtrl= #[262401, 262145]; // modifiers - Ctrl
	[char, modifiers, keycode].postln;
	case
		{keycode == 27} {if(psetCurr <= psetNum, { psetList.put(psetCurr, nil); })} // minus, delete preset
 		{keycode == 10} { // § - add/update preset (originally "plus / =")
			if(psetCurr <= psetNum, {
				saveSettings.value(psetCurr);
				})
		}
		{ (keycode >= 18) && (keycode < (18+taskNum)) } {
			case
				{ (modifiers == 256) || (modifiers == 0) } { // <number> - start/pause button
					btPlay[keycode-18].valueAction_(1 - btPlay[keycode-18].value)
				}
				{ (modifiers == 131330) || (modifiers == 131074) } {// Shift+<number> (18..18+taskNum) - restart button
					btRestart[keycode-18].valueAction_(1 - btRestart[keycode-18].value)
				}
				{ (modifiers == 262401) || (modifiers == 262145) } {// Ctrl + <number> (18..18+taskNum) - stop button
					btStop[keycode-18].valueAction_(1 - btStop[keycode-18].value)
				}
				{ (modifiers == 8388608) || (modifiers == 8388864) } {// Fn + <number> (18..18+taskNum) - update fileLists, check last element
					valList = Array.fill(taskNum, nil); // save the positions of popupmenus
					taskNum.do({ |cnt| valList[cnt] = pmFileList[cnt].value; });
					loadFileList.value(poolList.items[poolList.value].asSymbol); // update filelists
					taskNum.do({ |cnt|
						pmFileList[cnt].items_(sndNameList); // put the new sounds into popupmenus
						if( (cnt == (keycode-18)), {
							pmFileList[cnt].valueAction_(pmFileList[cnt].size - 1); // select last element
						},{
							pmFileList[cnt].value = valList[cnt];
						} );
					});
				};
		}
		{keycode == 12} { // Q (global start / pause)
			if( (modifiers == 0) || (modifiers == 256), { btPlayAll.valueAction_(1 - btPlayAll.value) });
		}
		{keycode == 13} { // W (global re-start)
			if( (modifiers == 0) || (modifiers == 256), { btRestartAll.valueAction_(1 - btRestartAll.value) });
		}
		{keycode == 14} { // E (global stop)
			if( (modifiers == 0) || (modifiers == 256), { btStopAll.valueAction_(1 - btStopAll.value) });
		}
		{keycode == 42} { // "\" (Record / stop) & Alt + "\" (loop record)
			if( (modifiers == 131076) || (modifiers == 524320), { btInputLoop.valueAction_(1 - btInputLoop.value) });
			btInputRec.valueAction_(1 - btInputRec.value);
		}
		{keycode == 50} { // ` (fill all tasks randomly)
			if( (modifiers == 0) || (modifiers == 256), { taskNum.do{ |i| fillRandom.value(i)} });
		}
		{(keycode >= 6) && (keycode < 10)} {
			if((modifiers == 0) || (modifiers == 256), { fillRandom.value(keycode-6) }) // Z X C V (fill specific task randomly)
		}
		{(keycode >= 0) && (keycode < 4)} { // A S D F
			if(modifClean.includes(modifiers), { contClean.value(keycode) });// A S D F (clean task 1 2 3 4)
			if(modifCtrl.includes(modifiers), { contCopy.value(keycode) });// Ctrl + A S D F (copy content of task 1 2 3 4)
			if(modifShift.includes(modifiers), { contPaste.value(keycode) });// Shift + A S D F (paste content to task 1 2 3 4)
		};
};


//=======================
//pre-sets section
psetChange = {arg preset;
	if((preset != psetCurr) && (psetCurr <= psetNum), {
		psetButtList[psetCurr].value = if(psetList[psetCurr] != nil, { 1 }, { 0 }); // make the previously chosen pre-set into previous state
	});
	psetButtList[preset].value = 2; // push the button
	psetCurr = preset;
	restoreSettings.value(psetCurr);
};

saveSettings = {arg pset;
	var tmpList, psetTask, psetCurrList;
	psetCurrList = List.fill(taskNum, nil);
	//psetCurrList = [0..taskNum-1 - psetTask]
	//psetTask = [0..4 - task global params; 5..17 - arrays [0..3] of every other slider]
	taskNum.do({ arg i;
		psetTask = Array.fill(21, nil);
		psetTask[0] = "task " ++ i.asSymbol;
		psetTask[1] = pmChList[i].value;
		psetTask[2] = slWide[i].value;
		psetTask[3] = btDirWide[i].value;
		psetTask[4] = pmFileList[i].value;
		psetTask[5] = btLoop[i].value;
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=slCycList[i][j].value}); psetTask[6]=tmpList; // 6 - cycles
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirVolList[i][j].value}); psetTask[7]=tmpList; // 7 - dir button Vol
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslVolList[i][j].lo}); psetTask[8]=tmpList; // 8 - Vol rslid Lo
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslVolList[i][j].hi}); psetTask[9]=tmpList; // 9 - Vol rslid Hi
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirDurList[i][j].value}); psetTask[10]=tmpList; // 10 - dir button Vol
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslDurList[i][j].lo}); psetTask[11]=tmpList; // 11 - Dur rslid Lo
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslDurList[i][j].hi}); psetTask[12]=tmpList; // 12 - Dur rslid Hi
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirRatList[i][j].value}); psetTask[13]=tmpList; // 13 - dir button Rat
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslRatList[i][j].lo}); psetTask[14]=tmpList; // 14 - Rat rslid Lo
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslRatList[i][j].hi}); psetTask[15]=tmpList; // 15 - Rat rslid Hi
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirPosList[i][j].value}); psetTask[16]=tmpList; //16 - dir button Pos
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslPosList[i][j].lo}); psetTask[17]=tmpList; // 17 - Pos rslid Lo
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslPosList[i][j].hi}); psetTask[18]=tmpList; // 18 - Pos rslid Hi
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=pmDistrModeList[i][j].value }); psetTask[19]=tmpList; // 19 - distrib mode
		tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=slDispList[i][j].value }); psetTask[20]=tmpList; // 20 - dispersion
		psetCurrList[i] = psetTask;
	});
	psetList.put(pset, psetCurrList);
	pset.asSymbol ++ " pre-set successfully (re)written!"
};

restoreSettings = {arg pset;
	var presetCurrNode;
	if(psetList[pset] != nil, {
		presetCurrNode = psetList[pset]; // current presets list
		// first restore global settings
		taskNum.do({ arg i;
			pmChList[i].value = presetCurrNode[i][1];
			slWide[i].valueAction_(presetCurrNode[i][2]);
			btDirWide[i].value = presetCurrNode[i][3];
			pmFileList[i].value = presetCurrNode[i][4];
			btLoop[i].value = presetCurrNode[i][5];
			4.do({ |j| slCycList[i][j].valueAction_(presetCurrNode[i][6][j]) }); // 6 - cycles
			4.do({ |j| btDirVolList[i][j].value = presetCurrNode[i][7][j]}); // 7 - dir button Vol
			4.do({ |j| rslVolList[i][j].activeLo_(presetCurrNode[i][8][j]) }); // 8 - Vol rslid Lo
			4.do({ |j| rslVolList[i][j].activeHi_(presetCurrNode[i][9][j]) }); // 9 - Vol rslid Hi
			4.do({ |j| btDirDurList[i][j].value = presetCurrNode[i][10][j]}); // 10 - dir button Dur
			4.do({ |j| rslDurList[i][j].activeLo_(presetCurrNode[i][11][j]) }); // 11 - Dur rslid Lo
			4.do({ |j| rslDurList[i][j].activeHi_(presetCurrNode[i][12][j]) }); // 12 - Dur rslid Hi
			4.do({ |j| btDirRatList[i][j].value = presetCurrNode[i][13][j] }); // 13 - dir button Rat
			4.do({ |j| rslRatList[i][j].activeLo_(presetCurrNode[i][14][j]) }); // 14 - Rat rslid Lo
			4.do({ |j| rslRatList[i][j].activeHi_(presetCurrNode[i][15][j]) }); // 15 - Rat rslid Hi
			4.do({ |j| btDirPosList[i][j].value = presetCurrNode[i][16][j]}); // 16 - dir button Pos
			4.do({ |j| rslPosList[i][j].activeLo_(presetCurrNode[i][17][j]) }); // 17 - Pos rslid Lo
			4.do({ |j| rslPosList[i][j].activeHi_(presetCurrNode[i][18][j]) }); // 18 - Pos rslid Hi
			4.do({ |j| pmDistrModeList[i][j].valueAction_(presetCurrNode[i][19][j]) }); // 19 - distr mode
			if(presetCurrNode[i].size == 20, {
				4.do({ |j| slDispList[i][j].valueAction_(specDisp.unmap(0.1)) }); // no data at 20 - default dispersion
			}, {
				4.do({ |j| slDispList[i][j].valueAction_(presetCurrNode[i][20][j]) }); // 20 - dispersion
			})
		});
	});
};

//pre-sets section - end of
//=======================


//=====================
// copy-paste mechanism
contCopy = {arg taskNo;
	var tmpList;

	listTaskCont = Array.fill(21, nil);
	listTaskCont[0] = "task " ++ taskNo.asSymbol;
	listTaskCont[1] = pmChList[taskNo].value;
	listTaskCont[2] = slWide[taskNo].value;
	listTaskCont[3] = btDirWide[taskNo].value;
	listTaskCont[4] = pmFileList[taskNo].value;
	listTaskCont[5] = btLoop[taskNo].value;
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=slCycList[taskNo][j].value}); listTaskCont[6]=tmpList; // 6 - cycles
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirVolList[taskNo][j].value}); listTaskCont[7]=tmpList; // 7 - dir button Vol
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslVolList[taskNo][j].lo}); listTaskCont[8]=tmpList; // 8 - Vol rslid Lo
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslVolList[taskNo][j].hi}); listTaskCont[9]=tmpList; // 9 - Vol rslid Hi
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirDurList[taskNo][j].value}); listTaskCont[10]=tmpList; // 10 - dir button Vol
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslDurList[taskNo][j].lo}); listTaskCont[11]=tmpList; // 11 - Dur rslid Lo
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslDurList[taskNo][j].hi}); listTaskCont[12]=tmpList; // 12 - Dur rslid Hi
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirRatList[taskNo][j].value}); listTaskCont[13]=tmpList; // 13 - dir button Rat
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslRatList[taskNo][j].lo}); listTaskCont[14]=tmpList; // 14 - Rat rslid Lo
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslRatList[taskNo][j].hi}); listTaskCont[15]=tmpList; // 15 - Rat rslid Hi
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=btDirPosList[taskNo][j].value}); listTaskCont[16]=tmpList; //16 - dir button Pos
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslPosList[taskNo][j].lo}); listTaskCont[17]=tmpList; // 17 - Pos rslid Lo
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=rslPosList[taskNo][j].hi}); listTaskCont[18]=tmpList; // 18 - Pos rslid Hi
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=pmDistrModeList[taskNo][j].value }); listTaskCont[19]=tmpList; // 19 - distrib mode
	tmpList=Array.fill(4, nil); 4.do({ |j| tmpList[j]=slDispList[taskNo][j].value }); listTaskCont[20]=tmpList; // 20 - dispersion
};


contPaste = {arg taskNo;
	var tmpList;

	pmChList[taskNo].value = listTaskCont[1];
	slWide[taskNo].valueAction_(listTaskCont[2]);
	btDirWide[taskNo].value = listTaskCont[3];
	pmFileList[taskNo].value = listTaskCont[4];
	btLoop[taskNo].value = listTaskCont[5];
	4.do({ |j| slCycList[taskNo][j].valueAction_(listTaskCont[6][j]) }); // 6 - cycles
	4.do({ |j| btDirVolList[taskNo][j].value = listTaskCont[7][j]}); // 7 - dir button Vol
	4.do({ |j| rslVolList[taskNo][j].activeLo_(listTaskCont[8][j]) }); // 8 - Vol rslid Lo
	4.do({ |j| rslVolList[taskNo][j].activeHi_(listTaskCont[9][j]) }); // 9 - Vol rslid Hi
	4.do({ |j| btDirDurList[taskNo][j].value = listTaskCont[10][j]}); // 10 - dir button Dur
	4.do({ |j| rslDurList[taskNo][j].activeLo_(listTaskCont[11][j]) }); // 11 - Dur rslid Lo
	4.do({ |j| rslDurList[taskNo][j].activeHi_(listTaskCont[12][j]) }); // 12 - Dur rslid Hi
	4.do({ |j| btDirRatList[taskNo][j].value = listTaskCont[13][j] }); // 13 - dir button Rat
	4.do({ |j| rslRatList[taskNo][j].activeLo_(listTaskCont[14][j]) }); // 14 - Rat rslid Lo
	4.do({ |j| rslRatList[taskNo][j].activeHi_(listTaskCont[15][j]) }); // 15 - Rat rslid Hi
	4.do({ |j| btDirPosList[taskNo][j].value = listTaskCont[16][j]}); // 16 - dir button Pos
	4.do({ |j| rslPosList[taskNo][j].activeLo_(listTaskCont[17][j]) }); // 17 - Pos rslid Lo
	4.do({ |j| rslPosList[taskNo][j].activeHi_(listTaskCont[18][j]) }); // 18 - Pos rslid Hi
	4.do({ |j| pmDistrModeList[taskNo][j].valueAction_(listTaskCont[19][j]) }); // 19 - distr mode
	if(listTaskCont.size == 20, {
		4.do({ |j| slDispList[taskNo][j].valueAction_(specDisp.unmap(0.1)) }); // no data at 20 - default dispersion
	}, {
		4.do({ |j| slDispList[taskNo][j].valueAction_(listTaskCont[20][j]) }); // 20 - dispersion
	})
};

// copy-paste mechanism - end of
//=====================



//=====================
//random controls
fillRandom = { |taskNo|
	var randDistr;
	slWide[taskNo].valueAction_( rrand(0.5, 1.0) );
	btDirWide[taskNo].value = [0,1,2].choose;
	4.do({ |j|
		pmDistrModeList[taskNo][j].valueAction_( distrMode.size.rand ); // distr mode
		randDistr = distrMode.at(pmDistrModeList[taskNo][j].value).containsStringAt(0, "RN") == true; // if random only forth and back
		slCycList[taskNo][j].valueAction_( 0.2.rand ); // cycles - scope is 2000, random scope ~ 350
		btDirVolList[taskNo][j].value = if(randDistr == true, {[0,1].choose}, {[0,1,2].choose}); // dir button Vol
		rslVolList[taskNo][j].activeLo_( 0.5.rand ); // Vol rslid Lo
		rslVolList[taskNo][j].activeHi_( rrand(rslVolList[taskNo][j].lo + rrand(0.1, 1-rslVolList[taskNo][j].lo), 1.0) ); // Vol rslid Hi
		btDirDurList[taskNo][j].value = if(randDistr == true, {[0,1].choose}, {[0,1,2].choose}); // dir button Dur
		rslDurList[taskNo][j].activeLo_( 0.5.rand ); // Dur rslid Lo
		rslDurList[taskNo][j].activeHi_( rrand(rslDurList[taskNo][j].lo, 1.0) ); // Dur rslid Hi
		btDirRatList[taskNo][j].value = if(randDistr == true, {[0,1].choose}, {[0,1,2].choose}); // dir button Rat
		rslRatList[taskNo][j].activeLo_( if([0,1].choose == 0, { 0.2.rand }, { rrand(0.53, 0.70) }) ); // Rat rslid Lo
		rslRatList[taskNo][j].activeHi_( rslRatList[taskNo][j].lo + rrand(0.1, 1-rslRatList[taskNo][j].lo) ); // Rat rslid Hi
		btDirPosList[taskNo][j].value = if(randDistr == true, {[0,1].choose}, {[0,1,2].choose}); // dir button Pos
		rslPosList[taskNo][j].activeLo_( 0.8.rand ); // Pos rslid Lo
		rslPosList[taskNo][j].activeHi_( rrand(rslPosList[taskNo][j].lo, 1) ); // Pos rslid Hi
	});
};
//random controls - end
//=====================


//=====================
//clean controls
contClean = { |taskNo|
	slWide[taskNo].valueAction_(0.7);
	btDirWide[taskNo].value = 0;
	4.do({ |j|
		pmDistrModeList[taskNo][j].valueAction_(j); // distr mode
		slCycList[taskNo][j].valueAction_(0); // cycles - scope is 2000, random scope ~ 350
		btDirVolList[taskNo][j].value = 0; // dir button Vol
		rslVolList[taskNo][j].activeLo_(0); // Vol rslid Lo
		rslVolList[taskNo][j].activeHi_(0); // Vol rslid Hi
		btDirDurList[taskNo][j].value = 0; // dir button Dur
		rslDurList[taskNo][j].activeLo_(0); // Dur rslid Lo
		rslDurList[taskNo][j].activeHi_(0); // Dur rslid Hi
		btDirRatList[taskNo][j].value = 0; // dir button Rat
		rslRatList[taskNo][j].activeLo_(0); // Rat rslid Lo
		rslRatList[taskNo][j].activeHi_(0); // Rat rslid Hi
		btDirPosList[taskNo][j].value = 0; // dir button Pos
		rslPosList[taskNo][j].activeLo_(0); // Pos rslid Lo
		rslPosList[taskNo][j].activeHi_(0); // Pos rslid Hi
	});
};
//clean controls - end
//=====================



loadFileList = {arg pn;
	poolName = pn;
	sndNameList = []; bufnumList = List.new; bufDurList = List.new;
	bufnumList.add(tmpBuffer.bufnum);
	bufDurList.add(tmpBuffer.numFrames/tmpBuffer.sampleRate);
	sndNameList.add("internal buffer");
	if(try { XQ.globalBufferDict.at(poolName)[0] } != nil, {
		XQ.globalBufferDict.at(poolName)[0].do({ arg buffer, i;
			sndNameList = sndNameList.add(buffer.path.basename);
			bufnumList.add(buffer.bufnum);
			bufDurList.add(buffer.numFrames / buffer.sampleRate); // buffer length in seconds
		 });
	});
	// put the new sounds into popupmenus
	taskNum.do({ |j|
		pmFileList[j].items_(sndNameList);
		pmFileList[j].value = j;
	});
};

updateDurCtlSpec = { |taskNo|
	//update duration sliders
	bufDurSpecList[taskNo] = ([0, bufDurList[taskNo], \lin, 0.1, 0, "s"].asSpec); // buffer length Spec
	4.do({ |j|
		stPosLoList[taskNo][j].string_(bufDurSpecList[taskNo].map(rslPosList[taskNo][j].lo));
		stPosHiList[taskNo][j].string_(bufDurSpecList[taskNo].map(rslPosList[taskNo][j].hi));
	});
};

// =======================
//task definition function
defTask = { arg taskNo, action, loopMode;
// i, action (0 Play/1 Pause/2 Reset/3 Stop), loopMode (0/1)
	var	dMode = Array.fill(4, nil),
		cycNum = Array.fill(4, nil), dispVal = Array.fill(4, nil),
		volMode = Array.fill(4, nil), volLo = Array.fill(4, nil), volHi = Array.fill(4, nil),
		durMode = Array.fill(4, nil), durLo = Array.fill(4, nil), durHi = Array.fill(4, nil),
		ratMode = Array.fill(4, nil), ratLo = Array.fill(4, nil), ratHi = Array.fill(4, nil),
		posMode = Array.fill(4, nil), posLo = Array.fill(4, nil), posHi = Array.fill(4, nil),
		wideMode, wideValue, grainVol, grainDur, grainRat, grainPos, grainPan, grainCh, currBufnum, cycTotal = 0,
		rp, theVol;
	4.do({ arg i;
		dMode[i] = pmDistrModeList[taskNo][i].value;
		cycNum[i] = nbCycList[taskNo][i].value;
		dispVal[i] = specDisp.map(slDispList[taskNo][i].value);
		cycTotal = cycTotal + if(nbCycList[taskNo][i].value != nil, { nbCycList[taskNo][i].value },  { 0 });
		volMode[i] = btDirVolList[taskNo][i].value; volLo[i] = rslVolList[taskNo][i].lo; volHi[i] = rslVolList[taskNo][i].hi;
		durMode[i] = btDirDurList[taskNo][i].value; durLo[i] = rslDurList[taskNo][i].lo; durHi[i] = rslDurList[taskNo][i].hi;
		ratMode[i] = btDirRatList[taskNo][i].value; ratLo[i] = rslRatList[taskNo][i].lo; ratHi[i] = rslRatList[taskNo][i].hi;
		posMode[i] = btDirPosList[taskNo][i].value; posLo[i] = rslPosList[taskNo][i].lo; posHi[i] = rslPosList[taskNo][i].hi;
	});
	wideMode = btDirWide[taskNo].value;
	wideValue = slWide[taskNo].value;

	grainCh = pmChList[taskNo].value * 2;
	currBufnum = bufnumList.at(pmFileList[taskNo].value);

	rp = RedPerlin.new;

	//action (0 Play/1 Pause/2 Reset/3 Stop)
	case
		{ action == 0 } {
			if(taskList[taskNo] != nil, {
				taskList[taskNo].play;
			}, {
				taskList[taskNo] = (
					Task.new({
						var waitTime, cnt = 0;
						inf.do({
							4.do({ |j|
								{ // switch on progress bar
									rslRunIndList[taskNo][j].hi = 0;
									rslRunIndList[taskNo][j].visible_(true)
								}.defer;
								cycNum[j].do({ arg i;
									//bookmark - CHECK THE FORMULAS IF THEY ARE CORRECT
									//consider these formulaes as well (qubic root - faster change):
//									{j == 1} { 1-(i/(cycNum[j]-1))**(0.333) } // waiting time decreases based on the root of 3
//									{j == 2} { (i/(cycNum[j]-1))**(0.333) } // waiting time increases based on the root of 3

									var timeprop = case
										{dMode[j] == 0} { 1-(i/(cycNum[j]-1))**3 } // UP **3 - wait time (WT) decreases
										{dMode[j] == 1} { (i/(cycNum[j]-1))**3 } // DW **3 - WT increases
										{dMode[j] == 2} { 1-(i/(cycNum[j]-1)).sqrt } // UP sqrt - WT decreases
										{dMode[j] == 3} { (i/(cycNum[j]-1)).sqrt } // DW sqrt - WT increases
										{dMode[j] == 4} { 1-sin( (i/(cycNum[j]-1))**2 * 0.5pi ) } // UP sin - WT decreases
										{dMode[j] == 5} { sin( (i/(cycNum[j]-1))**2 * 0.5pi ) } // DW sin - WT increases
										{dMode[j] == 6} { i/(cycNum[j]-1).linrand } // RN lin - WT based on linrand
										{dMode[j] == 7} { abs(rp.noise1D(i/(cycNum[j]-1), 0.75, 8, 1)) }; // RN perl - WT on perlin distrib

										if(timeprop < 0, {timeprop = 0});
										if(timeprop > 1, {timeprop = [1, exprand(0.01, 1)].choose});

									grainVol = case
										{ volMode[j] == 0 } { volHi[j] - (timeprop * (volHi[j] - volLo[j])) }
										{ volMode[j] == 1 } { timeprop * (volHi[j] - volLo[j]) + volLo[j] }
										{ volMode[j] == 2 } { exprand(volLo[j], volHi[j]) };
									grainDur = case
										{ durMode[j] == 0 } { durHi[j] - (timeprop * (durHi[j] - durLo[j])) }
										{ durMode[j] == 1 } { timeprop * (durHi[j] - durLo[j]) + durLo[j] }
										{ durMode[j] == 2 } { exprand(durLo[j], durHi[j]) };
									grainRat = case
										{ ratMode[j] == 0 } { ratHi[j] - (timeprop * (ratHi[j] - ratLo[j])) }
										{ ratMode[j] == 1 } { timeprop * (ratHi[j] - ratLo[j]) + ratLo[j] }
										{ ratMode[j] == 2 } { exprand(ratLo[j], ratHi[j]) };
									grainPos = case
										{ posMode[j] == 0 } { posHi[j] - (timeprop * (posHi[j] - posLo[j])) }
										{ posMode[j] == 1 } { timeprop * (posHi[j] - posLo[j]) + posLo[j] }
										{ posMode[j] == 2 } { exprand(posLo[j], posHi[j]) };
									grainPan = case
										{ wideMode == 0 } { ((cnt - (cycTotal/2)) / (cycTotal/2)) * wideValue }
										{ wideMode == 1 } { (0 - (cnt - (cycTotal/2)) / (cycTotal/2)) * wideValue }
										{ wideMode == 2 } { rand2(wideValue) };

									{ theVol = theVolume.value; }.defer;

									Synth(\sgrain2,[\bufnum, currBufnum, \busnum, grainCh, \amp, grainVol, \dur, grainDur, \rate, specRat.map(grainRat), \startPos, grainPos, \pan, grainPan, \vol, theVol]);

									//changing direction of panorama distrib in case of loop
									if(cnt == cycTotal, {
										cnt = 0;
										if (wideMode != 2, { wideMode = 1-wideMode });
									}, {
										cnt = cnt + 1
									});

									if(volHi[j] == 0, {
										waitTime = rrand(durLo[j].max(0.1), durHi[j].max(0.2))
									}, {
										//waitTime = exprand( (timeprop*0.1).max(0.01), timeprop*dispVal[j] );
										waitTime = timeprop*dispVal[j];
									});

									// progress-bar shows the proportion of time (hi) and progress (lo)
									{
										rslRunIndList[taskNo][j].hi = 1-timeprop;
										rslRunIndList[taskNo][j].lo = i/cycNum[j];
									}.defer;

									waitTime.wait;
								});
								{ rslRunIndList[taskNo][j].visible_(false) }.defer; // switch off progress bar
							});

							if(loopMode == 0, {
								taskList[taskNo].stop;
								taskList[taskNo] = nil;
								{
									btPlay[taskNo].value = 0
								}.defer;
							});
							0.1.wait;
						});
					}).start;
				);
			});
		}
		{ action == 1 } { if(taskList[taskNo] != nil, { taskList[taskNo].pause }) }
		{ action == 2 } { if(taskList[taskNo] != nil, { taskList[taskNo].reset }) }
		{ action == 3 } { if(taskList[taskNo] != nil, { taskList[taskNo].stop; taskList[taskNo] = nil }) };
};
//end of task definition function
// ==============================


minimizeWaveSection = {arg secNo;
	var bounds;
	// hide range sliders and their labels
	4.do({ |j|
		btDirVolList[secNo][j].visible_(false); lbVolList[secNo][j].visible_(false);
		rslVolList[secNo][j].visible_(false); stVolLoList[secNo][j].visible_(false); stVolHiList[secNo][j].visible_(false);
		btDirDurList[secNo][j].visible_(false); lbDurList[secNo][j].visible_(false);
		rslDurList[secNo][j].visible_(false); stDurLoList[secNo][j].visible_(false); stDurHiList[secNo][j].visible_(false);
		btDirRatList[secNo][j].visible_(false); lbRatList[secNo][j].visible_(false);
		rslRatList[secNo][j].visible_(false); stRatLoList[secNo][j].visible_(false); stRatHiList[secNo][j].visible_(false);
		btDirPosList[secNo][j].visible_(false); lbPosList[secNo][j].visible_(false);
		rslPosList[secNo][j].visible_(false); stPosLoList[secNo][j].visible_(false); stPosHiList[secNo][j].visible_(false);
	});
	// move task's bottom controls up
	bounds = pmChList[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; pmChList[secNo].bounds = bounds;
	bounds = btDirWide[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; btDirWide[secNo].bounds = bounds;
	bounds = slWide[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; slWide[secNo].bounds = bounds;
	bounds = stWide[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; stWide[secNo].bounds = bounds;
	bounds = lbWide[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; lbWide[secNo].bounds = bounds;
	bounds = pmFileList[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; pmFileList[secNo].bounds = bounds;
	bounds = lbFileList[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; lbFileList[secNo].bounds = bounds;
	bounds = btLoop[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; btLoop[secNo].bounds = bounds;
	bounds = lbLoop[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; lbLoop[secNo].bounds = bounds;
	bounds = btPlay[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; btPlay[secNo].bounds = bounds;
	bounds = btRestart[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; btRestart[secNo].bounds = bounds;
	bounds = btStop[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; btStop[secNo].bounds = bounds;
	bounds = btSlot[secNo].bounds; bounds.top = bounds.top - hrIndex + 60; btSlot[secNo].bounds = bounds;
	// move the rest up
	if(secNo < (taskNum-1), {
		for (secNo+1, taskNum-1, { arg n;
			4.do({ arg m;
				bounds = rslRunIndList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; rslRunIndList[n][m].bounds = bounds;
				bounds = lbLabelsList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbLabelsList[n][m].bounds = bounds;
				bounds = slCycList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; slCycList[n][m].bounds = bounds;
				bounds = pmDistrModeList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; pmDistrModeList[n][m].bounds = bounds;
				bounds = nbCycList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; nbCycList[n][m].bounds = bounds;
				bounds = lbCycList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbCycList[n][m].bounds = bounds;
				bounds = slDispList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; slDispList[n][m].bounds = bounds;
				bounds = lbDispList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbDispList[n][m].bounds = bounds;
				bounds = btDirVolList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; btDirVolList[n][m].bounds = bounds;
				bounds = rslVolList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; rslVolList[n][m].bounds = bounds;
				bounds = stVolLoList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stVolLoList[n][m].bounds = bounds;
				bounds = stVolHiList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stVolHiList[n][m].bounds = bounds;
				bounds = lbVolList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbVolList[n][m].bounds = bounds;
				bounds = btDirDurList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; btDirDurList[n][m].bounds = bounds;
				bounds = rslDurList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; rslDurList[n][m].bounds = bounds;
				bounds = stDurLoList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stDurLoList[n][m].bounds = bounds;
				bounds = stDurHiList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stDurHiList[n][m].bounds = bounds;
				bounds = lbDurList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbDurList[n][m].bounds = bounds;
				bounds = btDirRatList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; btDirRatList[n][m].bounds = bounds;
				bounds = rslRatList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; rslRatList[n][m].bounds = bounds;
				bounds = stRatLoList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stRatLoList[n][m].bounds = bounds;
				bounds = stRatHiList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stRatHiList[n][m].bounds = bounds;
				bounds = lbRatList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbRatList[n][m].bounds = bounds;
				bounds = btDirPosList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; btDirPosList[n][m].bounds = bounds;
				bounds = rslPosList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; rslPosList[n][m].bounds = bounds;
				bounds = stPosLoList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stPosLoList[n][m].bounds = bounds;
				bounds = stPosHiList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; stPosHiList[n][m].bounds = bounds;
				bounds = lbPosList[n][m].bounds; bounds.top = bounds.top - hrIndex + 60; lbPosList[n][m].bounds = bounds;
			});
			bounds = lbTask[n].bounds; bounds.top = bounds.top - hrIndex + 60; lbTask[n].bounds = bounds;
			bounds = pmChList[n].bounds; bounds.top = bounds.top - hrIndex + 60; pmChList[n].bounds = bounds;
			bounds = btDirWide[n].bounds; bounds.top = bounds.top - hrIndex + 60; btDirWide[n].bounds = bounds;
			bounds = slWide[n].bounds; bounds.top = bounds.top - hrIndex + 60; slWide[n].bounds = bounds;
			bounds = stWide[n].bounds; bounds.top = bounds.top - hrIndex + 60; stWide[n].bounds = bounds;
			bounds = lbWide[n].bounds; bounds.top = bounds.top - hrIndex + 60; lbWide[n].bounds = bounds;
			bounds = pmFileList[n].bounds; bounds.top = bounds.top - hrIndex + 60; pmFileList[n].bounds = bounds;
			bounds = lbFileList[n].bounds; bounds.top = bounds.top - hrIndex + 60; lbFileList[n].bounds = bounds;
			bounds = lbLoop[n].bounds; bounds.top = bounds.top - hrIndex + 60; lbLoop[n].bounds = bounds;
			bounds = btLoop[n].bounds; bounds.top = bounds.top - hrIndex + 60; btLoop[n].bounds = bounds;
			bounds = btPlay[n].bounds; bounds.top = bounds.top - hrIndex + 60; btPlay[n].bounds = bounds;
			bounds = btRestart[n].bounds; bounds.top = bounds.top - hrIndex + 60; btRestart[n].bounds = bounds;
			bounds = btStop[n].bounds; bounds.top = bounds.top - hrIndex + 60; btStop[n].bounds = bounds;
			bounds = btSlot[n].bounds; bounds.top = bounds.top - hrIndex + 60; btSlot[n].bounds = bounds;
		});
	});
	bounds = w.bounds; bounds.height = bounds.height - hrIndex + 60; w.bounds = bounds;
	w.refresh;
};

restoreWaveSection = {arg secNo;
	var bounds;
	//adjust window height
	bounds = w.bounds; bounds.height = bounds.height + (hrIndex - 60); w.bounds = bounds;
	// move the rest down
	if(secNo < (taskNum-1), {
		for (secNo+1, taskNum-1, { arg n;
			4.do({ arg m;
				bounds = rslRunIndList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); rslRunIndList[n][m].bounds = bounds;
				bounds = lbLabelsList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbLabelsList[n][m].bounds = bounds;
				bounds = slCycList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); slCycList[n][m].bounds = bounds;
				bounds = pmDistrModeList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); pmDistrModeList[n][m].bounds = bounds;
				bounds = nbCycList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); nbCycList[n][m].bounds = bounds;
				bounds = lbCycList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbCycList[n][m].bounds = bounds;
				bounds = slDispList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); slDispList[n][m].bounds = bounds;
				bounds = lbDispList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbDispList[n][m].bounds = bounds;
				bounds = btDirVolList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); btDirVolList[n][m].bounds = bounds;
				bounds = rslVolList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); rslVolList[n][m].bounds = bounds;
				bounds = stVolLoList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stVolLoList[n][m].bounds = bounds;
				bounds = stVolHiList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stVolHiList[n][m].bounds = bounds;
				bounds = lbVolList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbVolList[n][m].bounds = bounds;
				bounds = btDirDurList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); btDirDurList[n][m].bounds = bounds;
				bounds = rslDurList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); rslDurList[n][m].bounds = bounds;
				bounds = stDurLoList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stDurLoList[n][m].bounds = bounds;
				bounds = stDurHiList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stDurHiList[n][m].bounds = bounds;
				bounds = lbDurList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbDurList[n][m].bounds = bounds;
				bounds = btDirRatList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); btDirRatList[n][m].bounds = bounds;
				bounds = rslRatList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); rslRatList[n][m].bounds = bounds;
				bounds = stRatLoList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stRatLoList[n][m].bounds = bounds;
				bounds = stRatHiList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stRatHiList[n][m].bounds = bounds;
				bounds = lbRatList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbRatList[n][m].bounds = bounds;
				bounds = btDirPosList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); btDirPosList[n][m].bounds = bounds;
				bounds = rslPosList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); rslPosList[n][m].bounds = bounds;
				bounds = stPosLoList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stPosLoList[n][m].bounds = bounds;
				bounds = stPosHiList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); stPosHiList[n][m].bounds = bounds;
				bounds = lbPosList[n][m].bounds; bounds.top = bounds.top + (hrIndex - 60); lbPosList[n][m].bounds = bounds;
			});
			bounds = lbTask[n].bounds; bounds.top = bounds.top + (hrIndex - 60); lbTask[n].bounds = bounds;
			bounds = pmChList[n].bounds; bounds.top = bounds.top + (hrIndex - 60); pmChList[n].bounds = bounds;
			bounds = btDirWide[n].bounds; bounds.top = bounds.top + (hrIndex - 60); btDirWide[n].bounds = bounds;
			bounds = slWide[n].bounds; bounds.top = bounds.top + (hrIndex - 60); slWide[n].bounds = bounds;
			bounds = stWide[n].bounds; bounds.top = bounds.top + (hrIndex - 60); stWide[n].bounds = bounds;
			bounds = lbWide[n].bounds; bounds.top = bounds.top + (hrIndex - 60); lbWide[n].bounds = bounds;
			bounds = pmFileList[n].bounds; bounds.top = bounds.top + (hrIndex - 60); pmFileList[n].bounds = bounds;
			bounds = lbFileList[n].bounds; bounds.top = bounds.top + (hrIndex - 60); lbFileList[n].bounds = bounds;
			bounds = lbLoop[n].bounds; bounds.top = bounds.top + (hrIndex - 60); lbLoop[n].bounds = bounds;
			bounds = btLoop[n].bounds; bounds.top = bounds.top + (hrIndex - 60); btLoop[n].bounds = bounds;
			bounds = btPlay[n].bounds; bounds.top = bounds.top + (hrIndex - 60); btPlay[n].bounds = bounds;
			bounds = btRestart[n].bounds; bounds.top = bounds.top + (hrIndex - 60); btRestart[n].bounds = bounds;
			bounds = btStop[n].bounds; bounds.top = bounds.top + (hrIndex - 60); btStop[n].bounds = bounds;
			bounds = btSlot[n].bounds; bounds.top = bounds.top + (hrIndex - 60); btSlot[n].bounds = bounds;
		});
	});
	// move task's bottom controls down
	bounds = pmChList[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); pmChList[secNo].bounds = bounds;
	bounds = btDirWide[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); btDirWide[secNo].bounds = bounds;
	bounds = slWide[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); slWide[secNo].bounds = bounds;
	bounds = stWide[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); stWide[secNo].bounds = bounds;
	bounds = lbWide[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); lbWide[secNo].bounds = bounds;
	bounds = pmFileList[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); pmFileList[secNo].bounds = bounds;
	bounds = lbFileList[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); lbFileList[secNo].bounds = bounds;
	bounds = btLoop[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); btLoop[secNo].bounds = bounds;
	bounds = lbLoop[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); lbLoop[secNo].bounds = bounds;
	bounds = btPlay[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); btPlay[secNo].bounds = bounds;
	bounds = btRestart[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); btRestart[secNo].bounds = bounds;
	bounds = btStop[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); btStop[secNo].bounds = bounds;
	bounds = btSlot[secNo].bounds; bounds.top = bounds.top + (hrIndex - 60); btSlot[secNo].bounds = bounds;
	// show range sliders and their labels
	4.do({ |j|
		btDirVolList[secNo][j].visible_(true); lbVolList[secNo][j].visible_(true);
		rslVolList[secNo][j].visible_(true); stVolLoList[secNo][j].visible_(true); stVolHiList[secNo][j].visible_(true);
		btDirDurList[secNo][j].visible_(true); lbDurList[secNo][j].visible_(true);
		rslDurList[secNo][j].visible_(true); stDurLoList[secNo][j].visible_(true); stDurHiList[secNo][j].visible_(true);
		btDirRatList[secNo][j].visible_(true); lbRatList[secNo][j].visible_(true);
		rslRatList[secNo][j].visible_(true); stRatLoList[secNo][j].visible_(true); stRatHiList[secNo][j].visible_(true);
		btDirPosList[secNo][j].visible_(true); lbPosList[secNo][j].visible_(true);
		rslPosList[secNo][j].visible_(true); stPosLoList[secNo][j].visible_(true); stPosHiList[secNo][j].visible_(true);
	});
};

// update pool and fileList on window open
poolnamesarray = XQ.globalBufferDict.keys.asArray.sort;
pool = poolList.items.at(poolList.value);
poolList.items_(poolnamesarray);
poolindex = poolList.items.indexOf(pool);
if(poolindex == nil, {
	poolList.value_(0);
	loadFileList.value(poolnamesarray[0]);
},{
	poolList.value_(poolindex);
	loadFileList.value(pool);
});

poolList.valueAction_(0);
loadFileList.value(XQ.poolNames[0].asSymbol); // load the first pool


//MIDI
MIDIClient.init(13,3);			// explicitly intialize the client
13.do({ arg i; MIDIIn.connect(i, MIDIClient.sources.at(i)); });
ccResp = CCResponder({ |src, chan, num, val|
//	var one2fourKeys=  #[15, 85, 86, 87]; // OLD SETTINGS
	var one2Keys=  #[86, 89];
	var currIndex;
 	[src,chan,num,val].postln;
//	if( one2fourKeys.includes(num) == true, { // 1 to 4 - start/stop task // OLD SETTINGS
//		currIndex= one2fourKeys.indexOf(num.asInteger);
	if( one2Keys.includes(num) == true, { // 1 & 2 - start/stop task (only 1st and 2nd automated!!)
		currIndex= one2Keys.indexOf(num.asInteger);
		{
			if(btPlay[currIndex].value == 0, {
				btPlay[currIndex].valueAction_(1)
			},{
				btStop[currIndex].valueAction_(1)
			});
		}.defer;
	});

	case
	{ num == 119 } { // 9 - next pre-set
		if(psetList.indicesOfEqual(nil) != nil, { // are there any pre-set?
			currIndex= 0;
			if(psetCurr <= psetNum, {
				currIndex= psetCurr + 1;
				while({ psetList[currIndex] == nil }, {
					currIndex= currIndex + 1;
					if(currIndex > psetNum, {currIndex= 0} );
				})
			});
			{
				//["psetCurr", "psetNum", "currIndex", psetCurr, psetNum, currIndex].postln;
				psetButtList[currIndex].valueAction_(1 - psetButtList[currIndex].value);
			}.defer;

		});
	}
	{ num == 14 } { // 0 - start/stop recording into buffer
		{
			if(btInputLoop.value == 0, { btInputLoop.value_(1) });
			btInputRec.valueAction_(1-btInputRec.value);
		}.defer
	}
	{ num == 63 } { // theVolume
		{
			theVolume.valueAction_(val.linlin(0,127, 0,1));
		}.defer
	};
},
nil, 0, nil, nil );
//MIDI

//collapse all
btSlotAll.valueAction_(1);

w.refresh;
w.front;
w.onClose = {
	SystemClock.clear;
	ccResp.remove; //MIDI

	presetsFile = File.new("preferences/granwavepset.dk", "w");
	presetsFile.write(psetList.asCompileString);
	presetsFile.close;
};

)