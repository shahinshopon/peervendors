import 'package:intl/intl.dart';

class ProductListForHomePage {
  List<AdsDetail> ads_details = [];
  ProductListForHomePage({this.ads_details});

  factory ProductListForHomePage.fromJson(
      Map<String, dynamic> json, String currencySymbol) {
    if (json != null && json['ads_details'].length > 0) {
      List<dynamic> adsDetails = json['ads_details'] as List;
      adsDetails.sort((a, b) => (b['ad_id']).compareTo(a['ad_id']));
      var t = adsDetails.map((item) => item['category_id']).toSet();
      Map<int, List<dynamic>> s = {};
      t.forEach((e) => s.addAll({e: []}));
      adsDetails.forEach((element) => s[element['category_id']].add(element));
      List<dynamic> finalAds = [];
      while (s.isNotEmpty) {
        s.entries.forEach((e) {
          finalAds.add(e.value[0]);
          s[e.key] = s[e.key].sublist(1);
        });
        s.removeWhere((key, value) => value.isEmpty);
      }
      return ProductListForHomePage(
          ads_details: finalAds
              .map((i) => AdsDetail.fromJson(i, currencySymbol))
              .toList());
    } else {
      return ProductListForHomePage(ads_details: []);
    }
  }

  factory ProductListForHomePage.clone(ProductListForHomePage source) {
    return ProductListForHomePage(
        ads_details: source == null || source.ads_details == null
            ? []
            : source.ads_details.map((e) => e).toList());
  }
  factory ProductListForHomePage.fromSavedAds(Map<String, dynamic> json) {
    return ProductListForHomePage(
        ads_details: json != null && json['ads_details'].length > 0
            ? (json['ads_details'] as List)
                .map((i) => AdsDetail.fromSavedAds(i))
                .toList()
            : []);
  }

  addNewAds(ProductListForHomePage newPdtList) {
    List<AdsDetail> ads = [];
    if (newPdtList?.ads_details?.length != null) {
      ads = newPdtList.ads_details;
    }
    if (ads_details != null) {
      ads.addAll(ads_details);
    }
    if (ads.length > 1) {
      final ids = Set();
      ads.retainWhere((ad) => ids.add(ad.ad_id));
    }
    ads_details = ads;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.ads_details.length > 0) {
      data['ads_details'] = this.ads_details.map((v) => v.toJson()).toList();
    } else {
      data['ads_details'] = [];
    }
    return data;
  }
}

class AdsDetail {
  int ad_id;
  int address_id;
  int category_id;
  int subCategoryId;
  String is_active;
  String item_description;
  String item_name;
  String price;
  int seller_id;
  String pickUpLocation;
  String createDate;
  int numberOfLikes;
  int numberOfViews;
  List<String> images;
  String sellerName;
  int numberOfReviews;
  double averageReview;

  AdsDetail(
      {this.ad_id,
      this.address_id,
      this.category_id,
      this.subCategoryId,
      this.images,
      this.is_active,
      this.item_description,
      this.item_name,
      this.price,
      this.seller_id,
      this.pickUpLocation,
      this.createDate,
      this.numberOfLikes,
      this.numberOfViews,
      this.sellerName,
      this.numberOfReviews,
      this.averageReview});

  factory AdsDetail.fromJson(Map<String, dynamic> json, String currencySymbol) {
    return AdsDetail(
        ad_id: json['ad_id'],
        address_id: json['address_id'],
        category_id: json['category_id'],
        images: json['images'].toString().split('|'),
        is_active: json['is_active'],
        item_description: json['item_description'],
        item_name: json['item_name'],
        price: stringifyPrice(json['price'], currencySymbol),
        seller_id: json['seller_id'],
        pickUpLocation: json['pick_up_location'],
        createDate: json['create_date'].split('T')[0],
        numberOfLikes: json['number_of_likes'],
        numberOfViews: json['number_of_views'],
        sellerName: json['seller_name'] ?? json['username'],
        numberOfReviews: json['number_of_reviews'],
        subCategoryId: json['sub_category_id'] ?? 0,
        averageReview: json['avg_review']);
  }

