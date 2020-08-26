import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:xfyun_ise/xfyun_ise.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  EvaluatorListener listener;
  ChapterResult result;
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      await XfyunIse.init(appId: '1wq12ds');
      //通过writeaudio方式直接写入音频时才需要此设置
      //mIse.setParameter(SpeechConstant.AUDIO_SOURCE,"-1");
      var dir = await getTemporaryDirectory();

      XfyunIse.setParameter(IseParam()
        ..language = 'en_us'
        ..category = 'read_chapter'
        ..textEncoding = 'utf-8'
        ..vadBos = '5000'
        ..vadEos = '1800'
        ..speechTimeout = '-1'
        ..resultLevel = 'complete'
        ..aue = 'opus'
        ..audioFormat = 'wav'
        ..iseAudioPath = "${dir.path}/isetest.wav"
        ..resultType = "json"
        ..plev = '0'
        ..audioSource = '-1');
    } on PlatformException {}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    listener = EvaluatorListener(onResult: (result) => setState(() => this.result = result));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: result == null ? Text('待评测') : Text('''
                  篇章开始: ${result.begPos}, 篇章结束: ${result.endPos}。
                  篇章内容: ${result.content}。
                  单词数量: ${result.wordCount}。
                  总分: ${result.totalScore}。
                  准确度评分: ${result.accuracyScore}。
                  流畅度评分: ${result.fluencyScore}。
                  完整度评分: ${result.integrityScore}。
                  标准度评分: ${result.standardScore}。
                '''),
            ),
            Center(
              child: FlatButton(
                child: Text('开始评测'),
                onPressed: () async {
                  XfyunIse.instance.start(
                    listener: listener,
                    text: '''
                    First-year university students have designed and built a groundbreaking electric car that recharges itself. Fifty students from the University of Sydney's Faculty of Engineering spent five months working together bits of plywood, foam and fiberglass to build the ManGo concept car. They developed the specifications and hand built the car. It's a?pretty radical design: a four-wheel drive with a motor in each wheel.
                    ''',
                  );
                  ByteData audioData = await NetworkAssetBundle(
                    Uri.parse('https://test-downloads.91ddedu.com'),
                  ).load('audio/5186/839f9cc6-4d27-4a4e-9a59-9b5dbf2e6ac0.wav');
                  Uint8List audioUnitData = audioData.buffer.asUint8List();
                  try {
                    XfyunIse.instance.writeAudio(audioUnitData);
                  } catch (e) {
                    print(e);
                  }

                  Future.delayed(Duration(milliseconds: 100), () => XfyunIse.instance.stop());
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
