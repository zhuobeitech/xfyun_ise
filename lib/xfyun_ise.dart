import 'dart:async';
import 'dart:typed_data';

import 'package:xml/xml.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class XfyunIse {
  static const MethodChannel _channel = const MethodChannel('com.zhuobeitech/xfyun_ise');

  static final XfyunIse instance = XfyunIse._();

  XfyunIse._();

  static Future<void> init({@required String appId}) async {
    await _channel.invokeMethod('init', appId);
    _channel.setMethodCallHandler((MethodCall call) async {
      print(call.method);
      print(call.arguments.toString());
    });
  }

  static Future<void> setParameter(IseParam param) async {
    await _channel.invokeMethod('setParameter', param.toMap());
  }

  Future<void> start({
    EvaluatorListener listener,
    @required String text,
  }) async {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onBeginOfSpeech' && listener?.onBeginOfSpeech != null) {
        listener.onBeginOfSpeech();
      } else if (call.method == 'onEndOfSpeech' && listener?.onEndOfSpeech != null) {
        listener.onEndOfSpeech();
      } else if (call.method == 'onResult' && listener?.onResult != null) {
        String result = call.arguments;
        listener.onResult(_parseRet(result));
      } else if (call.method == 'onVolumeChanged' && listener?.onVolumeChanged != null) {
        listener.onVolumeChanged(call.arguments);
      } else if (call.method == 'onError' && listener?.onError != null) {
        listener.onError(call.arguments);
      }
    });
    await _channel.invokeMethod('start', {'text': text});
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
  }

  Future<void> cancel() async {
    await _channel.invokeMethod('cancel');
  }

  Future<void> writeAudio(Uint8List data) async {
    await _channel.invokeMethod('writeAudio', {
      'data': data,
    });
  }

  /// 是否在会话中，通过此函数，获取当前SDK是否正在进行会话。
  Future<bool> isEvaluating() async {
    bool ret = await _channel.invokeMethod('isEvaluating');
    return ret;
  }

  /// 用完记得释放listener
  void clearListener() {
    _channel.setMethodCallHandler(null);
  }

  ChapterResult _parseRet(String result) {
    XmlDocument document = parse(result);
    XmlElement emelent =
        document.findAllElements("rec_paper").first.findAllElements("read_chapter")?.first;
    return ChapterResult.fromXml(emelent);
  }
}

/// 讯飞语音识别的回调映射，有flutter来决定处理所有的回调结果，
/// 会更具有灵活性
class EvaluatorListener {
  VoidCallback onEndOfSpeech;
  VoidCallback onBeginOfSpeech;

  /// error信息构成的key-value map，[filePath]是音频文件路径
  void Function(ChapterResult result) onResult;
  void Function(Map<dynamic, dynamic> error) onError;
  void Function(int volume) onVolumeChanged;

  EvaluatorListener({
    this.onBeginOfSpeech,
    this.onResult,
    this.onVolumeChanged,
    this.onEndOfSpeech,
    this.onError,
  });
}

class ChapterResult {
  String fluencyScore;
  String integrityScore;
  String isRejected;
  String standardScore;
  String wordCount;
  String accuracyScore;
  String content;
  String exceptInfo;
  List<SentenceResult> sentence;
  String begPos;
  String endPos;
  String totalScore;

  ChapterResult.fromXml(XmlElement emelent)
      : fluencyScore = emelent.getAttribute('fluency_score'),
        integrityScore = emelent.getAttribute('integrity_score'),
        isRejected = emelent.getAttribute('is_rejected'),
        standardScore = emelent.getAttribute('standard_score'),
        wordCount = emelent.getAttribute('word_count'),
        accuracyScore = emelent.getAttribute('accuracy_score'),
        content = emelent.getAttribute('content'),
        exceptInfo = emelent.getAttribute('except_info'),
        sentence = (emelent.findElements('sentence') ?? [])
            .map<SentenceResult>((item) => SentenceResult.fromXml(item))
            ?.toList(),
        begPos = emelent.getAttribute('beg_pos'),
        endPos = emelent.getAttribute('end_pos'),
        totalScore = emelent.getAttribute('total_score');

