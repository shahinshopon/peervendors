class ProductDetailsModel {
  AdDetails ad_details;
  ProductDetailsModel({this.ad_details});

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailsModel(
      ad_details: json['ad_details'] != null
          ? AdDetails.fromJson(json['ad_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.ad_details != null) {
      data['ad_details'] = this.ad_details.toJson();
    }
    return data;
  }
}

class AdDetails {
  int ad_id;
  int address_id;
  double avg_review;
  int category_id;
  String is_active;
  String item_description;
  String item_name;
  int number_of_reviews;
  int numberOfLikes;
  int numberOfViews;
  double price;
  int seller_id;
  String username;
  String firebaseId;
  String pickUpLocation;
  String createDate;
  List<dynamic> images;

  AdDetails(
      {this.ad_id,
      this.address_id,
      this.avg_review,
      this.category_id,
      this.images,
      this.is_active,
      this.item_description,
      this.item_name,
      this.number_of_reviews,
      this.price,
      this.seller_id,
      this.username,
      this.firebaseId,
      this.pickUpLocation,
      this.createDate,
      this.numberOfLikes,
      this.numberOfViews});

  factory AdDetails.fromJson(Map<String, dynamic> json) {
    return AdDetails(
        ad_id: json['ad_id'],
        address_id: json['address_id'],
        avg_review: json['avg_review'],
        category_id: json['category_id'],
        is_active: json['is_active'],
        item_description: json['item_description'],
        item_name: json['item_name'],
        number_of_reviews: json['number_of_reviews'],
        price: json['price'],
        seller_id: json['seller_id'],
        username: json['username'],
        firebaseId: json['firebase_id'],
        pickUpLocation: json['pick_up_location'],
        createDate: json['create_date'].split('T')[0],
        numberOfLikes: json['number_of_likes'],
        numberOfViews: json['number_of_views'],
        images: json['images'].toString().split('|'));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ad_id'] = this.ad_id;
    data['address_id'] = this.address_id;
    data['avg_review'] = this.avg_review;
    data['category_id'] = this.category_id;
    data['images'] = this.images.join('|');
    data['is_active'] = this.is_active;
    data['item_description'] = this.item_description;
    data['item_name'] = this.item_name;
    data['number_of_reviews'] = this.number_of_reviews;
    data['price'] = this.price;
    data['seller_id'] = this.seller_id;
    data['username'] = this.username;
    data['firebase_id'] = this.firebaseId;
    data['pick_up_location'] = this.pickUpLocation;
    data['number_of_likes'] = this.numberOfLikes;
    data['number_of_views'] = this.numberOfViews;
    return data;
  }
}
