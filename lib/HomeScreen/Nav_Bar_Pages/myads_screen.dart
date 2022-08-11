import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/firestore_db.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/views/product_details.dart';

class MyAdsScreen extends StatefulWidget {
  UserModel currentUser;
  UserPreferences cUP = UserPreferences();
  Map<String, dynamic> order;

  MyAdsScreen(
      {Key key, @required this.cUP, @required this.currentUser, this.order})
      : super(key: key);

  @override
  MyAdsScreenState createState() => MyAdsScreenState();
}

class MyAdsScreenState extends State<MyAdsScreen> {
  ProductListForHomePage myAds, myFavAds;
  String myFavedAds;
  bool isLoading = true;
  bool hasNotLoadedOrders = true;
  bool isLoadingOrders = false;
  int startIndex = 0;
  List<Map<String, dynamic>> orders = [];
  final firestoreDB = FirestoreDB();

  @override
  void initState() {
    if (widget.order != null) {
      orders.add(widget.order);
      startIndex = 2;
    }
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    setUserPrefs();
  }

  Future setUserPrefs() async {
    setState(() {
      myFavedAds = widget.cUP.getString(Constants.peerVendorsFavorits);
    });
    List<ProductListForHomePage> value = await Future.wait([
      ApiRequest.getUsersAds(widget.currentUser.user_id.toString(),
          widget.currentUser.currencySymbol),
      ApiRequest.getLikedAds(myFavedAds, widget.currentUser.currencySymbol)
    ]);
    setState(() {
      myAds = value[0];
      myFavAds = value[1];
      isLoading = false;
    });
  }

  markAdAsSoldOrDeleted(BuildContext context, AdsDetail adsDetail,
      String action, bool isFavorites) async {
    if (isFavorites) {
      myFavAds.ads_details
          .removeWhere((adDetails) => adDetails.ad_id == adsDetail.ad_id);
      List<String> cfavs = myFavedAds.split(',');
      cfavs.remove(adsDetail.ad_id.toString());
      String newFavedAds = cfavs.join(",");
      await widget.cUP.saveString(Constants.peerVendorsFavorits, newFavedAds);
      myFavedAds = newFavedAds;
      setState(() {});
    } else {
      Map<String, String> map = {
        'ad_id': adsDetail.ad_id.toString(),
        'mark_reason': action
      };
      var t = await ApiRequest.markAdAsSoldDeletedOrExpired(map);
      String message = action == 'sold'
          ? AppLocalizations.of(context).addMarkedAsSold
          : AppLocalizations.of(context).addDeletedSuccessfully;

      if (t != null) {
        myAds.ads_details
            .removeWhere((eachAd) => eachAd.ad_id == adsDetail.ad_id);
        setState(() {});
        Utils.showToast(context, message, colorSuccess);
        Navigator.pop(context, true);
      } else {
        Utils.showToast(context,
            AppLocalizations.of(context).actionNotPerformed, colorError);
      }
    }
  }

