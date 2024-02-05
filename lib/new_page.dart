const jwt = require("jsonwebtoken");
const { users } = require('../../app/models/user.model')
const { Room, Chat } = require('../../app/models/chat.model')
const mongoose = require("mongoose")
const moment = require("moment");
function chatRoom(io) {
try {
async function verifySocketToken(socket, next) {
try {

const id = socket.handshake.query.userName
console.log("🚀 ~ file: verifySocketToken ~ id ", id)

if (mongoose.isValidObjectId(id)) {

const user = await users.findById(id, { _id: 1, firstname: 1, lastname: 1 })
if (user) {
socket.user = user
next()
}

} else {
console.log("Invalid Id");
}
} catch (err) {
console.log(err)
}
}

io.use((socket, next) => {
verifySocketToken(socket, next)
})

// connection + communication
io.on('connection', async socket => {
// console.log("c_" + socket.id + " uid " + socket.user.firstname)

// socket.on('disconnect', () => {
//     console.log("d_" + socket.id + " uid " + socket.user.firstname)
// })

socket.join(socket.user._id.toString())

//send userinfo
console.log("🚀 ~ file: chat.js:50 ~ chatRoom ~ socket.user:", socket.user)
io.to(socket.user._id.toString()).emit("userinfo", socket.user)

let room = await Room.aggregate([
{
$match: {
$or: [
{ user1: mongoose.Types.ObjectId(socket.user._id) },
{ user2: mongoose.Types.ObjectId(socket.user._id) }
]
},
},
{
$lookup: {
from: "users",
localField: "user1",
foreignField: "_id",
as: "user1",
},
},
{ $unwind: "$user1" },
{
$lookup: {
from: "users",
localField: "user2",
foreignField: "_id",
as: "user2",
},
}, { $unwind: "$user2" },

{
$sort: { updatedAt: -1 }
},

{
$project: {
"roomid": 1, "newMessage1": 1, "newMessage2": 1, "user1": { _id: 1, username: 1 }, "user2": { _id: 1, username: 1 }
}
},

])

// console.log(room, "------------------>room")

const roomIdarray = room.map(one => {
return one.roomid
})
// console.log(roomIdarray[0], "------------------>roomIdarray")


if (room.length) {
socket.join(roomIdarray)
console.log("🚀 ~ file: chat.js:99 ~ chatRoom ~ roomIdarray[0]", roomIdarray[0])
io.to(socket.user._id.toString()).emit('rooms', roomIdarray[0])
// io.to(socket.user._id.toString()).emit('rooms', { room: room })
} else {
io.to(socket.user._id).emit('rooms', { room: "" })
}



socket.on('sendMessage', async message => {
console.log("<<------------------sendMessage-------------------->>", message);

// ------------------------------------------------------------------------------------------------------- II

let roomid = socket.user._id + message.to
console.log("🚀 ~ socket.user._id + message.to:", socket.user._id + message.to)
console.log("🚀 ~ file: chat.js:114 ~ chatRoom ~ roomid:", roomid)
const result = await Room.findOne({ roomid })
console.log("🚀 ~ file: chat.js:110 ~ chatRoom ~ result", result)
if (result) {
console.log("+++++++++++++++++++++++++++++++++got room id+++++++++++++++++++++++++++++++++")
if (result.user1 == socket.user._id.toString()) {
await Room.findByIdAndUpdate(result._id, { newMessage2: result.newMessage2 + 1 })
} else {
await Room.findByIdAndUpdate(result._id, { newMessage1: result.newMessage1 + 1 })
}

const currentMoment = moment(Date.now()).format("hh:mm A")
let newMsg = await new Chat({
roomid,
to: message.to,
from: message.from,
message: message.message,
time : currentMoment

}).save()
newMsg = { ...newMsg._doc, sender: socket.user.userName }
// console.log("🚀 ~ file: chat.js:122 ~ chatRoom ~ newMsg", newMsg)
// newMsg["sender"] = socket.user.username
await refreshRoom(socket.user._id.toString())
await refreshRoom(message.to)
const result_ = await Chat.find({
$or: [
{ roomid: message.to + message.from },
{ roomid: message.from + message.to }
]
})
console.log("🚀 ~ file: chat.js:132 ~ chatRoom ~ result_", result_)
io.to(socket.user._id.toString()).emit('data', result_) //data

io.to(roomid).emit('recieveMessage', newMsg)//

} else {
console.log("+++++++++++++++++++++++++++++++++did not get room id+++++++++++++++++++++++++++++++++")
console.log("🚀 ~ message.to + socket.user._id:", message.to + socket.user._id)

const result = await Room.findOne({ roomid: message.to + socket.user._id })

if (!result) {
console.log("room not found")
console.log("🚀 ~  ~ chatRoom ~ roooom id generate ~ ~ ~ ~ ")
console.log("🚀 ~  ~ chatRoom ~ socket.user._id", socket.user._id)
console.log("🚀 ~  ~ chatRoom ~ message.to", message.to)
const result = await new Room({
roomid: socket.user._id + message.to,
user1: socket.user._id,
user2: message.to,
newMessage2: 1
}).save()
const currentMoment = moment(Date.now()).format("hh:mm A")

const newMsg = await Chat({
to: message.to,
from: socket.user._id,
message: message.message,
roomid: result.roomid,
time : currentMoment

}).save()

const room = await Room.aggregate([
{
$match: {
_id: result._id
},
},
{
$lookup: {
from: "users",
localField: "user1",
foreignField: "_id",
as: "user1",
},
},
{ $unwind: "$user1" },
{
$lookup: {
from: "users",
localField: "user2",
foreignField: "_id",
as: "user2",
},
}, { $unwind: "$user2" },
{
$project: {
"roomid": 1, "newMessage1": 1, "newMessage2": 1, "user1": { _id: 1, username: 1 }, "user2": { _id: 1, username: 1 }
}
}
])
// console.log(room[0], "-------------------------------room[0]")
socket.join(result.roomid)
// console.log("🚀 ~ file: chat.js:183 ~ chatRoom ~ newMsg", newMsg)
const result_ = await Chat.find({
$or: [
{ roomid: message.to + message.from },
{ roomid: message.from + message.to }
]
})
console.log("🚀 ~ file: chat.js:132 ~ chatRoom ~ result_", result_)
io.to(socket.user._id.toString()).emit('data', result_)


io.to(result.roomid).emit('recieveMessage', newMsg)
io.to(socket.user._id.toString()).emit('addThisRoom', room[0])
io.to(message.to).emit('addThisRoom', room[0])

} else {

// console.log("room found")
if (result.user1 == socket.user._id.toString()) {
await Room.findByIdAndUpdate(result._id, { newMessage2: result.newMessage2 + 1 })
} else {
await Room.findByIdAndUpdate(result._id, { newMessage1: result.newMessage1 + 1 })
}
const currentMoment = moment(Date.now()).format("hh:mm A")
let newMsg = await new Chat({
roomid: result.roomid,
to: message.to,
from: message.from,
message: message.message,
time : currentMoment

}).save()
newMsg = { ...newMsg._doc, sender: socket.user.userName }
await refreshRoom(socket.user._id.toString())
await refreshRoom(message.to)
const result_ = await Chat.find({
$or: [
{ roomid: message.to + message.from },
{ roomid: message.from + message.to }
]
})
console.log("🚀 ~ file: chat.js:132 ~ chatRoom ~ result_", result_)
io.to(socket.user._id.toString()).emit('data', result_)

// console.log("🚀 ~ file: chat.js:205 ~ chatRoom ~ newMsg", newMsg)
io.to(result.roomid).emit('recieveMessage', newMsg)//

}
}


// ------------------------------------------------------------------------------------------------------- II


// ------------------------------------------------------------------------------------------------------- I
// create room id
// let roomid = socket.user._id + message.to
// console.log("🚀 ~ file: chat.js:112 ~ chatRoom ~ roomid:", roomid)

// // check if the roomid exist and update in it itself
// const findRoom = await Room.findOne({ roomid })
// console.log("🚀 ~ file: chat.js:116 ~ chatRoom ~ findRoom:", findRoom)

// if(findRoom){
//     console.log("------------------------------findroom-----------------------------------------");
//     if(findRoom.user1 == socket.user._id.toString()){
//         await Room.findByIdAndUpdate(findRoom._id, { newMessage2: findRoom.newMessage2 + 1 })
//     } else {
//         await Room.findByIdAndUpdate(findRoom._id, { newMessage1: findRoom.newMessage1 + 1 })
//     }

//     // save chat
//     let newMsg = await new Chat({ roomid, to: message.to, from: message.from, message: message.message }).save()
//     newMsg = { ...newMsg._doc, sender: socket.user.userName }

//     await refreshRoom(socket.user._id.toString())
//     await refreshRoom(message.to)
//     const result_ = await Chat.find({
//         $or: [
//             { roomid: message.to + message.from },
//             { roomid: message.from + message.to }
//         ]
//     })
//     console.log("🚀 ~ file: chat.js:142 ~ chatRoom ~ result_:", result_)

//     io.to(socket.user._id.toString()).emit('data', result_ )
//     io.to(message.roomid).emit('recieveMessage', newMsg)
// } else {
//     console.log("------------------------------else part-----------------------------------------");

//     const result = await new Room({ roomid: socket.user._id + message.to, user1: socket.user._id, user2: message.to, newMessage2: 1 }).save()

//     const newMsg = await Chat({ to: message.to, from: socket.user._id, message: message.message, roomid: result.roomid }).save()

//     socket.join(result.roomid)

//     const result_ = await Chat.find({
//         $or: [
//             { roomid: message.to + message.from },
//             { roomid: message.from + message.to }
//         ]
//     })
//     console.log("🚀 ~ file: chat.js:159 ~ chatRoom ~ result_:", result_)
//     io.to(socket.user._id.toString()).emit('data', result_ )
//     io.to(result.roomid).emit('recieveMessage', newMsg)
// }



// ------------------------------------------------------------------------------------------------------- I


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// if (message.roomid) {
//     console.log("+++++++++++++++++++++++++++++++++got room id+++++++++++++++++++++++++++++++++")
//     const result = await Room.findOne({ roomid: message.roomid })
//     console.log("🚀 ~ file: chat.js:110 ~ chatRoom ~ result", result)
//     if (result.user1 == socket.user._id.toString()) {
//         await Room.findByIdAndUpdate(result._id, { newMessage2: result.newMessage2 + 1 })
//     } else {
//         await Room.findByIdAndUpdate(result._id, { newMessage1: result.newMessage1 + 1 })
//     }

//     let newMsg = await new Chat({
//         roomid: message.roomid,
//         to: message.to,
//         from: message.from,
//         message: message.message

//     }).save()
//     newMsg = { ...newMsg._doc, sender: socket.user.userName }
//     // console.log("🚀 ~ file: chat.js:122 ~ chatRoom ~ newMsg", newMsg)
//     // newMsg["sender"] = socket.user.username
//     await refreshRoom(socket.user._id.toString())
//     await refreshRoom(message.to)
//     const result_ = await Chat.find({
//         $or: [
//             { roomid: message.to + message.from },
//             { roomid: message.from + message.to }
//         ]
//     })
//     console.log("🚀 ~ file: chat.js:132 ~ chatRoom ~ result_", result_)
//     io.to(socket.user._id.toString()).emit('data', result_ ) //data

//     io.to(message.roomid).emit('recieveMessage', newMsg)//

// } else {
//     console.log("+++++++++++++++++++++++++++++++++did not get room id+++++++++++++++++++++++++++++++++")
//     const result = await Room.findOne({

//         $or: [
//             { roomid: message.to + socket.user._id },
//             { roomid: socket.user._id + message.to }
//         ]

//     })
//     if (!result) {
//         console.log("room not found")
//         console.log("🚀 ~  ~ chatRoom ~ roooom id generate ~ ~ ~ ~ ")
//         console.log("🚀 ~  ~ chatRoom ~ socket.user._id", socket.user._id)
//         console.log("🚀 ~  ~ chatRoom ~ message.to", message.to)
//         const result = await new Room({
//             roomid: socket.user._id + message.to,
//             user1: socket.user._id,
//             user2: message.to,
//             newMessage2: 1
//         }).save()

//         const newMsg = await Chat({
//             to: message.to,
//             from: socket.user._id,
//             message: message.message,
//             roomid: result.roomid
//         }).save()

//         const room = await Room.aggregate([
//             {
//                 $match: {
//                     _id: result._id
//                 },
//             },
//             {
//                 $lookup: {
//                     from: "users",
//                     localField: "user1",
//                     foreignField: "_id",
//                     as: "user1",
//                 },
//             },
//             { $unwind: "$user1" },
//             {
//                 $lookup: {
//                     from: "users",
//                     localField: "user2",
//                     foreignField: "_id",
//                     as: "user2",
//                 },
//             }, { $unwind: "$user2" },
//             {
//                 $project: {
//                     "roomid": 1, "newMessage1": 1, "newMessage2": 1, "user1": { _id: 1, username: 1 }, "user2": { _id: 1, username: 1 }
//                 }
//             }
//         ])
//         // console.log(room[0], "-------------------------------room[0]")
//         socket.join(result.roomid)
//         // console.log("🚀 ~ file: chat.js:183 ~ chatRoom ~ newMsg", newMsg)
//         const result_ = await Chat.find({
//             $or: [
//                 { roomid: message.to + message.from },
//                 { roomid: message.from + message.to }
//             ]
//         })
//         console.log("🚀 ~ file: chat.js:132 ~ chatRoom ~ result_", result_)
//         io.to(socket.user._id.toString()).emit('data', result_ )


//         io.to(result.roomid).emit('recieveMessage', newMsg)
//         io.to(socket.user._id.toString()).emit('addThisRoom', room[0])
//         io.to(message.to).emit('addThisRoom', room[0])

//     } else {

//         // console.log("room found")
//         if (result.user1 == socket.user._id.toString()) {
//             await Room.findByIdAndUpdate(result._id, { newMessage2: result.newMessage2 + 1 })
//         } else {
//             await Room.findByIdAndUpdate(result._id, { newMessage1: result.newMessage1 + 1 })
//         }

//         let newMsg = await new Chat({
//             roomid: result.roomid,
//             to: message.to,
//             from: message.from,
//             message: message.message

//         }).save()
//         newMsg = { ...newMsg._doc, sender: socket.user.userName }
//         await refreshRoom(socket.user._id.toString())
//         await refreshRoom(message.to)
//         const result_ = await Chat.find({
//             $or: [
//                 { roomid: message.to + message.from },
//                 { roomid: message.from + message.to }
//             ]
//         })
//         console.log("🚀 ~ file: chat.js:132 ~ chatRoom ~ result_", result_)
//         io.to(socket.user._id.toString()).emit('data', result_ )

//         // console.log("🚀 ~ file: chat.js:205 ~ chatRoom ~ newMsg", newMsg)
//         io.to(result.roomid).emit('recieveMessage', newMsg)//

//     }
// }

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

})



socket.on('joinNewUserRoom', roomid => {
socket.join(roomid)
})

socket.on('getOldMessages', async (user, cb) => {
// console.log("🚀 ~ file: getOldMessages ~ socket.on ~ user", user)
const result = await Chat.find({
$or: [
{ roomid: user.to + user.from },
{ roomid: user.from + user.to }
]
})
// console.log(result, "---------------getOldMessages")
io.to(socket.user._id.toString()).emit('data', result)
// cb(result)
})

async function refreshRoom(userid) {
let room = await Room.aggregate([
{
$match: {
$or: [
{ user1: mongoose.Types.ObjectId(userid) },
{ user2: mongoose.Types.ObjectId(userid) }
]
},
},
{
$lookup: {
from: "users",
localField: "user1",
foreignField: "_id",
as: "user1",
},
},
{ $unwind: "$user1" },
{
$lookup: {
from: "users",
localField: "user2",
foreignField: "_id",
as: "user2",
},
}, { $unwind: "$user2" },

{
$sort: { updatedAt: -1 }
},

{
$project: {
"roomid": 1, "newMessage1": 1, "newMessage2": 1, "user1": { _id: 1, username: 1 }, "user2": { _id: 1, username: 1 }
}
},

])
if (room.length) {
// console.log("🚀 ~ file: chat.js:269 ~ refreshRoom ~ room", room)
io.to(userid).emit('rooms', { room: room })
} else {
io.to(userid).emit('rooms', { room: "" })
}
}

socket.on("newMessages",async (user)=>{
console.log("notificationsss");
const finduser  = await users.findById({_id : user.to});
console.log(finduser.notifychat)
if(finduser.notifychat == 0){
await users.findByIdAndUpdate({_id : user.to},{notifychat : 1});
}
else{
const findoldmsg = finduser.notifychat + 1;
console.log( findoldmsg);

await users.findByIdAndUpdate({_id : user.to},{notifychat : findoldmsg});
}
io.to(socket.user._id.toString()).emit('notifications', `new messages,${user.message}`)
});






// socket.on('setMessageDigit', async user => {
//     // console.log(user)
//     if (user?.to && user?.from) {
//         const result = await Room.findOne({
//             $or: [
//                 { roomid: user.to + user.from },
//                 { roomid: user.from + user.to }
//             ]
//         })
//         if (result) {
//             if (result.user1 == socket.user._id.toString()) {
//                 await Room.findByIdAndUpdate(result._id, { newMessage1: 0 })
//             } else {
//                 await Room.findByIdAndUpdate(result._id, { newMessage2: 0 })
//             }
//         }
//         refreshRoom(socket.user._id.toString())
//     }
// })

// socket.on('deleteMsg', async (id, cb) => {
//     await Chat.findByIdAndDelete(id)
//     cb(true)
// })




// -----------------------------------------------------------------
// console.log('a user connected');
// const id = socket.handshake.query.userName
// console.log("🚀 ~ file: chat.js:13 ~ io.on ~ socket.handshake.query.token", socket.handshake.query.userName)
// // console.log("🚀 ~ file: chat.js:13 ~ io.on ~ socket.handshake.auth.token", socket.handshake.auth.token)
// console.log("🚀 ~ file: server.js:21 ~ io.on ~ id", id)
// socket.on('message', async data => {
//     console.log("🚀 ~ file: server.js:24 ~ socket.on ~ data >>>>>>>>>>>>>>>>>>>> ", data)



//     const message = {
//     message: data.message,
//     senderUsername: data.senderUsername,
//     sentAt: Date.now()
//     }
//     messages.push(message)
//     console.log("🚀 ~ file: server.js:36 ~ socket.on ~ messages", messages)
//     io.emit('message', message)

// })
// -----------------------------------------------------------------
});



} catch (err) {
console.log(err)
}

}

