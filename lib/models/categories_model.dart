class CategoriesModel {
  static List<Map<String, dynamic>> categoriesMap = [
    {
      'category_id': 1,
      'category_en': 'Cars, Bikes and Bicycles',
      'category_fr': 'Voitures, Velos et Motos',
      'category_sw': 'Magari, Baiskeli Na Baiskeli',
      'image': 'category_cars_bikes_and_bicycles.jpg'
    },
    {
      'category_id': 2,
      'category_en': 'Electronics And Appliances',
      'category_fr': 'Électronique Et Électroménagers',
      'category_sw': 'Electronics Na Vifaa',
      'image': 'category_electronics_and_appliances.jpg'
    },
    {
      'category_id': 3,
      'category_en': 'Fashion And Beauty',
      'category_fr': 'Mode Et Beauté',
      'category_sw': 'Mitindo Na Uzuri',
      'image': 'category_fashion_and_beauty.jpg'
    },
    {
      'category_id': 4,
      'category_en': 'Land, Housing And Apartments',
      'category_fr': 'Terrains, Logements Et Appartements',
      'category_sw': 'Ardhi, Nyumba Na Magorofa',
      'image': 'category_land_housing_and_apartments.jpg'
    },
    {
      'category_id': 5,
      'category_en': 'Health and Medicine',
      'category_fr': 'Santé et Médecine',
      'category_sw': 'Afya na Dawa',
      'image': 'category_health_and_medecine.jpg'
    },
    {
      'category_id': 6,
      'category_en': 'Education',
      'category_fr': 'Education',
      'category_sw': 'Elimu',
      'image': 'category_education.jpg'
    },
    {
      'category_id': 7,
      'category_en': 'Travel And Tourism',
      'category_fr': 'Voyage Et Tourisme',
      'category_sw': 'Usafiri Na Utalii',
      'image': 'category_travel_and_tourism.jpg'
    },
    {
      'category_id': 8,
      'category_en': 'Careers And Jobs',
      'category_fr': 'Carrières Et Emploi',
      'category_sw': 'Kazi Na Kazi',
      'image': 'category_careers_and_jobs.jpg'
    },
    {
      'category_id': 9,
      'category_en': 'Entertainment And Party',
      'category_fr': 'DJ De Musique, Mcs Et Concerts',
      'category_sw': 'Burudani Na Sherehe',
      'image': 'category_entertainment_and_party.jpg'
    },
    {
      'category_id': 14,
      'category_en': 'Art And Culture',
      'category_fr': 'Art et Culture',
      'category_sw': 'Sanaa na Utamaduni',
      'image': 'category_art_and_culture.jpg'
    },
    {
      'category_id': 10,
      'category_en': 'Technical Work',
      'category_fr': 'Coin Des Techniciens',
      'category_sw': 'Kazi Ya Ufundi',
      'image': 'category_technical_work.jpg'
    },
    {
      'category_id': 11,
      'category_en': 'Charity And Donations',
      'category_fr': 'Charité Et Dons',
      'category_sw': 'Misaada Na Misaada',
      'image': 'category_charity_and_donations.jpg'
    },
    {
      'category_id': 12,
      'category_en': 'Crypto Currency',
      'category_fr': 'Crypto Monnaie',
      'category_sw': 'Fedha Ya Crypto',
      'image': 'category_crypto_currency.jpg'
    },
    {
      'category_id': 13,
      'category_en': 'Agriculture',
      'category_fr': 'Agriculture',
      'category_sw': 'Kilimo',
      'image': 'agriculture.jpg'
    }
  ];

  static List<CategoryData> categories =
      categoriesMap.map((i) => CategoryData.fromJson(i)).toList();
  static String getCategoryName(int index, String lang) {
    return categoriesMap[index]['category_$lang'];
  }
}

class CategoryData {
  String category_en;
  String category_fr;
  String category_sw;
  int category_id;
  String image;

  CategoryData(
      {this.category_en,
      this.category_fr,
      this.category_sw,
      this.category_id,
      this.image});

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      category_en: json['category_en'],
      category_fr: json['category_fr'],
      category_sw: json['category_sw'],
      category_id: json['category_id'],
      image: json['image'],
    );
  }
}
