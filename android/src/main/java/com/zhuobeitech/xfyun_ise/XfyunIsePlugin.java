package com.zhuobeitech.xfyun_ise;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.os.Environment;
import android.text.TextUtils;
import android.util.Log;

import com.iflytek.cloud.ErrorCode;
import com.iflytek.cloud.EvaluatorListener;
import com.iflytek.cloud.EvaluatorResult;
import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.Setting;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechEvaluator;
import com.iflytek.cloud.SpeechUtility;

import java.io.ByteArrayOutputStream;
import java.io.File;

import java.io.FileInputStream;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** XfyunIsePlugin */
public class XfyunIsePlugin implements MethodCallHandler {
  private static String TAG = XfyunIsePlugin.class.getSimpleName();
  private MethodChannel channel;
  private Context applicationContext;
  private SpeechEvaluator evaluator;

  private XfyunIsePlugin(MethodChannel channel, Activity activity) {
    this.channel = channel;
    this.applicationContext = activity.getApplicationContext();
    // this.activity = activity;
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.zhuobeitech/xfyun_ise");
    channel.setMethodCallHandler(new XfyunIsePlugin(channel, registrar.activity()));
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("init")) {
      init(call, result);
    } else if (call.method.equals("setParameter")) {
      setParameter(call, result);
    } else if (call.method.equals("start")) {
      start(call, result);
    } else if (call.method.equals("writeAudio")) {
      writeAudio(call, result);
    } else if (call.method.equals("stop")) {
      stop(call, result);
    } else if (call.method.equals("cancel")) {
      cancel(call, result);
    } else if (call.method.equals("dispose")) {
      dispose(call, result);
    } else if (call.method.equals("isEvaluating")) {
      isEvaluating(call, result);
    } else {
      result.notImplemented();
    }
  }

  private EvaluatorListener mEvaluatorListener = new EvaluatorListener() {
    @Override
    public void onBeginOfSpeech() {
      Log.d(TAG, "onBeginOfSpeech()");

      channel.invokeMethod("onBeginOfSpeech", null);
    }

    @Override
    public void onError(SpeechError error) {
      Log.d(TAG, "onError():" + error.getPlainDescription(true));

      Map arguments = new HashMap();
      arguments.put("code", error.getErrorCode());
      arguments.put("desc", error.getErrorDescription());
      channel.invokeMethod("onError", arguments);
    }

    @Override
    public void onEndOfSpeech() {
      Log.d(TAG, "onEndOfSpeech()");

      channel.invokeMethod("onEndOfSpeech", null);
    }

    @Override
    public void onResult(EvaluatorResult results, boolean isLast) {
      Log.d(TAG, "onResult():" + results.getResultString());

      if (isLast) {
        channel.invokeMethod("onResult", results.getResultString());
      }
    }

    @Override
    public void onVolumeChanged(int volume, byte[] data) {
      channel.invokeMethod("onVolumeChanged", volume);
    }

    @Override
    public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {
      // 以下代码用于获取与云端的会话id，当业务出错时将会话id提供给技术支持人员，可用于查询会话日志，定位出错原因
      // 若使用本地能力，会话id为null
      // if (SpeechEvent.EVENT_SESSION_ID == eventType) {
      // String sid = obj.getString(SpeechEvent.KEY_EVENT_SESSION_ID);
      // Log.d(TAG, "session id =" + sid);
      // }
    }
  };

  /**
   * 初始化
   */
  private void init(MethodCall call, Result result) {
    // getPermisson();

    SpeechUtility.createUtility(applicationContext, SpeechConstant.APPID + "=" + call.arguments);
    Setting.setLocationEnable(false);// 关闭定位
    evaluator = SpeechEvaluator.createEvaluator(applicationContext, new InitListener() {
      @Override
      public void onInit(int code) {
        if (code != ErrorCode.SUCCESS) {
          Log.e(TAG, "创建evaluator失败，错误码：" + code);
        }
      }
    });

    result.success(null);
  }

  /**
   * 设置参数
   */
  private void setParameter(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "evaluator is null");
    } else {
      try {
        Map<String, String> map = (Map<String, String>) call.arguments;
        for (Map.Entry<String, String> entry : map.entrySet()) {
          evaluator.setParameter(entry.getKey(), entry.getValue());
        }
      } catch (Exception e) {
        e.printStackTrace();
      }
    }

    result.success(null);
  }

  /**
   * 开始评测
   */
  private void start(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "evaluator is null");
    } else {
      String text = call.argument("text");
      int ret = evaluator.startEvaluating(text, null, mEvaluatorListener);
      if (ret != ErrorCode.SUCCESS) {
        Log.e(TAG, "evaluation failed, err code：" + ret);
        result.error("Unexpected error!", "err code:" + ret, null);
        return;
      }
    }
    result.success(null);
  }

  /**
   * 写入录音数据 通过调用此函数，把音频数据传给SDK
   */
  private void writeAudio(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "evaluator is null");
    } else {
      byte[] data = call.argument("data");
      boolean ret = evaluator.writeAudio(data, 0, data.length);
      if (!ret) {
        Log.e(TAG, "Write audio failed");
        result.error("Write audio error!", null, null);
        return;
      }
    }
    result.success(null);
  }

  /**
   * 写入录音数据 通过调用此函数，把音频数据传给SDK
   */
  private void isEvaluating(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "evaluator is null");
      result.success(false);
      return;
    }
    boolean ret = evaluator.isEvaluating();
    result.success(ret);
  }

  /**
   * 停止评测
   */
  private void stop(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "evaluator is null");
    } else {
      evaluator.stopEvaluating();
    }
    result.success(null);
  }

  /**
   * 取消评测
   */
  private void cancel(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "evaluator is null");
    } else {
      evaluator.cancel();
    }

    result.success(null);
  }

  /**
   * 释放资源
   */
  private void dispose(MethodCall call, Result result) {
    if (evaluator == null) {
      Log.e(TAG, "recongnizer为null");
    } else {
      evaluator.cancel();// 取消当前会话
      evaluator.destroy();// 销毁evaluator单例
      evaluator = null;
    }

    result.success(null);
  }
}
