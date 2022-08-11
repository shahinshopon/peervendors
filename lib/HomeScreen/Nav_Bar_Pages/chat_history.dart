import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/views/chat.dart';

class ChatLoginScreen extends StatefulWidget {
  final bool isBackArrow;
  final Map<String, dynamic> searchDetails;
  UserPreferences cUP = UserPreferences();
  UserModel currentUser;

  ChatLoginScreen(
      {Key key,
      @required this.cUP,
      @required this.currentUser,
      @required this.isBackArrow,
      @required this.searchDetails})
      : super(key: key);

  @override
  ChatLoginScreenState createState() => ChatLoginScreenState();
}

class ChatLoginScreenState extends State<ChatLoginScreen> {
  final firestoreDb = FirestoreDB();
  bool isLoading = true;
  bool hasFinishedLoadingCurrentUsersChats = false;
  List<QueryDocumentSnapshot> currentUsersChats;

  @override
  void initState() {
    super.initState();
    setUserPrefs();
  }

  Future setUserPrefs() async {
    if (widget.searchDetails.isNotEmpty) {
      firestoreDb
          .getChatsForCustomerService(widget.searchDetails)
          .then((querySnapshot) {
        setState(() {
          currentUsersChats = querySnapshot.docs;
          hasFinishedLoadingCurrentUsersChats = true;
          isLoading = false;
        });
      });
    } else {
      firestoreDb
          .searchUserChatsByFirebaseId(
              userId: widget.currentUser.user_id,
              firebaseId: widget.currentUser.firebaseUserId)
          .then((chatFriends) {
        List<QueryDocumentSnapshot> myChats = chatFriends[0].docs;
        List<QueryDocumentSnapshot> chatsToMe = chatFriends[1].docs;
        //List<QueryDocumentSnapshot> csChats = chatFriends[2].docs;

        myChats.addAll(chatsToMe);
        //myChats.addAll(csChats);
        myChats.sort((a, b) => b["lastUpdated"].compareTo(a["lastUpdated"]));
        setState(() {
          currentUsersChats = myChats;
          hasFinishedLoadingCurrentUsersChats = true;
          isLoading = false;
        });
      });
    }
  }

