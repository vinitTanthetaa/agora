import 'package:agora/controoler.dart';
import 'package:agora/videocallPage.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Chat_Page extends StatefulWidget {
  String userId;
   Chat_Page({super.key,required this.userId});

  @override
  State<Chat_Page> createState() => _Chat_PageState();
}

class _Chat_PageState extends State<Chat_Page> {
  final TextEditingController _text = TextEditingController();
  ScrollController scrollController = ScrollController();
  late RtcEngine agoraEngine;
  ChannelMediaOptions options = const ChannelMediaOptions(clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication);
  int? _remoteUid;
  final List<String> _logText = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _addChatListener();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userId),),
      body: Center(child:
        Column(
          children: [
            TextField(
              controller: _text,
              decoration: const InputDecoration(
                hintText: "Enter message",
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: _sendMessage,
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor: MaterialStateProperty.all(Colors.lightBlue),
                  ),
                  child: const Text("SEND TEXT"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return const Videocall();
                    },));
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor: MaterialStateProperty.all(Colors.lightBlue),
                  ),
                  child: const Text("Video call"),
                ),
              ],
            ),
            Flexible(
              child: ListView.builder(
                controller: scrollController,
                itemBuilder: (_, index) {
                  return Text(_logText[index]);
                },
                itemCount: _logText.length,
              ),
            ),
          ],
        ),),
    );
  }

  Future<void> _addChatListener() async {
   // AgoraRtcEngine.create('YOUR_APP_ID');


    ChatClient.getInstance.chatManager.addEventHandler(
      'UNIQUE_HANDLER_ID',
      ChatEventHandler(onMessagesReceived: onMessagesReceived),
    );

    ChatClient.getInstance.chatManager.addMessageEvent(
      'UNIQUE_HANDLER_ID',
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          _addLogToConsole("send message: ${_text.text} ,${widget.userId},$msgId,$msg");
        },
        onError: (msgId, msg, error) {
          _addLogToConsole(
            "send message failed, code: ${error.code}, desc: ${error.description}",
          );
        },
      ),
    );
  }

  Future<void> setupVideoSDKEngine() async {
    // retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(const RtcEngineContext(
        appId: appid
    ));

    await agoraEngine.enableVideo();

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("Local user uid:${connection.localUid} joined the channel");
        //  showMessage("Local user uid:${connection.localUid} joined the channel");
          setState(() {
           // _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("Remote user uid:$remoteUid joined the channel");
         // showMessage("Remote user uid:$remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print("Remote user uid:$remoteUid left the channel");
         // showMessage("Remote user uid:$remoteUid left the channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (err, msg) {
          print("Remote user uid Error is:$err , $msg left the channel");
         // showMessage("Remote user uid Error is:$err , $msg left the channel");
        },
      ),
    );
  //  join();
  }
  void _sendMessage() async {
    if (widget.userId == null || _text.text == null || _text.text.isEmpty) {
      _addLogToConsole("single chat id or message content is null");
      return;
    }

    var msg = ChatMessage.createTxtSendMessage(
      targetId: widget.userId,
      content: _text.text,
    );

    ChatClient.getInstance.chatManager.sendMessage(msg,callback: (onSuccess, onError, onProgress) {
      MessageStatusCallBack(
        onSuccess: () {
          _addLogToConsole(_text.text);
          _text.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onError: (e) {
          _addLogToConsole(
            "Send message failed, code: ${e.code}, desc: ${e.description}",
          );
        },
      );
    },);
  }
  void onMessagesReceived(List<ChatMessage> messages) {
    for (var msg in messages) {
      print("widget.userId ==> ${widget.userId} --- ${msg.from}");
      if(msg.from == widget.userId.toLowerCase()){
        switch (msg.body.type) {
          case MessageType.TXT:
            {
              ChatTextMessageBody body = msg.body as ChatTextMessageBody;
              _addLogToConsole(
                "receive text message: ${body.content}, from: ${msg.from}",
              );
            }
            break;
          case MessageType.IMAGE:
            {
              _addLogToConsole(
                "receive image message, from: ${msg.from}",
              );
            }
            break;
          case MessageType.VIDEO:
            {
              _addLogToConsole(
                "receive video message, from: ${msg.from}",
              );
            }
            break;
          case MessageType.LOCATION:
            {
              _addLogToConsole(
                "receive location message, from: ${msg.from}",
              );
            }
            break;
          case MessageType.VOICE:
            {
              _addLogToConsole(
                "receive voice message, from: ${msg.from}",
              );
            }
            break;
          case MessageType.FILE:
            {
              _addLogToConsole(
                "receive image message, from: ${msg.from}",
              );
            }
            break;
          case MessageType.CUSTOM:
            {
              _addLogToConsole(
                "receive custom message, from: ${msg.from}",
              );
            }
            break;
          case MessageType.CMD:
            {}
            break;
        }
      }
    }
  }
  void _addLogToConsole(String log) {
    _logText.add(_timeString + ": " + log);
    setState(() {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }
  String get _timeString {
    return DateTime.now().toString().split(".").first;
  }

  }
