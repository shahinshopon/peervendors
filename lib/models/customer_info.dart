class CustomerInfo {
  int address_id;
  double avg_review;
  String country_code;
  String email;
  String firebase_id;
  int is_verified;
  String last_verification_code;
  int number_of_reviews;
  int number_of_ads;
  String phoneNumber;
  String profile_picture;
  String profile_message;
  int user_id;
  String user_lang;
  String username;

  CustomerInfo(
      {this.address_id,
      this.avg_review,
      this.country_code,
      this.email,
      this.firebase_id,
      this.is_verified,
      this.last_verification_code,
      this.number_of_reviews,
      this.number_of_ads,
      this.phoneNumber,
      this.profile_picture,
      this.profile_message,
      this.user_id,
      this.user_lang,
      this.username});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      address_id: json['address_id'],
      avg_review: json['avg_review'],
      country_code: json['country_code'],
      email: json['email'],
      firebase_id: json['firebase_id'],
      is_verified: json['is_verified'],
      last_verification_code: json['last_verification_code'],
      number_of_reviews: json['number_of_reviews'],
      number_of_ads: json['number_of_ads'],
      phoneNumber: '+' + json['phone_number'].toString().replaceAll('+', ''),
      profile_picture: json['profile_picture'],
      profile_message: json['profile_message'],
      user_id: json['user_id'],
      user_lang: json['user_lang'],
      username: json['username'],
    );
  }
}

class UserModelProfile {
  CustomerInfo customer_info;
  bool this_customer_exists;
  bool was_update_successful;
  List<CustomerReviews> reviews;

  UserModelProfile(
      {this.customer_info,
      this.this_customer_exists,
      this.was_update_successful,
      this.reviews});

  factory UserModelProfile.fromJson(Map<String, dynamic> json) {
    return UserModelProfile(
      customer_info: json['customer_info'] != null
          ? CustomerInfo.fromJson(json['customer_info'])
          : null,
      this_customer_exists: json['this_customer_exists'],
      was_update_successful: json['was_update_successful'],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((i) => CustomerReviews.fromJson(i))
              .toList()
          : [],
    );
  }
}

class CustomerReviews {
  String review_text;
  double review_star;
  String profile_picture;
  String username;
  String review_date;

  CustomerReviews(
      {this.review_text,
      this.review_star,
      this.profile_picture,
      this.username,
      this.review_date});

  factory CustomerReviews.fromJson(Map<String, dynamic> json) {
    String date = json['review_date'];
    date = date.split('T').first;
    return CustomerReviews(
        review_text: json['review_text'],
        review_star: json['review_star'],
        profile_picture: json['profile_picture'],
        username: json['username'],
        review_date: date);
  }
}