  ChapterResult.fromJson(Map<String, dynamic> json)
      : fluencyScore = json['fluency_score'],
        integrityScore = json['integrity_score'],
        isRejected = json['is_rejected'],
        standardScore = json['standard_score'],
        wordCount = json['word_count'],
        accuracyScore = json['accuracy_score'],
        content = json['content'],
        exceptInfo = json['except_info'],
        sentence = (json['sentence'] ?? [])
            .map<SentenceResult>((item) => SentenceResult.fromJson(item))
            .toList(),
        begPos = json['beg_pos'],
        endPos = json['end_pos'],
        totalScore = json['total_score'];

  Map<String, dynamic> toJson() => {
        'fluency_score': fluencyScore,
        'integrity_score': integrityScore,
        'is_rejected': isRejected,
        'standard_score': standardScore,
        'word_count': wordCount,
        'accuracy_score': accuracyScore,
        'content': content,
        'sentence': sentence,
        'beg_pos': begPos,
        'end_pos': endPos,
        'total_score': totalScore,
      };
}

class SentenceResult {
  String accuracyScore;
  String begPos;
  String content;
  String endPos;
  String fluencyScore;
  String standardScore;
  String totalScore;
  String wordCount;
  List<WordResult> word;
  String index;

  SentenceResult.fromXml(XmlElement emelent)
      : accuracyScore = emelent.getAttribute('accuracy_score'),
        begPos = emelent.getAttribute('beg_pos'),
        content = emelent.getAttribute('content'),
        endPos = emelent.getAttribute('end_pos'),
        fluencyScore = emelent.getAttribute('fluency_score'),
        standardScore = emelent.getAttribute('standard_score'),
        totalScore = emelent.getAttribute('total_score'),
        wordCount = emelent.getAttribute('word_count'),
        word = (emelent.findElements('word') ?? [])
            .map<WordResult>((item) => WordResult.fromXml(item))
            .toList(),
        index = emelent.getAttribute('beg_pos');

  SentenceResult.fromJson(Map<String, dynamic> json)
      : accuracyScore = json['accuracy_score'],
        begPos = json['beg_pos'],
        content = json['content'],
        endPos = json['end_pos'],
        fluencyScore = json['fluency_score'],
        standardScore = json['standard_score'],
        totalScore = json['total_score'],
        wordCount = json['word_count'],
        word = (json['word'] ?? []).map<WordResult>((item) => WordResult.fromJson(item)).toList(),
        index = json['beg_pos'];

  Map<String, dynamic> toJson() => {
        'accuracy_score': accuracyScore,
        'beg_pos': begPos,
        'content': content,
        'end_pos': endPos,
        'fluency_score': fluencyScore,
        'standard_score': standardScore,
        'total_score': totalScore,
        'word_count': wordCount,
        'word': word,
        'beg_pos': index,
      };
}

class WordResult {
  String dpMessage;
  String globalIndex;
  String index;
  String property;
  String totalScore;
  List<SyllResult> syll;
  String content;
  String endPos;
  String begPos;

  WordResult.fromXml(XmlElement emelent)
      : dpMessage = emelent.getAttribute('dp_message'),
        globalIndex = emelent.getAttribute('global_index'),
        index = emelent.getAttribute('index'),
        property = emelent.getAttribute('property'),
        totalScore = emelent.getAttribute('total_score'),
        syll = (emelent.findElements('syll') ?? [])
            .map<SyllResult>((item) => SyllResult.fromXml(item))
            .toList(),
        content = emelent.getAttribute('content'),
        endPos = emelent.getAttribute('end_pos'),
        begPos = emelent.getAttribute('beg_pos');

  WordResult.fromJson(Map<String, dynamic> json)
      : dpMessage = json['dp_message'],
        globalIndex = json['global_index'],
        index = json['index'],
        property = json['property'],
        totalScore = json['total_score'],
        syll = (json['syll'] ?? []).map<SyllResult>((item) => SyllResult.fromJson(item)).toList(),
        content = json['content'],
        endPos = json['end_pos'],
        begPos = json['beg_pos'];

  Map<String, dynamic> toJson() => {
        'dp_message': dpMessage,
        'global_index': globalIndex,
        'index': index,
        'property': property,
        'total_score': totalScore,
        'syll': syll,
        'content': content,
        'end_pos': endPos,
        'beg_pos': begPos,
      };
}

class SyllResult {
  String syllScore;
  List<PhoneResult> phone;
  String begPos;
  String content;
  String endPos;
  String syllAccent;

