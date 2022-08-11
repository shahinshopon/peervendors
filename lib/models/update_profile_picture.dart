class UpdateProfilePicture {
  String profile_picture;
  int user_id;
  bool was_update_successful;

  UpdateProfilePicture(
      {this.profile_picture, this.user_id, this.was_update_successful});

  factory UpdateProfilePicture.fromJson(Map<String, dynamic> json) {
    return UpdateProfilePicture(
      profile_picture: json['profile_picture'],
      user_id: json['user_id'],
      was_update_successful: json['was_update_successful'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['profile_picture'] = this.profile_picture;
    data['user_id'] = this.user_id;
    data['was_update_successful'] = this.was_update_successful;
    return data;
  }
}
