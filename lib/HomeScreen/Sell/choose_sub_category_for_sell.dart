import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peervendors/HomeScreen/Sell/upload_form.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/categories_model.dart';
import 'package:peervendors/models/sub_categories_model.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/views/product_details.dart';

class SubCategoryForSell extends StatelessWidget {
  final CategoryData categoryData;

  SubCategoryForSell({Key key, @required this.categoryData}) : super(key: key);

  Future<UserModel> getCurrentUser() async {
    var cUP = UserPreferences();
    await cUP.setUserPreferences();
    var currentUser = cUP.getCurrentUser();
    return currentUser;
  }

  @override
  Widget build(BuildContext context) {
    List<SubCategoryData> allSubCategoriesOfChoosenCategory = SubCategoriesModel
        .subCategories
        .where((subCategoryData) =>
            subCategoryData.category_id == categoryData.category_id)
        .toList();
    return FutureBuilder(
        future: getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return SafeArea(
              child: Center(
                  child: Utils.loadingWidget(
                      AppLocalizations.of(context).loadingPleaseWait)),
            );
          } else {
            return Scaffold(
                backgroundColor: Colors.blue[100],
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context).subCategories),
                  centerTitle: true,
                  backgroundColor: Colors.blue,
                  elevation: 0,
                ),
                body: SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ![11, 12, 5].contains(categoryData.category_id)
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                      child: Text(
                                    AppLocalizations.of(context)
                                        .chooseSubCategory,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                        color: Colors.indigo[900]),
                                  )),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount:
                                          allSubCategoriesOfChoosenCategory
                                              .length,
                                      itemBuilder: (context, index) {
                                        return Card(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.only(
                                                    left: 8,
                                                    top: 6,
                                                    bottom: 6,
                                                    right: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            leading: ClipOval(
                                              child:
                                                  allSubCategoriesOfChoosenCategory[
                                                                  index]
                                                              .image !=
                                                          null
                                                      ? Image.asset(
                                                          'assets/subcategories/${allSubCategoriesOfChoosenCategory[index].image}',
                                                          errorBuilder:
                                                              (context, obj,
                                                                  stack) {
                                                            return Image.asset(
                                                              'assets/images/img_product_placeholder.jpg',
                                                              height: SizeConfig
                                                                      .safeBlockVertical *
                                                                  10,
                                                              fit: BoxFit.cover,
                                                            );
                                                          },
                                                          fit: BoxFit.fill,
                                                          height: SizeConfig
                                                                  .safeBlockVertical *
                                                              10,
                                                        )
                                                      : Image.asset(
                                                          'assets/images/img_product_placeholder.jpg',
                                                          fit: BoxFit.cover,
                                                          height: SizeConfig
                                                                  .safeBlockVertical *
                                                              10,
                                                        ),
                                            ),
                                            title: Localizations.localeOf(
                                                            context)
                                                        .languageCode ==
                                                    'en'
                                                ? Text(
                                                    allSubCategoriesOfChoosenCategory[
                                                            index]
                                                        .subcategory_en)
                                                : Localizations.localeOf(
                                                                context)
                                                            .languageCode ==
                                                        'fr'
                                                    ? Text(
                                                        allSubCategoriesOfChoosenCategory[
                                                                index]
                                                            .subcategory_fr)
                                                    : Text(
                                                        allSubCategoriesOfChoosenCategory[
                                                                index]
                                                            .subcategory_sw),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (_) => UploadForm(
                                                    categoryId: categoryData
                                                        .category_id
                                                        .toString(),
                                                    subCategoryId:
                                                        allSubCategoriesOfChoosenCategory[
                                                                index]
                                                            .sub_category_id
                                                            .toString(),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Utils.buildPageSummary(
                                          AppLocalizations.of(context)
                                              .youNeedToContactSupport)),
                                  Utils.buildContactSupportButton(
                                      "support@peervendors.com",
                                      AppLocalizations.of(context).email,
                                      AppLocalizations.of(context).copied,
                                      FontAwesomeIcons.at,
                                      context),
                                  const SizedBox(height: 20),
                                  WhatsAppWidget(
                                      iconData: FontAwesomeIcons.whatsapp,
                                      showMessage: true,
                                      isCustomerSupport: true,
                                      message: AppLocalizations.of(context)
                                          .talkWithSupport,
                                      countryCode: snapshot.data.country_code,
                                      language: snapshot.data.user_lang,
                                      userId: snapshot.data.user_id,
                                      color: Colors.white,
                                      user: snapshot.data,
                                      categoryId: categoryData.category_id),
                                ],
                              )))));
          }
        });
  }
}