  Widget buildAdAdapter(BuildContext context, int index, bool isFavorites) {
    AdsDetail currentAd =
        isFavorites ? myFavAds.ads_details[index] : myAds.ads_details[index];
    return SizedBox(
      height: 102,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => ProductDetails(
                    adsDetail: currentAd,
                    currentUser: widget.currentUser,
                    cUP: widget.cUP)),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8)),
                  child: Image.network(
                    '${Constants.imageBaseUrl}${currentAd.images[0]}',
                    width: 96,
                    height: double.maxFinite,
                    fit: BoxFit.cover,
                    errorBuilder: (context, exception, stack) {
                      return Image.asset(
                        'assets/images/img_product_placeholder_slider.jpg',
                        fit: BoxFit.cover,
                        width: 96,
                      );
                    },
                  ),
                ),
                Positioned(
                    right: -13,
                    top: -13,
                    child: IconButton(
                        icon: const CircleAvatar(
                          child: Icon(
                            Icons.delete,
                            color: Colors.pinkAccent,
                          ),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!isFavorites) {
                            Utils.setDialog(context,
                                titleStyle: const TextStyle(
                                    color: Colors.pink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                title: AppLocalizations.of(context).want2Delete,
                                children: [
                                  Text(currentAd.item_name),
                                ],
                                actions: [
                                  ElevatedButton(
                                    child:
                                        Text(AppLocalizations.of(context).no),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.red),
                                      onPressed: () {
                                        markAdAsSoldOrDeleted(context,
                                            currentAd, 'deleted', isFavorites);
                                      },
                                      child: Text(AppLocalizations.of(context)
                                              .yes +
                                          ' ' +
                                          AppLocalizations.of(context).delete))
                                ]);
                          } else {
                            myFavAds.ads_details.removeWhere(
                                (eachAd) => eachAd.ad_id == currentAd.ad_id);
                            List<String> cfavs = myFavedAds.split(',');
                            cfavs.remove(currentAd.ad_id.toString());
                            String newFavedAds = cfavs.join(",");
                            await widget.cUP.saveString(
                                Constants.peerVendorsFavorits, newFavedAds);
                            myFavedAds = newFavedAds;
                            setState(() {});
                          }
                        }))
              ]),
              Padding(
                padding: const EdgeInsets.only(
                    left: 12, right: 12, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Utils.shortenText(currentAd.item_name, desiredLength: 26),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: SizedBox(
                        width: (SizeConfig.screenWidth - 132),
                        child: Text(
                          Utils.shortenText(currentAd.item_description,
                              desiredLength: 60),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: colorGrey600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppLocalizations.of(context).price}: ${currentAd.price}\t\t',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAdsList(ProductListForHomePage myAdsDetails,
      {bool isFavorites = false}) {
    String message = isFavorites
        ? AppLocalizations.of(context).noFavItems
        : AppLocalizations.of(context).noAddsAvailable;
    if (myAdsDetails == null ||
        myAdsDetails.ads_details == null ||
        myAdsDetails.ads_details.isEmpty) {
      return Center(child: Text(message));
    } else {
      return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: false,
        itemCount: myAdsDetails.ads_details.length,
        itemBuilder: (context, index) {
          return buildAdAdapter(context, index, isFavorites);
        },
      );
    }
  }

  loadOrders() async {
    isLoadingOrders = true;
    setState(() {});
    if (myAds?.ads_details?.isNotEmpty == true) {
      final querySnapshotList = await Future.wait([
        firestoreDB.getOrders("0", widget.currentUser.user_id.toString(),
            isCheckingOrder: false),
        firestoreDB.getSellersOrders(widget.currentUser.user_id.toString())
      ]);
      var s = querySnapshotList[0].docs;
      s.addAll(querySnapshotList[1].docs);
      completeOrdersSetup(s);
    } else {
      final querySnapshot = await firestoreDB.getOrders(
          "0", widget.currentUser.user_id.toString(),
          isCheckingOrder: false);
      completeOrdersSetup(querySnapshot.docs);
    }
    isLoadingOrders = false;
    hasNotLoadedOrders = false;
    setState(() {});
  }

  completeOrdersSetup(List<dynamic> docs) {
    String s = orders.isEmpty ? "0" : orders[0]["itemId"];
    if (docs.isNotEmpty) {
      for (dynamic doc in docs) {
        final res = doc.data() as Map<String, dynamic>;
        if (res["itemId"] != s) {
          orders.add(res);
        }
      }
    }
  }

  TextStyle titleStyle() {
    return TextStyle(fontSize: 17, fontWeight: FontWeight.bold);
  }

  Widget buildDeleteOrUpdateOrder(BuildContext context,
      Map<String, dynamic> currentOrder, String buttonText, ButtonStyle style,
      {markAsSoldReason = "marked as sold", bool isDelete = false}) {
    return ElevatedButton.icon(
        icon: Icon(
            isDelete ? FontAwesomeIcons.trashAlt : FontAwesomeIcons.thumbsUp),
        style: style,
        onPressed: () {
          Navigator.of(context).pop();
          String thisOrderId = currentOrder['orderId'];
          int actualSoldTime = DateTime.now().toUtc().millisecondsSinceEpoch;
          Map<String, String> params = {
            "orderStatus": "Sold",
            "actualOutcome": markAsSoldReason,
            "actualSoldTime": actualSoldTime.toString(),
            "initiatedBy": widget.currentUser.user_id.toString()
          };
          for (String key in "orderId,buyerId,sellerId".split(',')) {
            params[key] = currentOrder[key].toString();
          }
          firestoreDB.deleteOrder(
              thisOrderId, actualSoldTime, markAsSoldReason);
          ApiRequest.updateOrder(params: params);
          orders.removeWhere((element) => element['orderId'] == thisOrderId);
          setState(() {});
        },
        label: Text(buttonText));
  }

  ButtonStyle actionStyle(Color pc) => Utils.roundedButtonStyle(
      primaryColor: pc, minSize: Size(SizeConfig.screenWidth * 0.7, 38));

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Utils.loadingWidget(AppLocalizations.of(context).loadingPleaseWait)
        : DefaultTabController(
            length: 3,
            initialIndex: startIndex,
            child: Builder(builder: (BuildContext context) {
              final TabController tabController =
                  DefaultTabController.of(context);
              tabController.addListener(() {
                if (!tabController.indexIsChanging &&
                    tabController.index == 2 &&
                    hasNotLoadedOrders) {
                  loadOrders();
                }
              });
              return Scaffold(
                  backgroundColor: Colors.blue[100],
                  appBar: AppBar(
                    leading: const SizedBox.shrink(),
                    title: Text(AppLocalizations.of(context).myAds),
                    centerTitle: true,
                    bottom: TabBar(
                        indicatorWeight: 5,
                        indicatorColor: Colors.blue[200],
                        tabs: [
                          Tab(
                            icon: const Icon(FontAwesomeIcons.shoppingCart),
                            text: AppLocalizations.of(context).myAds,
                          ),
                          Tab(
                              icon: const Icon(Icons.favorite_border),
                              text: AppLocalizations.of(context).favourites),
                          Tab(
                              icon: const Icon(FontAwesomeIcons.shippingFast),
                              text: AppLocalizations.of(context).myOrders)
                        ]),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                  body: SafeArea(
                      child: TabBarView(children: [
                    buildAdsList(myAds, isFavorites: false),
                    buildAdsList(myFavAds, isFavorites: true),
                    orders.isEmpty
                        ? Center(
                            child: isLoadingOrders
                                ? Utils.loadingWidget(
                                    AppLocalizations.of(context)
                                        .loadingPleaseWait)
                                : Text(AppLocalizations.of(context).noOrders))
                        : ListView.builder(
                            primary: true,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: false,
                            itemCount: orders.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Card(
                                  elevation: 5,
                                  child: ListTile(
                                      title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          AppLocalizations.of(context)
                                              .tapOrLongPressForOrderDetails
                                              .split('. ')
                                              .first,
                                          style: titleStyle()),
                                      const SizedBox(height: 10),
                                      Text(
                                          AppLocalizations.of(context)
                                              .tapOrLongPressForOrderDetails
                                              .split('. ')
                                              .last,
                                          style: titleStyle())
                                    ],
                                  )),
                                );
                              }
                              var currentOrder = orders[index - 1];
                              Color color = currentOrder['sellerId'] ==
                                      widget.currentUser.user_id.toString()
                                  ? Colors.white
                                  : Colors.green[100];
                              bool userIsSeller = color != Colors.white;
                              return Card(
                                  elevation: 5,
                                  color: color,
                                  child: ListTile(
                                      horizontalTitleGap: 10,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                      onLongPress: () {
                                        List<Widget> children = [];
                                        var keys =
                                            'orderId, itemName, itemPrice, quantity, sellerName, deliveryAddress, pickUpLocation, deliveryInstructions'
                                                .split(', ');
                                        for (String key in keys) {
                                          children.addAll([
                                            Text("$key: ${currentOrder[key]}"),
                                            SizedBox(height: 5)
                                          ]);
                                        }
                                        children.add(SizedBox(height: 10));
                                        children.add(Text(
                                            "deliveryDate: ${currentOrder['deliveryDate'] ?? ''} ",
                                            style: titleStyle()));
                                        if (userIsSeller) {
                                          children.addAll([
                                            SizedBox(height: 10),
                                            Text(AppLocalizations.of(context)
                                                .sellerNoteToEngage)
                                          ]);
                                        }
                                        Utils.setDialog(context,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                                vertical: 15.0),
                                            title: AppLocalizations.of(context)
                                                .productDetails,
                                            children: children,
                                            actions: [
                                              userIsSeller
                                                  ? buildDeleteOrUpdateOrder(
                                                      context,
                                                      currentOrder,
                                                      AppLocalizations.of(
                                                              context)
                                                          .markAsDelivered,
                                                      actionStyle(Colors.blue),
                                                      markAsSoldReason:
                                                          "marked as sold",
                                                      isDelete: false)
                                                  : const SizedBox.shrink(),
                                              ElevatedButton.icon(
                                                  icon: Icon(FontAwesomeIcons
                                                      .thumbsUp),
                                                  style:
                                                      actionStyle(Colors.blue),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  label: Text(userIsSeller
                                                      ? AppLocalizations.of(
                                                              context)
                                                          .stillProcessingOrder
                                                      : AppLocalizations.of(
                                                              context)
                                                          .ok)),
                                              buildDeleteOrUpdateOrder(
                                                  context,
                                                  currentOrder,
                                                  AppLocalizations.of(context)
                                                      .cancelOrder,
                                                  actionStyle(Colors.pink[300]),
                                                  markAsSoldReason:
                                                      "cancel this order",
                                                  isDelete: true),
                                            ]);
                                      },
                                      onTap: () async {
                                        if (color == Colors.white) {
                                          var ad = await ApiRequest.getAd(
                                              int.parse(currentOrder['itemId']),
                                              widget
                                                  .currentUser.currencySymbol);
                                          if (ad != null) {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        ProductDetails(
                                                            adsDetail: ad,
                                                            currentUser: widget
                                                                .currentUser,
                                                            cUP: widget.cUP)));
                                          } else {
                                            Utils.showToast(
                                                context,
                                                AppLocalizations.of(context)
                                                    .itemSold,
                                                Colors.red);
                                          }
                                        }
                                      },
                                      leading: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                          child: Image.network(
                                              'https://pvendors.s3.eu-west-3.amazonaws.com/prod_ad_images/${currentOrder["images"].split('|').first}',
                                              fit: BoxFit.cover, errorBuilder:
                                                  (context, exception, trace) {
                                            return Image.asset(
                                              'assets/images/img_product_placeholder.jpg',
                                              fit: BoxFit.cover,
                                            );
                                          })),
                                      title: Wrap(
                                        children: [
                                          Text(
                                            AdsDetail.stringifyPrice(
                                                double.tryParse(
                                                    currentOrder["itemPrice"]),
                                                widget.currentUser
                                                    .currencySymbol),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(" " + currentOrder["itemName"],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis)
                                        ],
                                      ),
                                      subtitle: Text(
                                          "Status: ${currentOrder['orderStatus']}",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold))));
                            })
                  ])));
            }));
  }
}
