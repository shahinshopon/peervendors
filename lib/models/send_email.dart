class SendEmail {
  int insertId;
  String message;
  String status;
  bool wasInsertSuccessfull;

  SendEmail(
      {this.insertId, this.message, this.status, this.wasInsertSuccessfull});

  factory SendEmail.fromJson(Map<String, dynamic> json) {
    return SendEmail(
      insertId: json['insert_id'],
      message: json['message'],
      status: json['status'],
      wasInsertSuccessfull: json['was_insert_successfull'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['insert_id'] = this.insertId;
    data['message'] = this.message;
    data['status'] = this.status;
    data['was_insert_successfull'] = this.wasInsertSuccessfull;
    return data;
  }
}

class ReviewData {
  int adId;
  int reviewId;
  double reviewStar;
  String reviewText;
  int reviewerId;

  ReviewData(
      {this.adId,
      this.reviewId,
      this.reviewStar,
      this.reviewText,
      this.reviewerId});

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> reviewData = json['review_data'];
    return reviewData == null
        ? null
        : ReviewData(
            adId: reviewData['ad_id'],
            reviewId: reviewData['review_id'],
            reviewStar: reviewData['review_star'],
            reviewText: reviewData['review_text'],
            reviewerId: reviewData['reviewer_id']);
  }
}