module.exports = chatRoom




// flutter

// import 'dart:async';
// import 'dart:developer';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:gftr/Helper/apiConstants.dart';
// import 'package:gftr/Helper/colorConstants.dart';
// import 'package:gftr/View/Widgets/customLoader.dart';
// import 'package:gftr/View/Widgets/customText.dart';
// import 'package:gftr/View/Widgets/drawer.dart';
// import 'package:gftr/ViewModel/Cubits/Msgnotifications.dart';
// import 'package:gradient_borders/box_borders/gradient_box_border.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:socket_io_client/socket_io_client.dart';
// import '../../Helper/appConfig.dart';
// import '../../Helper/imageConstants.dart';
// import 'package:flutter/foundation.dart' as foundation;
//
//
// class MessagesPage extends StatefulWidget {
// String userId;
// String userName;
// String targetId;
// String Avatar;
// MessagesPage(
// {Key? key,
// required this.userId,
// required this.targetId,
// required this.userName, required  this.Avatar})
//     : super(key: key);
//
// @override
// State<MessagesPage> createState() => _MessagesPageState();
// }
//
// class _MessagesPageState extends State<MessagesPage> {
// TextEditingController messageController = TextEditingController();
// FocusNode focusNode=FocusNode();
// List messages = [];
// bool emojiShowing = false;
// bool? isConcted;
// bool? isActive;
//
// // String? roomId;
// late IO.Socket socket;
//
// StreamController<List<dynamic>> messageList = StreamController<List<dynamic>>();
// Stream<List<dynamic>> userResponse2() {
// socket.emit("getOldMessages", {"to": widget.targetId, "from": widget.userId});
// return messageList.stream;
// }
//
// ScrollController _scrollController = ScrollController();
// // static const baseUrlsSocket = 'http://192.168.29.28:3330';
// void initSocket() async {
// socket = IO.io(
// ApiConstants.baseUrlsSocket,
// OptionBuilder()
//     .setTransports(['websocket'])
//     .disableAutoConnect()
//     .setQuery({"userName": widget.userId})
//     .build());
// //socket = io('/', { "query": { "recipientId": widget.userId } });
// socket.connect();
// socket.onConnect((_) {
// isConcted = socket.connected;
// log("isConcted : $isConcted");
// print('Connection established');
// });
// isActive = socket.active;
// //log("Active : $isActive");
// socket.emit("getOldMessages", {"to": widget.targetId, "from": widget.userId});
// socket.on("data", (data) {
// messageList.sink.add(data);
// log("Show a notification to the user showNotification(${data})");
// //  print("New message from ${data.widget.userId}: ${data.messages}");
// // log(data.toString());
// setState(() {});
// });
// socket.onDisconnect((_) => print('Connection Disconnection'));
// socket.onConnectError((err) => print('=====================================${err}'));
// socket.onError((err) => print("err"));
// }
//
// sendMesseage({
// required String message,
// required String toIdId,
// required String fromId,
// }) {
// socket.emit(
// "sendMessage", {
// 'message': message,
// "to": toIdId,
// "from": fromId,
// });
// socket.emit("getOldMessages", {"to": toIdId, "from": fromId});
// socket.emit("newMessages", {"to": toIdId, "from": fromId});
// setState(() {});
// }
// MessagnotiCubit messagnotiCubit =MessagnotiCubit();
//
// @override
// void initState() {
// super.initState();
// initSocket();
// userResponse2();
// setState(() {});
// }
//
// // @override
// // void didChangeDependencies() {
// //   super.didChangeDependencies();
// //   userResponse2();
// // }
//
// @override
// void dispose() {
// socket.disconnect();
// socket.dispose();
// _scrollController.dispose();
// messageList.close();
// super.dispose();
// }
//
// @override
// Widget build(BuildContext context) {
// return GestureDetector(
// onTap: () {
// FocusManager.instance.primaryFocus?.unfocus();
// emojiShowing = false;
// setState(() {});
// },
// child: Scaffold(
// backgroundColor: Colors.white,
// drawer: drawerWidget(context),
// appBar: AppBar(
// leading: Padding(
// padding:
// EdgeInsets.only(left: screenWidth(context, dividedBy: 13)),
// child: GestureDetector(
// onTap: () {
// Scaffold.of(context).openDrawer();
// },
// child: SizedBox(
// height: screenHeight(context, dividedBy: 30),
// width: screenWidth(context, dividedBy: 30),
// child: Image.asset(ImageConstants.sideMenu),
// ),
// ),
// ),
// backgroundColor: Colors.black,
// centerTitle: true,
// //elevation: 0,
// automaticallyImplyLeading: false,
// title: SizedBox(
// height: screenHeight(context, dividedBy: 30),
// // width: screenWidth(context,dividedBy: 20),
// child: Image.asset(ImageConstants.gftrLogo)),
// shape: const RoundedRectangleBorder(
// borderRadius: BorderRadius.vertical(
// bottom: Radius.circular(31),
// ),
// ),
// ),
// body: Column(children: [
// SizedBox(
// child: Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// GestureDetector(
// onTap: () {
// Navigator.pop(context,'refresh');
// },
// child: SizedBox(
// width: screenWidth(context, dividedBy: 5.2),
// height: screenHeight(context, dividedBy: 47),
// child: Icon(
// Icons.chevron_left_rounded,
// color: Colors.black,
// size: screenWidth(context, dividedBy: 16),
// ),
// ),
// ),
// customText(widget.userName, Colors.black, 14, FontWeight.bold,
// poppins),
//
// Padding(
// padding: const EdgeInsets.only(right: 8.0,top: 4,bottom: 4),
// child: Container(
// alignment: Alignment.center,
// width: screenWidth(context, dividedBy: 10),
// height: screenHeight(context, dividedBy: 20),
// decoration: BoxDecoration(
// // color: ColorCodes.coral,
// border: GradientBoxBorder(
// gradient: LinearGradient(
// colors: [ColorCodes.coral, ColorCodes.teal]),
// width: 2,
// ),
// shape: BoxShape.circle),
// child: ClipRRect(
// borderRadius: BorderRadius.circular(30),
// child: CircleAvatar(
// backgroundImage: NetworkImage(widget.Avatar),
// )
// ),
// ),
// ),
//
// ],
// ),
// ),
// Container(
// height: 2,
// width: double.infinity,
// color: const Color(0xffF2F2F2),
// ),
// StreamBuilder(
// stream: userResponse2(),
// builder: (context, AsyncSnapshot snapshot) {
// if (snapshot.hasError) {
// return Expanded(
// child: Center(
// child: customText(snapshot.error.toString(),
// Colors.black, 13, FontWeight.w500, poppins)));
// } else if (!snapshot.hasData) {
// return Expanded(
// child: Center(
// child: spinkitLoader(context, ColorCodes.teal)));
// } else if (snapshot.hasData) {
// return Expanded(
// child: ListView.builder(
// shrinkWrap: true,
// controller: _scrollController,
// // controller: _scrollController,
// physics: AlwaysScrollableScrollPhysics(),
// itemCount: snapshot.data.length + 1,
// itemBuilder: (context, index) {
// if(index == snapshot.data.length){
// return Container(height: 70);
// }
// return Row(
// mainAxisAlignment:
// snapshot.data[index]['from'] == widget.userId
// ? MainAxisAlignment.end
//     : MainAxisAlignment.start,
// children: [
// Flexible(
// child: Column(
// crossAxisAlignment:
// snapshot.data[index]['from'] == widget.userId
// ? CrossAxisAlignment.end
//     : CrossAxisAlignment.start,
// children: [
// Container(
// // width:screenWidth(context,dividedBy: 1.1),
// margin: const EdgeInsets.symmetric(
// vertical: 4,
// horizontal: 16,
// ),
// padding: const EdgeInsets.symmetric(
// vertical: 10,
// horizontal: 10,
// ),
// decoration: BoxDecoration(
// color: snapshot.data[index]['from'] ==
// widget.userId
// ? ColorCodes.teal
//     : Colors.grey.shade400,
// borderRadius: snapshot.data[index]
// ['from'] ==
// widget.userId
// ? BorderRadius.only(
// topRight: Radius.circular(30),
// topLeft: Radius.circular(30),
// bottomLeft: Radius.circular(30),
// )
//     : BorderRadius.only(
// topRight: Radius.circular(30),
// topLeft: Radius.circular(30),
// bottomRight: Radius.circular(30),
// ),
// ),
// child:Text(
// snapshot.data[index]['message'],
// style: TextStyle(
// color: snapshot.data[index]['from'] == widget.userId ? Colors.white : Colors.black,
// fontFamily: poppins),
// )
// ),
// Padding(
// padding: snapshot.data[index]['from'] == widget.userId ? EdgeInsets.only(right: 15) :EdgeInsets.only(left: 15),
// child: customText(snapshot.data[index]['time'], ColorCodes.greyText, 10, FontWeight.w100, 'poppins'),
// )
// ],
// ),
//
// ),
//
// ],
// );
// },
// ));
// }
// return Expanded(
// child: Center(
// child: spinkitLoader(context, ColorCodes.coral)));
// }),
// Container(
// margin: const EdgeInsets.all(18),
// decoration: BoxDecoration(
// borderRadius: BorderRadius.circular(10),
// color: Colors.white,
// boxShadow: const [
// BoxShadow(
// offset: Offset(1.0, 1.0),
// spreadRadius: 1,
// color: Colors.grey,
// blurRadius: 3)
// ]),
// padding: const EdgeInsets.symmetric(horizontal: 20),
// child: Row(children: [
// Padding(
// padding: EdgeInsets.only(
// right: screenWidth(context, dividedBy: 30)),
// child: GestureDetector(
// onTap: () {
// emojiShowing = !emojiShowing;
// FocusManager.instance.primaryFocus?.unfocus();
// setState(() {});
// },
// child: Image.asset(ImageConstants.emojis,
// height: screenHeight(context, dividedBy: 20),
// width: screenWidth(context, dividedBy: 14)),
// ),
// ),
// Flexible(
// child: TextField(
// controller: messageController,
// maxLines: null,
// onTap: () {
// emojiShowing = false;
// setState(() {});
// },
// decoration: const InputDecoration(
// border: InputBorder.none, hintText: "Messages..."),
// ),
// ),
// InkWell(
// onTap: () {
// if (messageController.text.isNotEmpty) {
// setState(() {
// _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 100), curve: Curves.easeOut);
// });
// // messages.insert(0, messageController.text.trim());
// sendMesseage(
// message: messageController.text.trim(),
// toIdId: widget.targetId,
// fromId: widget.userId
// );
// messageController.clear();
// setState(() {});
// }
// },
// child: Image(
// image: AssetImage(ImageConstants.send),
// width: screenWidth(context, dividedBy: 18),
// height: screenHeight(context, dividedBy: 18)))
// ])),
// Offstage(
// offstage: !emojiShowing,
// child: SizedBox(
// height: 250,
// child: EmojiPicker(
// textEditingController: messageController,
// config: Config(
// columns: 7,
// emojiSizeMax: 32 *
// (foundation.defaultTargetPlatform ==
// TargetPlatform.android
// ? 1.30
//     : 1.0),
// verticalSpacing: 0,
// horizontalSpacing: 0,
// gridPadding: EdgeInsets.zero,
// initCategory: Category.RECENT,
// bgColor: const Color(0xFFF2F2F2),
// indicatorColor: Colors.blue,
// iconColor: Colors.grey,
// iconColorSelected: Colors.blue,
// backspaceColor: Colors.blue,
// skinToneDialogBgColor: Colors.white,
// skinToneIndicatorColor: Colors.grey,
// enableSkinTones: true,
// recentsLimit: 28,
// replaceEmojiOnLimitExceed: false,
// noRecents: const Text(
// 'No Recents',
// style: TextStyle(fontSize: 20, color: Colors.black26),
// textAlign: TextAlign.center,
// ),
// loadingIndicator: const SizedBox.shrink(),
// tabIndicatorAnimDuration: kTabScrollDuration,
// categoryIcons: const CategoryIcons(),
// buttonMode: ButtonMode.MATERIAL,
// checkPlatformCompatibility: true,
// ),
// )
// )),
// ])),
// );
// }
// }