class Subject {
  List<Section> sections;

  Subject({this.sections});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      sections: json['sections'] != null
          ? (json['sections'] as List).map((i) => Section.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.sections != null) {
      data['sections'] = this.sections.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Section {
  List<Topic> topics;
  String heading;

  Section({this.topics, this.heading});

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      topics: json['topics'] != null
          ? (json['topics'] as List).map((i) => Topic.fromJson(i)).toList()
          : null,
      heading: json['heading'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['heading'] = this.heading;
    if (this.topics != null) {
      data['topics'] = this.topics.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Topic {
  String title;
  String content;

  Topic({this.title, this.content});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      content: json['content'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['content'] = this.content;
    data['title'] = this.title;
    return data;
  }
}