  Widget currentUsersChatsList() {
    return hasFinishedLoadingCurrentUsersChats
        ? widget.searchDetails.isEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: currentUsersChats.length,
                itemBuilder: (context, index) {
                  var data =
                      currentUsersChats[index].data() as Map<String, dynamic>;
                  int lastUpdated = data['lastUpdated'];
                  if (data.containsKey("countryCode")) {
                    return buildCSUserTile(data);
                  } else {
                    List<dynamic> usersInThisChat = data['userNames'];
                    int userId1 = data['userId1'];
                    int userId2 = data['userId2'];
                    String currentUsersUserName =
                        widget.currentUser.username.toLowerCase().trim();
                    int otherUsersUserId = userId1 == widget.currentUser.user_id
                        ? userId2
                        : userId1;
                    String otherUsersUserName =
                        usersInThisChat[0].toLowerCase() == currentUsersUserName
                            ? usersInThisChat[1]
                            : usersInThisChat[0];
                    String profile1 = '';
                    String profile2 = '';
                    if (userId1 == widget.currentUser.user_id) {
                      profile1 = widget.currentUser.profilePicture;
                      if (data.containsKey('userProfile2')) {
                        profile2 = data['userProfile2'];
                      }
                    } else {
                      profile2 = widget.currentUser.profilePicture;
                      if (data.containsKey('userProfile1')) {
                        profile1 = data['userProfile1'];
                      }
                    }
                    Map<String, dynamic> lastAdInfo = Map.from(data)
                      ..removeWhere((k, v) =>
                          !'lastAdImage,lastAdTitle,lastDescription,lastAdPrice,lastAdId'
                              .contains(k));
                    return userTile(
                        otherUsersUserName: otherUsersUserName,
                        otherUsersUserId: otherUsersUserId,
                        lastUpdated: lastUpdated,
                        lastAdInfo: lastAdInfo,
                        profile1: profile1,
                        profile2: profile2);
                  }
                })
            : ListView.builder(
                shrinkWrap: true,
                itemCount: currentUsersChats.length,
                itemBuilder: (context, index) {
                  var data =
                      currentUsersChats[index].data() as Map<String, dynamic>;
                  return buildCSUserTile(data);
                })
        : const SizedBox.shrink();
  }

  Widget buildCSUserTile(Map<String, dynamic> data) {
    int lastUpdated = data['lastUpdated'];
    int otherUsersUserId = data['userId'];
    String otherUsersUserName = data['userName'];
    String otherUsersFirebaseId = data['chatRoomId'];
    Map<String, dynamic> lastAdInfo = Map.from(data)
      ..removeWhere((k, v) =>
          !'lastAdImage,lastAdTitle,lastDescription,lastAdPrice,lastAdId'
              .contains(k));
    return userTile(
        otherUsersUserId: otherUsersUserId,
        otherUsersUserName: otherUsersUserName,
        otherUsersFirebaseId: otherUsersFirebaseId,
        lastUpdated: lastUpdated,
        lastAdInfo: lastAdInfo);
  }

  Widget userTile(
      {String otherUsersUserName,
      int otherUsersUserId,
      int lastUpdated,
      String otherUsersFirebaseId,
      Map<String, dynamic> lastAdInfo,
      String profile1,
      String profile2}) {
    String oP =
        profile1 == widget.currentUser.profilePicture ? profile2 : profile1;
    return Card(
        elevation: 5,
        color: Colors.indigo[80],
        child: ListTile(
          tileColor: Colors.white,
          horizontalTitleGap: 0.0,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          leading: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: '$oP'.length > 6
                  ? Image.network(
                      'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/$oP',
                      fit: BoxFit.cover,
                      errorBuilder: (context, exception, trace) {
                      return Image.asset(
                          'assets/images/default_profile_picture.jpg',
                          fit: BoxFit.cover);
                    })
                  : Image.asset('assets/images/default_profile_picture.jpg',
                      fit: BoxFit.cover)),
          title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                otherUsersUserName,
                style: TextStyle(color: Colors.black, fontSize: 16),
              )),
          subtitle: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                AppLocalizations.of(context).lastUpdated +
                    ' ' +
                    firestoreDb
                        .convertTimeStampToDisplayTimeString(lastUpdated),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                ), //fontStyle: FontStyle.italic),
              )),
          trailing: GestureDetector(
            onTap: () {
              chatWithSomeone(
                  toUserId: otherUsersUserId,
                  toUserName: otherUsersUserName,
                  myUserId: widget.currentUser.user_id,
                  otherUsersFirebaseId: otherUsersFirebaseId,
                  lastAdInfo: lastAdInfo,
                  profile1: profile1,
                  profile2: profile2);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration:
                  Utils.containerBoxDecoration(color: Colors.blue, radius: 15),
              child: Text(
                AppLocalizations.of(context).message,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ));
  }

  chatWithSomeone(
      {int toUserId,
      String toUserName,
      int myUserId,
      String otherUsersFirebaseId,
      Map<String, dynamic> lastAdInfo,
      String profile1,
      String profile2}) {
    List<int> userIds = [widget.currentUser.user_id, toUserId];
    List<String> userNames = [toUserName, widget.currentUser.username];
    userNames.sort();
    userIds.sort();
    if (widget.searchDetails.isEmpty) {
      String chatRoomId = '${userIds[0]}_${userIds[1]}';
      Map<String, dynamic> chatRoomData = {
        'firebaseUserIds': userIds,
        'chatRoomId': chatRoomId,
        'userNames': userNames,
        'userId1': userIds[0],
        'userId2': userIds[1],
        'lastUpdated': DateTime.now().millisecondsSinceEpoch
      };
      if (lastAdInfo != null) {
        chatRoomData.addAll(lastAdInfo);
      }
      if (profile1 != '') {
        chatRoomData['userProfile1'] = profile1;
      }
      if (profile2 != '') {
        chatRoomData['userProfile2'] = profile2;
      }
      firestoreDb.addChatRoom(
          chatRoomDetails: chatRoomData, chatRoomId: chatRoomId);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Chat(
                  currentUser: widget.currentUser,
                  otherUsersUserId: toUserId,
                  chatRoomId: chatRoomId,
                  toUserName: toUserName,
                  userLang: widget.currentUser.user_lang,
                  chatRoomDetails: chatRoomData,
                  isCustomerService: false,
                  cUP: widget.cUP,
                  fromUserName: widget.currentUser.username)));
    } else {
      Map<String, dynamic> chatRoomDetails = {
        "chatRoomId": otherUsersFirebaseId,
        "lastUpdated": DateTime.now().millisecondsSinceEpoch
      };
      firestoreDb.addChatRoom(
          chatRoomDetails: chatRoomDetails,
          chatRoomId: otherUsersFirebaseId,
          isCustomerService: true);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => Chat(
              currentUser: widget.currentUser,
              otherUsersUserId: toUserId,
              chatRoomId: otherUsersFirebaseId,
              toUserName: toUserName,
              userLang: widget.searchDetails['userLang'],
              fromUserName: AppLocalizations.of(context).customerService,
              chatRoomDetails: chatRoomDetails,
              cUP: widget.cUP,
              isCustomerService: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue[100],
        appBar: AppBar(
          leading: widget.isBackArrow
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              : const SizedBox.shrink(),
          title: Text(AppLocalizations.of(context).chats),
          centerTitle: true,
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
        body: isLoading
            ? Utils.loadingWidget(
                AppLocalizations.of(context).loadingPleaseWait)
            : currentUsersChats.length > 0
                ? currentUsersChatsList()
                : Utils.messageWidget(
                    context, AppLocalizations.of(context).noChatsAvailable));
  }
}
