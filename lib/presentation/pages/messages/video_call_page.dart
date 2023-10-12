import 'dart:core';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import 'package:agora/core/resources/color_manager.dart';
import 'package:agora/core/resources/styles_manager.dart';
import 'package:agora/core/utility/constant.dart';
import 'package:agora/core/utility/private_keys.dart';
import 'package:agora/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import 'package:agora/presentation/cubit/callingRooms/calling_rooms_cubit.dart';
import 'package:agora/presentation/cubit/firestoreUserInfoCubit/user_info_cubit.dart';
import 'package:agora/presentation/widgets/global/circle_avatar_image/circle_avatar_of_profile_image.dart';
import 'package:permission_handler/permission_handler.dart';

enum UserCallingType { sender, receiver }

class CallPage extends StatefulWidget {
  final String channelName;
  final String userCallingId;

  final List<UserPersonalInfo>? usersInfo;
  final UserCallingType userCallingType;
  final ClientRoleType role;

  const CallPage({
    Key? key,
    required this.channelName,
    this.userCallingId = "",
    required this.userCallingType,
    required this.role,
    this.usersInfo,
  }) : super(key: key);

  @override
  CallPageState createState() => CallPageState();
}

class CallPageState extends State<CallPage> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
    setState(() {});
  }
  Future<void> initAgora() async {
    setState(() {});
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    setState(() {});
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    setState(() {});
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );
      setState(() {});
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.enableAudio();
    await _engine.startPreview();
    setState(() {});
    await _engine.joinChannel(
      token: CHANNEL_TOKEN,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
    setState(() {});
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _engine.leaveChannel();
    _engine.release();
    setState(() {});
  }
  bool muted = false;
  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
           Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  void _onSwitchCamera() {
    _engine.switchCamera();
  }
  void _onCallEnd(BuildContext context) {
    setState(() => amICalling = false);
    _engine.leaveChannel();
    _engine.release();
    setState(() {});
    Navigator.of(context).maybePop();
  }
  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }
  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
  // final _users = <int>[];
  // final _infoStrings = <String>[];
  // bool muted = false;
  // bool moreThanOne = false;
  //
  // late RtcEngine _engine;
  // late UserPersonalInfo myPersonalInfo;
  // @override
  // void dispose() {
  //   _users.clear();
  //   _dispose();
  //   super.dispose();
  // }
  //
  // Future<void> _dispose() async {
  //   await _engine.leaveChannel();
  //   await _engine.destroy();
  // }
  //
  // @override
  // void initState() {
  //   super.initState();
  //   myPersonalInfo = UserInfoCubit.getMyPersonalInfo(context);
  //   WidgetsBinding.instance.addPostFrameCallback((_) async => await onJoin());
  //
  //   initialize();
  // }
  //
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   WidgetsBinding.instance.addPostFrameCallback((_) async => await onJoin());
  // }
  //
  // Future<void> onJoin() async {
  //   await _handleCameraAndMic(Permission.camera);
  //   await _handleCameraAndMic(Permission.microphone);
  // }
  //
  // Future<void> _handleCameraAndMic(Permission permission) async =>
  //     await permission.request();
  //
  // /// Create your own app id with agora with "testing mode"
  // /// it's very simple, just go to https://www.agora.io/en/ and create your own project and get your own app id in [agoraAppId]
  // /// Again, don't make it with secure mode ,You will lose the creation of several channels.
  // /// Make it with "testing mode"
  // Future<void> initialize() async {
  //   if (agoraAppId.isEmpty) {
  //     setState(() {
  //       _infoStrings.add(
  //         'APP_ID missing, please provide your APP_ID in settings.dart',
  //       );
  //       _infoStrings.add('Agora Engine is not starting');
  //     });
  //     return;
  //   }
  //
  //   await _initAgoraRtcEngine();
  //   _addAgoraEventHandlers();
  //   VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
  //   configuration.dimensions = const VideoDimensions(width: 1920, height: 1080);
  //   await _engine.setVideoEncoderConfiguration(configuration);
  //   await _engine.joinChannel(null, widget.channelName, null, 0);
  // }
  //
  // /// Create agora sdk instance and initialize
  // Future<void> _initAgoraRtcEngine() async {
  //   _engine = await RtcEngine.create(agoraAppId);
  //   await _engine.enableVideo();
  //   await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
  //   await _engine.setClientRole(widget.role);
  // }
  //
  // /// Add agora event handlers
  // void _addAgoraEventHandlers() {
  //   _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
  //     setState(() {
  //       final info = 'onError: $code';
  //       _infoStrings.add(info);
  //     });
  //   }, joinChannelSuccess: (channel, uid, elapsed) {
  //     setState(() {
  //       final info = 'onJoinChannel: $channel, uid: $uid';
  //       _infoStrings.add(info);
  //     });
  //   }, leaveChannel: (stats) {
  //     setState(() {
  //       _infoStrings.add('onLeaveChannel');
  //       _users.clear();
  //     });
  //   }, userJoined: (uid, elapsed) {
  //     setState(() {
  //       final info = 'userJoined: $uid';
  //       _infoStrings.add(info);
  //       _users.add(uid);
  //     });
  //   }, userOffline: (uid, elapsed) {
  //     setState(() {
  //       final info = 'userOffline: $uid';
  //       _infoStrings.add(info);
  //       _users.remove(uid);
  //     });
  //   }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
  //     setState(() {
  //       final info = 'firstRemoteVideo: $uid ${width}x $height';
  //       _infoStrings.add(info);
  //     });
  //   }));
  // }
  //
  // /// Helper function to get list of native views
  // List<Widget> _getRenderViews() {
  //   final List<StatefulWidget> list = [];
  //   if (widget.role == ClientRole.Broadcaster) {
  //     list.add(const rtc_local_view.SurfaceView());
  //   }
  //   for (var uid in _users) {
  //     list.add(
  //         rtc_remote_view.SurfaceView(channelId: widget.channelName, uid: uid));
  //   }
  //   return list;
  // }
  //
  // /// Video view wrapper
  // Widget _videoView(view) {
  //   return Expanded(child: Container(child: view));
  // }
  //
  // /// Video view row wrapper
  // Widget _expandedVideoRow(List<Widget> views) {
  //   final wrappedViews = views.map<Widget>(_videoView).toList();
  //   return Expanded(
  //     child: Row(children: wrappedViews),
  //   );
  // }
  //
  // /// Video layout wrapper
  // Widget _viewRows() {
  //   final views = _getRenderViews();
  //   if (views.length > 1) {
  //     WidgetsBinding.instance
  //         .addPostFrameCallback((_) => setState(() => moreThanOne = true));
  //   }
  //   if (widget.userCallingType == UserCallingType.receiver &&
  //       views.length == 1 &&
  //       moreThanOne) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) async {
  //       await CallingRoomsCubit.get(context)
  //           .deleteTheRoom(channelId: widget.channelName);
  //       setState(() => amICalling = false);
  //     });
  //     Navigator.of(context).maybePop();
  //   }
  //
  //   switch (views.length) {
  //     case 1:
  //       return Column(
  //         children: <Widget>[_videoView(views[0])],
  //       );
  //     case 2:
  //       return Column(
  //         children: <Widget>[
  //           _expandedVideoRow([views[0]]),
  //           _expandedVideoRow([views[1]])
  //         ],
  //       );
  //     case 3:
  //       return Column(
  //         children: <Widget>[
  //           _expandedVideoRow(views.sublist(0, 2)),
  //           _expandedVideoRow(views.sublist(2, 3))
  //         ],
  //       );
  //     case 4:
  //       return Column(
  //         children: <Widget>[
  //           _expandedVideoRow(views.sublist(0, 2)),
  //           _expandedVideoRow(views.sublist(2, 4))
  //         ],
  //       );
  //     default:
  //   }
  //   return const SizedBox();
  // }
  //
  // /// Toolbar layout
  // Widget _toolbar() {
  //   if (widget.role == ClientRole.Audience) return Container();
  //   return Container(
  //     alignment: Alignment.bottomCenter,
  //     padding: const EdgeInsets.symmetric(vertical: 48),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: <Widget>[
  //         RawMaterialButton(
  //           onPressed: _onToggleMute,
  //           shape: const CircleBorder(),
  //           elevation: 2.0,
  //           fillColor: muted ? Colors.blueAccent : Colors.white,
  //           padding: const EdgeInsets.all(12.0),
  //           child: Icon(
  //             muted ? Icons.mic_off : Icons.mic,
  //             color: muted ? Colors.white : Colors.blueAccent,
  //             size: 20.0,
  //           ),
  //         ),
  //         RawMaterialButton(
  //           onPressed: () => _onCallEnd(context),
  //           shape: const CircleBorder(),
  //           elevation: 2.0,
  //           fillColor: Colors.redAccent,
  //           padding: const EdgeInsets.all(15.0),
  //           child: const Icon(
  //             Icons.call_end,
  //             color: Colors.white,
  //             size: 35.0,
  //           ),
  //         ),
  //         RawMaterialButton(
  //           onPressed: _onSwitchCamera,
  //           shape: const CircleBorder(),
  //           elevation: 2.0,
  //           fillColor: Colors.white,
  //           padding: const EdgeInsets.all(12.0),
  //           child: const Icon(
  //             Icons.switch_camera,
  //             color: Colors.blueAccent,
  //             size: 20.0,
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }
  //
  // void _onCallEnd(BuildContext context) {
  //   setState(() => amICalling = false);
  //   CallingRoomsCubit.get(context).leaveTheRoom(
  //     userId: myPersonalInfo.userId,
  //     channelId: widget.channelName,
  //     isThatAfterJoining: true,
  //   );
  //   Navigator.of(context).maybePop();
  // }
  //
  // void _onToggleMute() {
  //   setState(() {
  //     muted = !muted;
  //   });
  //   _engine.muteLocalAudioStream(muted);
  // }
  //

  //
  // @override
  // // Widget build(BuildContext context) {
  // //   return Scaffold(
  // //     appBar: AppBar(
  // //       title: const Text('Agora Video Call'),
  // //     ),
  // //     body: Stack(
  // //       children: [
  // //         Center(
  // //           child: _remoteVideo(),
  // //         ),
  // //         Align(
  // //           alignment: Alignment.bottomCenter,
  // //           child: InkWell(
  // //               onTap: () {
  // //                 _engine.leaveChannel();
  // //               },
  // //               child: const CircleAvatar(backgroundColor: Colors.red,child: Icon(Icons.phone_disabled_outlined))),
  // //         ),
  // //         Align(
  // //           alignment: Alignment.topLeft,
  // //           child: SizedBox(
  // //             width: 100,
  // //             height: 150,
  // //             child: Center(
  // //               child: _localUserJoined
  // //                   ? AgoraVideoView(
  // //                 controller: VideoViewController(
  // //                   rtcEngine: _engine,
  // //                   canvas: const VideoCanvas(uid: 0),
  // //                 ),
  // //               )
  // //                   : const CircularProgressIndicator(),
  // //             ),
  // //           ),
  // //         ),
  // //       ],
  // //     ),
  // //   );
  // // }
  // //
  // // // Display remote user's video
  // // Widget _remoteVideo() {
  // //   if (_remoteUid != null) {
  // //     return AgoraVideoView(
  // //       controller: VideoViewController.remote(
  // //         rtcEngine: _engine,
  // //         canvas: VideoCanvas(uid: _remoteUid),
  // //         connection: const RtcConnection(channelId: channel),
  // //       ),
  // //     );
  // //   } else {
  // //     return const Text(
  // //       'Please wait for remote user to join',
  // //       textAlign: TextAlign.center,
  // //     );
  // //   }
  // // }
  //
  // Widget build(BuildContext context) {
  //   final views = _getRenderViews();
  //   final int? numOfUsers = widget.usersInfo?.length;
  //   return Material(
  //     child: Center(
  //       child: Stack(
  //         alignment: Alignment.center,
  //         children: <Widget>[
  //            _viewRows(),
  //           if (views.length == 1) ...[
  //             Positioned(
  //               top: 30,
  //               child: SizedBox(
  //                 width: MediaQuery.of(context).size.width,
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   children: [
  //                     const SizedBox(width: 10),
  //                     const Icon(Icons.video_camera_back_rounded,
  //                         color: ColorManager.white, size: 33),
  //                     const SizedBox(width: 10),
  //                     GestureDetector(
  //                       onTap: _onToggleMute,
  //                       child: Icon(
  //                         muted
  //                             ? Icons.mic_off_rounded
  //                             : Icons.mic_none_rounded,
  //                         color: Colors.white,
  //                         size: 33.0,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 10),
  //                     const Icon(Icons.volume_up_rounded,
  //                         color: ColorManager.white, size: 33),
  //                     const SizedBox(width: 10),
  //                     GestureDetector(
  //                       onTap: () => _onCallEnd(context),
  //                       child: const Icon(Icons.close_rounded,
  //                           color: ColorManager.white, size: 33),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             Positioned(
  //               top: 130,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   if (widget.usersInfo != null) ...[
  //                     if (numOfUsers == 1) ...[
  //                       buildCircleAvatar(0, 1000),
  //                     ] else if (numOfUsers != 0) ...[
  //                       Align(
  //                         alignment: Alignment.bottomRight,
  //                         child: buildCircleAvatar(0, 700),
  //                       ),
  //                       Positioned(
  //                           height: -15,
  //                           left: -10,
  //                           child: buildCircleAvatar(1, 700)),
  //                     ],
  //                     const SizedBox(height: 30),
  //                     ...List.generate(numOfUsers!, (index) {
  //                       return Text(widget.usersInfo![index].name,
  //                           style: getNormalStyle(
  //                               color: ColorManager.white, fontSize: 25));
  //                     }),
  //                   ],
  //                   const SizedBox(height: 10),
  //                   Text('Connecting...',
  //                       style: getNormalStyle(
  //                           color: ColorManager.white, fontSize: 16.5)),
  //                 ],
  //               ),
  //             ),
  //           ] else ...[
  //             _toolbar(),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget buildCircleAvatar(int index, double bodyHeight) {
  //   return CircleAvatarOfProfileImage(
  //     bodyHeight: bodyHeight,
  //     userInfo: widget.usersInfo![index],
  //     disablePressed: true,
  //     showColorfulCircle: false,
  //   );
  // }
}
