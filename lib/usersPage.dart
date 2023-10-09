import 'package:agora/chat_page.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List Users = ['User1','User2','User3'];
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(),
      body: Center(child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: Users.length,
              itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(Users[index]),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return  Chat_Page(userId: Users[index],);
                  },));
                },
              );
            },),
          )
        ],
      )),
    );
  }
}
