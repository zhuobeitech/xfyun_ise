# xfyun_ise

科大讯飞语音测评插件
A plugin for xunfei dictation for iOS and Android.

## Install

First, add xfyun_ise as a dependency in your pubspec.yaml file.

## Setting

Set privacy on iOS in Info.plist

```
<key>NSMicrophoneUsageDescription</key>
<string></string>
<key>NSLocationUsageDescription</key>
<string></string>
<key>NSLocationAlwaysUsageDescription</key>
<string></string>
<key>NSContactsUsageDescription</key>
<string></string>
```

Set privacy on Android in AndroidManifest.xml

```
<!--连接网络权限，用于执行云端语音能力 -->
<uses-permission android:name="android.permission.INTERNET"/>
<!--获取手机录音机使用权限，听写、识别、语义理解需要用到此权限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<!--读取网络信息状态 -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<!--获取当前wifi状态 -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<!--允许程序改变网络连接状态 -->
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
<!--读取手机信息权限 -->
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<!--读取联系人权限，上传联系人需要用到此权限 -->
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<!--外存储写权限，构建语法需要用到此权限 -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<!--外存储读权限，构建语法需要用到此权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<!--配置权限，用来记录应用配置信息 -->
<uses-permission android:name="android.permission.WRITE_SETTINGS"/>
<!--手机定位信息，用来为语义等功能提供定位，提供更精准的服务-->
<!--定位信息是敏感信息，可通过Setting.setLocationEnable(false)关闭定位请求 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<!--如需使用人脸识别，还要添加：摄相头权限，拍照需要用到 -->
<uses-permission android:name="android.permission.CAMERA" />
```

## Usage

- Init the plugin. Use the appId you register on https://www.xfyun.cn/

```
final voice = XFVoice.shared;
voice.init(appIdIos: 'the app id for ios', appIdAndroid: 'the app id for android');
```

- Set the parameter.

```
    // 请替换成你的appid
    XfyunIse.init(appId: '1wq12ds');

```

## 方法概要

| 限定符和类型           | 字段和说明                                                                                                                               |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| void                   | cancel() 取消会话 通过此函数取消当前的会话。                                                                                             |
| static SpeechEvaluator | createEvaluator(android.content.Context context, InitListener listener) 创建单例对象 使用此函数创建一个本类单例对象。                    |
| boolean                | destroy() 销毁单例对象 通过本函数，销毁由 createEvaluator(android.content.Context, com.iflytek.cloud.InitListener)创建的单例对象。       |
| static SpeechEvaluator | getEvaluator() 获取单例对象 通过函数获取已创建的单例对象。                                                                               |
| java.lang.String       | getParameter(java.lang.String key) 获取参数 获取指定的参数的当前值。                                                                     |
| boolean                | isEvaluating() 是否在会话中 通过此函数，获取当前 SDK 是否正在进行会话。                                                                  |
| boolean                | setParameter(java.lang.String key, java.lang.String value) 设置参数 设置评测会话参数。                                                   |
| int                    | startEvaluating(byte[] text, java.lang.String textParams, EvaluatorListener listener) 开始评测 传入 byte[]类型的评测文本，开始评测会话。 |
| int                    | startEvaluating(java.lang.String text, java.lang.String textParams, EvaluatorListener listener) 开始评测 调用此函数，开始评测。          |
| void                   | stopEvaluating() 停止录音 调用本函数告知 SDK，当前会话音频已全部录入。                                                                   |
| boolean                | writeAudio(byte[] buffer, int offset, int length) 写入录音数据 通过调用此函数，把音频数据传给 SDK。                                      |

## Important

The binary downloaded from xunfei is bind with you appid.
So, when you use this plugin, you should replace the binary in both Android and iOS project.
