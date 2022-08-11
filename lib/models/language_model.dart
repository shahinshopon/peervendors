class LanguageModel {
  String languageCode;
  String languageName;

  LanguageModel({this.languageCode, this.languageName});

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      languageCode: json['language_code'],
      languageName: json['language_name'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['language_code'] = this.languageCode;
    data['language_name'] = this.languageName;
    return data;
  }
}