  SyllResult.fromXml(XmlElement emelent)
      : syllScore = emelent.getAttribute('syll_score'),
        phone = (emelent.findElements('phone') ?? [])
            .map<PhoneResult>((item) => PhoneResult.fromXml(item))
            .toList(),
        begPos = emelent.getAttribute('beg_pos'),
        content = emelent.getAttribute('content'),
        endPos = emelent.getAttribute('end_pos'),
        syllAccent = emelent.getAttribute('syll_accent');

  SyllResult.fromJson(Map<String, dynamic> json)
      : syllScore = json['syll_score'],
        phone =
            (json['phone'] ?? []).map<PhoneResult>((item) => PhoneResult.fromJson(item)).toList(),
        begPos = json['beg_pos'],
        content = json['content'],
        endPos = json['end_pos'],
        syllAccent = json['syll_accent'];

  Map<String, dynamic> toJson() => {
        'syll_score': syllScore,
        'phone': phone,
        'beg_pos': begPos,
        'content': content,
        'end_pos': endPos,
        'syll_accent': syllAccent,
      };
}

class PhoneResult {
  String begPos;
  String content;
  String endPos;

  PhoneResult.fromXml(XmlElement emelent)
      : begPos = emelent.getAttribute('beg_pos'),
        content = emelent.getAttribute('content'),
        endPos = emelent.getAttribute('end_pos');

  PhoneResult.fromJson(Map<String, dynamic> json)
      : begPos = json['beg_pos'],
        content = json['content'],
        endPos = json['end_pos'];

  Map<String, dynamic> toJson() => {
        'beg_pos': begPos,
        'content': content,
        'end_pos': endPos,
      };
}

class IseParam {
  String language;
  String category;
  String accent;
  String speechTimeout;
  String resultLevel;
  String aue;
  String audioFormat;
  String iseAudioPath;
  String domain;
  String resultType;
  String timeout;
  String powerCycle;
  String sampleRate;
  String engineType;
  String local;
  String cloud;
  String mix;
  String auto;
  String textEncoding;
  String resultEncoding;
  String playerInit;
  String playerDeactive;
  String recorderInit;
  String recorderDeactive;
  String speed;
  String pitch;
  String ttsAudioPath;
  String vadEnable;
  String vadBos;
  String vadEos;
  String voiceName;
  String voiceId;
  String voiceLang;
  String volume;
  String ttsBufferTime;
  String ttsDataNotify;
  String nextText;
  String mpplayinginfocenter;
  String audioSource;
  String asrAudioPath;
  String asrSch;
  String asrPtt;
  String localGrammar;
  String cloudGrammar;
  String grammarType;
  String grammarContent;
  String lexiconContent;
  String lexiconName;
  String grammarList;
  String nlpVersion;
  String plev;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> param = {
      'language': language,
      'category': category,
      'accent': accent,
      'speech_timeout': speechTimeout,
      'result_level': resultLevel,
      'aue': aue,
      'audio_format': audioFormat,
      'ise_audio_path': iseAudioPath,
      'domain': domain,
      'result_type': resultType,
      'timeout': timeout,
      'power_cycle': powerCycle,
      'sample_rate': sampleRate,
      'engine_type': engineType,
      'local': local,
      'cloud': cloud,
      'mix': mix,
      'auto': auto,
      'text_encoding': textEncoding,
      'result_encoding': resultEncoding,
      'player_init': playerInit,
      'player_deactive': playerDeactive,
      'recorder_init': recorderInit,
      'recorder_deactive': recorderDeactive,
      'speed': speed,
      'pitch': pitch,
      'tts_audio_path': ttsAudioPath,
      'vad_enable': vadEnable,
      'vad_bos': vadBos,
      'vad_eos': vadEos,
      'voice_name': voiceName,
      'voice_id': voiceId,
      'voice_lang': voiceLang,
      'volume': volume,
      'tts_buffer_time': ttsBufferTime,
      'tts_data_notify': ttsDataNotify,
      'next_text': nextText,
      'mpplayinginfocenter': mpplayinginfocenter,
      'audio_source': audioSource,
      'asr_audio_path': asrAudioPath,
      'asr_sch': asrSch,
      'asr_ptt': asrPtt,
      'local_grammar': localGrammar,
      'cloud_grammar': cloudGrammar,
      'grammar_type': grammarType,
      'grammar_content': grammarContent,
      'lexicon_content': lexiconContent,
      'lexicon_name': lexiconName,
      'grammar_list': grammarList,
      'nlp_version': nlpVersion,
      'plev': plev,
    };
    final isNull = (key, value) {
      return value == null;
    };
    param.removeWhere(isNull);
    return param;
  }
}