  factory AdsDetail.fromSavedAds(Map<String, dynamic> json) {
    return AdsDetail(
        ad_id: json['ad_id'],
        address_id: json['address_id'],
        category_id: json['category_id'],
        subCategoryId: json['subCategoryId'],
        images: json['images'].toString().split('|'),
        is_active: json['is_active'],
        item_description: json['item_description'],
        item_name: json['item_name'],
        price: json['price'],
        seller_id: json['seller_id'],
        pickUpLocation: json['pickUpLocation'],
        createDate: json['create_date'],
        numberOfLikes: json['numberOfLikes'],
        numberOfViews: json['numberOfViews'],
        sellerName: json['sellerName'],
        numberOfReviews: json['numberOfReviews'],
        averageReview: json['averageReview']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ad_id'] = this.ad_id;
    data['address_id'] = this.address_id;
    data['category_id'] = this.category_id;
    data['subCategoryId'] = this.subCategoryId;
    data['images'] = this.images.join('|');
    data['is_active'] = this.is_active;
    data['item_description'] = this.item_description;
    data['item_name'] = this.item_name;
    data['price'] = this.price;
    data['seller_id'] = this.seller_id;
    data['pickUpLocation'] = this.pickUpLocation;
    data['create_date'] = this.createDate;
    data['numberOfLikes'] = this.numberOfLikes;
    data['numberOfViews'] = this.numberOfViews;
    data['sellerName'] = this.sellerName;
    data['numberOfReviews'] = this.numberOfReviews;
    data['averageReview'] = this.averageReview;
    return data;
  }

  static String stringifyPrice(double price, String currency) {
    if (price == null) {
      return '$currency 0.00';
    } else {
      final NumberFormat numberCurrencyFormat =
          NumberFormat("#,##0.00", "en_US");
      return currency + ' ' + numberCurrencyFormat.format(price);
    }
  }
}

class Song {
  int duration;
  int songId;
  String author;
  String userName;
  String title;
  String genre;
  int userId;
  String userLang;
  String phoneNumber;
  String email;
  String releaseYear;
  String authorCountry;
  int numberOfPlays;
  int isVerified;
  int numberOfLikes;
  String trackImage;
  String url;
  String savedBy;

  Song(
      {this.duration,
      this.songId,
      this.author,
      this.userName,
      this.title,
      this.genre,
      this.trackImage,
      this.userId,
      this.userLang,
      this.phoneNumber,
      this.email,
      this.releaseYear,
      this.authorCountry,
      this.numberOfPlays,
      this.isVerified,
      this.numberOfLikes,
      this.url,
      this.savedBy});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      duration: json['duration'],
      songId: json['songId'],
      author: json['author'],
      userName: json['userName'],
      genre: json['genre'],
      title: json['title'],
      userId: json['userId'],
      userLang: json['userLang'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      releaseYear: json['releaseYear'],
      authorCountry: json['authorCountry'],
      numberOfPlays: json['numberOfPlays'] ?? 0,
      isVerified: json['isVerified'] ?? 0,
      trackImage: json['trackImage'],
      numberOfLikes: json['numberOfLikes'] ?? 0,
      url: json['url'],
      savedBy: json['savedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['duration'] = duration;
    data['songId'] = songId;
    data['author'] = author;
    data['userName'] = userName;
    data['title'] = title;
    data['genre'] = genre;
    data['userId'] = userId;
    data['userLang'] = userLang;
    data['phoneNumber'] = phoneNumber;
    data['email'] = email;
    data['releaseYear'] = releaseYear;
    data['authorCountry'] = authorCountry;
    data['numberOfPlays'] = numberOfPlays;
    data['isVerified'] = isVerified;
    data['numberOfLikes'] = numberOfLikes;
    data['trackImage'] = trackImage;
    data['url'] = url;
    data['savedBy'] = savedBy;
    return data;
  }
}

class SongList {
  List<Song> songList;

  SongList({this.songList});

  factory SongList.fromSongMapList(List<dynamic> songListMap) {
    if (songListMap.isNotEmpty) {
      songListMap.sort((a, b) => (b['songId']).compareTo(a['songId']));
      return SongList(
          songList: songListMap.map((song) => Song.fromJson(song)).toList());
    } else {
      return SongList(songList: []);
    }
  }

  bool deleteSong(int songId) {
    int s = songList.length;
    songList = songList.where((element) => element.songId != songId).toList();
    return s > songList.length;
  }

  bool addSong(Song newSong) {
    if (songList == null || songList.isEmpty) {
      songList = [newSong];
      return true;
    } else {
      var t = songList.where((song) => song.songId == newSong.songId);
      if (t.isEmpty) {
        songList.add(newSong);
      }
      return t.isEmpty;
    }
  }

  List<dynamic> toJson() {
    //final Map<String, dynamic> data = Map<String, dynamic>();
    if (songList != null && songList.isNotEmpty) {
      return songList.map((song) => song.toJson()).toList();
    }
    return [];
  }
}
