// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:notesapp/core/controllers/recording_handler.dart';
// import 'package:record/record.dart';
// import 'package:siri_wave/siri_wave.dart';

// class LiveSiriWave extends StatefulWidget {
//   const LiveSiriWave({super.key, this.height = 100});
//   final double height;

//   @override
//   State<LiveSiriWave> createState() => _LiveSiriWaveState();
// }

// class _LiveSiriWaveState extends State<LiveSiriWave>
//     with SingleTickerProviderStateMixin {
//   final Recorder _recorder = Recorder();
//   late final IOS7SiriWaveformController _controller;
//   late final Ticker _ticker;
//   StreamSubscription<Amplitude>? _sub;
//   double _currentAmplitude = 0.0;

//   @override
//   void initState() {
//     super.initState();

//     _controller = IOS7SiriWaveformController(
//       amplitude: 0.0,
//       color: Colors.greenAccent,
//       frequency: 3,
//       speed: 0.35,
//     );

//     // Force a repaint each frame
//     _ticker = createTicker((_) {
//       if (mounted) {
//         setState(() {
//           _controller.amplitude = _currentAmplitude;
//         });
//       }
//     })..start();

//     _sub = _recorder
//         .onAmplitudeChanged(const Duration(milliseconds: 30))
//         .listen((amp) {
//       double db = amp.current.isNaN ? -45.0 : amp.current;
//       if (db > 0) db = -db;

//       double normalized = (db + 45) / 45;
//       normalized = ((normalized - 0.05) * 1.5).clamp(0.0, 1.0);

//       _currentAmplitude = _currentAmplitude * 0.7 + normalized * 0.3;
//     });
//   }

//   @override
//   void dispose() {
//     _ticker.dispose();
//     _sub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RepaintBoundary(
//       child: SiriWaveform.ios7(
//         controller: _controller,
//         options: IOS7SiriWaveformOptions(
//           height: widget.height,
//           width: MediaQuery.of(context).size.width - 120,
//         ),
//       ),
//     );
//   }
// }
