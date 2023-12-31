import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora/config/routes/app_routes.dart';
import 'package:agora/core/utility/constant.dart';
import 'package:agora/presentation/cubit/firestoreUserInfoCubit/users_info_reel_time/users_info_reel_time_bloc.dart';
import 'package:agora/presentation/pages/messages/ringing_page.dart';
import 'package:agora/presentation/screens/mobile_screen_layout.dart';

class PopupCalling extends StatefulWidget {
  final String userId;
  final String voice_video;

  const PopupCalling(this.userId, {Key? key,required this.voice_video}) : super(key: key);

  @override
  State<PopupCalling> createState() => _PopupCallingState();
}

class _PopupCallingState extends State<PopupCalling> {
  bool isHeMoved = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersInfoReelTimeBloc, UsersInfoReelTimeState>(
      bloc: UsersInfoReelTimeBloc.get(context)..add(LoadMyPersonalInfo()),
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state is MyPersonalInfoLoaded &&
              !amICalling &&
              state.myPersonalInfoInReelTime.channelId.isNotEmpty) {
            if (!isHeMoved) {
              isHeMoved = true;
              Go(context).push(
                  page: CallingRingingPage(
                      channelId: state.myPersonalInfoInReelTime.channelId,
                      clearMoving: clearMoving, voiceORvideo: widget.voice_video,),
                  withoutRoot: false);
            }
          }
        });
        return MobileScreenLayout(widget.userId);
      },
    );
  }

  clearMoving() {
    isHeMoved = false;
  }
}
