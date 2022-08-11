import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreDB {
  static CollectionReference allSongs =
      FirebaseFirestore.instance.collection("allSongs");
  static CollectionReference playLists =
      FirebaseFirestore.instance.collection("playLists");
  static CollectionReference users =
      FirebaseFirestore.instance.collection("users");
  static CollectionReference searches =
      FirebaseFirestore.instance.collection("searches");
  static CollectionReference chatRooms =
      FirebaseFirestore.instance.collection("chatRooms");
  static CollectionReference orders =
      FirebaseFirestore.instance.collection("orders");
  static CollectionReference customerService =
      FirebaseFirestore.instance.collection("customerService");
  Future<void> createUser(Map<String, String> userData,
      {String firebaseUserId}) async {
    users.doc(firebaseUserId).set(userData).catchError((e) {});
  }

  getUserInfo(String email) async {
    return users.where("userEmail", isEqualTo: email).get().catchError((e) {});
  }

  Future<QuerySnapshot> getChatsForCustomerService(
      Map<String, dynamic> searchDetails) {
    Future<QuerySnapshot> querySnapshot = customerService
        .where('lastUpdated', isGreaterThan: searchDetails['lastUpdated'])
        .where('emailMessageTitle',
            isEqualTo: searchDetails['emailMessageTitle'])
        .where('countryCode', isEqualTo: searchDetails['countryCode'])
        .where('userLang', isEqualTo: searchDetails['userLang'])
        .orderBy('lastUpdated', descending: true)
        .get();
    return querySnapshot;
  }

  Future<List<QuerySnapshot>> searchUserChatsByFirebaseId(
      {int userId, bool isCustomerService = false, String firebaseId}) {
    int startTime =
        DateTime.now().add(const Duration(days: -20)).millisecondsSinceEpoch;
    int customerServiceStartTime =
        DateTime.now().add(const Duration(days: -10)).millisecondsSinceEpoch;
    if (!isCustomerService) {
      Future<QuerySnapshot> querySnapshot1 = chatRooms
          .where('userId1', isEqualTo: userId)
          .where('lastUpdated', isGreaterThan: startTime)
          .orderBy('lastUpdated', descending: true)
          .get();
      Future<QuerySnapshot> querySnapshot2 = chatRooms
          .where('userId2', isEqualTo: userId)
          .where('lastUpdated', isGreaterThan: startTime)
          .orderBy('lastUpdated', descending: true)
          .get();
      // Future<QuerySnapshot> querySnapshot = customerService
      //     .where('chatRoomId', isEqualTo: firebaseId)
      //     .where('lastUpdated', isGreaterThan: customerServiceStartTime)
      //     .orderBy('lastUpdated', descending: true)
      //     .limit(1)
      //     .get();
      return Future.wait([querySnapshot1, querySnapshot2]); //, querySnapshot]);
    } else {
      Future<QuerySnapshot> querySnapshot = customerService
          .where('chatRoomId', isEqualTo: firebaseId)
          .where('lastUpdated', isGreaterThan: customerServiceStartTime)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();
      return Future.wait([querySnapshot]);
    }
  }

  Future<void> addChatRoom(
      {Map<String, dynamic> chatRoomDetails,
      String chatRoomId,
      bool isCustomerService = false}) {
    return !isCustomerService
        ? chatRooms
            .doc(chatRoomId)
            .set(chatRoomDetails, SetOptions(merge: true))
            .catchError((e) {})
        : customerService
            .doc(chatRoomId)
            .set(chatRoomDetails, SetOptions(merge: true))
            .catchError((e) {});
  }

  Future<void> addSearch(
      {Map<String, dynamic> newCategoryData, String userId}) {
    return searches
        .doc(userId)
        .set(newCategoryData, SetOptions(merge: true))
        .catchError((e) {});
  }

  Future<void> updateSearchCategory(
      {Map<String, dynamic> chatRoomDetails,
      String chatRoomId,
      bool isCustomerService = false}) {
    return !isCustomerService
        ? chatRooms
            .doc(chatRoomId)
            .set(chatRoomDetails, SetOptions(merge: true))
            .catchError((e) {})
        : customerService
            .doc(chatRoomId)
            .set(chatRoomDetails, SetOptions(merge: true))
            .catchError((e) {});
  }

  getChats(String chatRoomId, {bool isCustomerService = false}) async {
    int startTime =
        DateTime.now().add(const Duration(days: -30)).millisecondsSinceEpoch;
    return !isCustomerService
        ? chatRooms
            .doc(chatRoomId)
            .collection("chats")
            .where('time', isGreaterThan: startTime)
            .orderBy('time', descending: true)
            .limit(20)
            .snapshots()
        : customerService
            .doc(chatRoomId)
            .collection("chats")
            .where('time', isGreaterThan: startTime)
            .orderBy('time', descending: true)
            .limit(20)
            .snapshots();
  }

  getUserSongs(int userId) async {
    return allSongs
        .where("userId", isEqualTo: userId)
        .orderBy('songId', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getOrders(String itemId, String buyerId,
      {bool isCheckingOrder = true}) async {
    return isCheckingOrder
        ? orders
            .where("orderStatus", isNotEqualTo: "Sold")
            .where("buyerId", isEqualTo: buyerId)
            .where("itemId", isEqualTo: itemId)
            .limit(1)
            .get()
        : orders
            .where("orderStatus", isNotEqualTo: "Sold")
            .where("buyerId", isEqualTo: buyerId)
            .get();
  }

  Future<void> createOrders({Map<String, dynamic> orderInfo}) {
    Map<String, dynamic> f = {};
    f.addAll(orderInfo);
    f["actualOutcome"] = "";
    f["actualSoldTime"] = 0;
    return orders
        .doc(f['orderId'])
        .set(f, SetOptions(merge: true))
        .catchError((e) {});
  }

  Future<QuerySnapshot> getSellersOrders(String sellerId) async {
    return orders
        .where("orderStatus", isNotEqualTo: "Sold")
        .where("sellerId", isEqualTo: sellerId)
        .get();
  }

  deleteOrder(String orderId, int actualSoldTime, String actualOutcome) {
    Map<String, dynamic> updates = {
      'actualSoldTime': actualSoldTime,
      "orderStatus": "Sold",
      "actualOutcome": actualOutcome
    };
    return orders.doc(orderId).update(updates);
  }

  getDefaultSongs(int songsBeforeTime) async {
    return allSongs
        .where("songId", isLessThan: songsBeforeTime)
        .orderBy('songId', descending: true)
        .limit(20)
        .get();
  }

  updateSong(String songId, Map<String, dynamic> updates) async {
    return allSongs.doc(songId).update(updates);
  }

  getUserRecentSongs(String firebaseId) async {
    return playLists.where("firebaseId", isEqualTo: firebaseId).snapshots();
  }

  removeRecentSong(String firebaseId, String songId) async {
    return allSongs
        .doc(firebaseId)
        .collection('recentSongs')
        .doc(songId)
        .delete();
  }

  Future<void> addSong(String songId, Map<String, dynamic> songMetadata) {
    return allSongs.doc(songId).set(songMetadata).catchError((e) {});
  }

  Future<void> addMessage(
      String chatRoomId, Map<String, dynamic> chatMessageData,
      {bool isCustomerService = false}) {
    return !isCustomerService
        ? chatRooms
            .doc(chatRoomId)
            .collection("chats")
            .add(chatMessageData)
            .catchError((e) {})
        : customerService
            .doc(chatRoomId)
            .collection("chats")
            .add(chatMessageData)
            .catchError((e) {});
  }

  getUserChats({String myFirebaseId}) async {
    return chatRooms.where('users', arrayContains: myFirebaseId).snapshots();
  }

  String convertTimeStampToDisplayTimeString(int time) {
    DateTime now = DateTime.now();
    DateFormat format = DateFormat('HH:mm a');
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    Duration diff = now.difference(date);
    if (diff.inSeconds <= 0 ||
        diff.inSeconds > 0 && diff.inMinutes == 0 ||
        diff.inMinutes > 0 && diff.inHours == 0 ||
        diff.inHours > 0 && diff.inDays == 0) {
      return format.format(date);
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        return '1 day ago';
      } else {
        return diff.inDays.toString() + ' days ago';
      }
    } else {
      if (diff.inDays == 7) {
        return '1 week ago';
      } else {
        return (diff.inDays / 7).floor().toString() + ' weeks ago';
      }
    }
  }
}
