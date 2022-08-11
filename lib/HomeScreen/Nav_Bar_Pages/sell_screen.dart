import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/HomeScreen/Sell/choose_sub_category_for_sell.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/models/categories_model.dart';

class SellScreen extends StatefulWidget {
  SellScreen({
    Key key,
  }) : super(key: key);

  @override
  SellScreenState createState() {
    return SellScreenState();
  }
}

class SellScreenState extends State<SellScreen> {
  final List<CategoryData> allCategories = CategoriesModel.categories;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue[100],
        appBar: AppBar(
          leading: const SizedBox.shrink(),
          title: Text(AppLocalizations.of(context).sell),
          centerTitle: true,
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Text(
                      AppLocalizations.of(context).chooseACategory,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: Colors.blue[900]),
                      textAlign: TextAlign.center,
                    )),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allCategories.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.only(
                                  left: 8, top: 6, bottom: 6, right: 8),
                              leading: ClipOval(
                                child: allCategories[index].image != null
                                    ? Image.asset(
                                        'assets/categories/${allCategories[index].image}',
                                        errorBuilder: (context, obj, stack) {
                                          return Image.asset(
                                            'assets/images/img_product_placeholder.jpg',
                                            fit: BoxFit.cover,
                                            height:
                                                SizeConfig.safeBlockVertical *
                                                    10,
                                          );
                                        },
                                        fit: BoxFit.fill,
                                        height:
                                            SizeConfig.safeBlockVertical * 10,
                                      )
                                    : Image.asset(
                                        'assets/images/img_product_placeholder.jpg',
                                        height:
                                            SizeConfig.safeBlockVertical * 10,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              title: Text(CategoriesModel.getCategoryName(
                                  index,
                                  Localizations.localeOf(context)
                                      .languageCode)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (_) => SubCategoryForSell(
                                          categoryData: allCategories[index])),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ))));
  }
}
