import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:agora/config/routes/app_routes.dart';
import 'package:agora/config/routes/customRoutes/hero_dialog_route.dart';
import 'package:agora/core/resources/strings_manager.dart';
import 'package:agora/core/utility/constant.dart';
import 'package:agora/data/models/child_classes/post/post.dart';
import 'package:agora/presentation/pages/profile/users_who_likes_for_mobile.dart';
import 'package:agora/presentation/pages/profile/users_who_likes_for_web.dart';

class CountOfLikes extends StatelessWidget {
  final Post postInfo;
  const CountOfLikes({Key? key, required this.postInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int likes = postInfo.likes.length;

    return InkWell(
      onTap: () {
        if (isThatMobile) {
          Go(context).push(
              page: UsersWhoLikesForMobile(
            showSearchBar: true,
            usersIds: postInfo.likes,
            isThatMyPersonalId: postInfo.publisherId == myPersonalId,
          ));
        } else {
          Navigator.of(context).push(
            HeroDialogRoute(
              builder: (context) => UsersWhoLikesForWeb(
                usersIds: postInfo.likes,
                isThatMyPersonalId: postInfo.publisherId == myPersonalId,
              ),
            ),
          );
        }
      },
      child: Text(
          '$likes ${likes > 1 ? StringsManager.likes.tr : StringsManager.like.tr}',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.displayMedium),
    );
  }
}