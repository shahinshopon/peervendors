import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/constants.dart';
import 'package:peervendors/helpers/user_preferences.dart';
import 'package:peervendors/HomeScreen/botton_nav_controller.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/user_model.dart';

import 'choose_image.dart';

class UploadForm extends StatefulWidget {
  final String categoryId;
  final String subCategoryId;
  //final Map<String, dynamic> editedAdInfo;
  AdsDetail editedAdInfo;

  UploadForm(
      {Key key,
      @required this.categoryId,
      this.editedAdInfo,
      this.subCategoryId})
      : super(key: key);

  @override
  _UploadFormState createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _titlecontroller = TextEditingController();
  final _descriptioncontroller = TextEditingController();
  final _pickUpLocationController = TextEditingController();
  final _pricecontroller = TextEditingController();
  String _title, _description, _price, _pickUpLocation, currencySymbol;
  UserModel currentUser;
  List<bool> _isSelected = [true, false, false];
  Map<String, dynamic> currentUsersAddress = {};
  UserPreferences cUP = UserPreferences();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setUserPrefs();
  }

  @override
  void dispose() {
    _titlecontroller.dispose();
    _descriptioncontroller.dispose();
    _pickUpLocationController.dispose();
    _pricecontroller.dispose();
    super.dispose();
  }

  Future setUserPrefs() async {
    setState(() {
      isLoading = true;
    });
    if (widget.editedAdInfo != null) {
      _titlecontroller.text = widget.editedAdInfo.item_name;
      _descriptioncontroller.text = widget.editedAdInfo.item_description;
      _pricecontroller.text = widget.editedAdInfo.price
          .toString()
          .split(' ')
          .last
          .replaceAll(',', '');
      _pickUpLocationController.text = widget.editedAdInfo.pickUpLocation;
      _pickUpLocation = widget.editedAdInfo.pickUpLocation;
    } else {
      _pricecontroller.text = '0.0';
    }
    cUP.setUserPreferences().then((value) async {
      Map<String, dynamic> currentAddress = cUP.getCurrentUserAddress();
      if (currentAddress != null) {
        String address =
            "${currentAddress['city']}, ${currentAddress['state']}";
        setState(() {
          currentUsersAddress = currentAddress;
          currentUser = cUP.getCurrentUser();
          _pickUpLocation = address;
          _pickUpLocationController.text = address;
          currencySymbol = '${currentUser.currencySymbol}: ';
          isLoading = false;
        });
      } else {
        currentUser = cUP.getCurrentUser();
        Map<String, dynamic> addressDataMap =
            await ApiRequest.getAddressFromAddressId(params: {
          'address_id': currentUser.address_id.toString(),
          'user_id': currentUser.user_id.toString()
        });
        if (addressDataMap != null && addressDataMap.length > 3) {
          cUP.saveString(
              Constants.peerVendorsCurrentAddress, json.encode(addressDataMap));
          currentUsersAddress = addressDataMap;
        }
        setState(() {
          currentUser = cUP.getCurrentUser();
          currentUsersAddress = addressDataMap;
          _pickUpLocation =
              "${addressDataMap['city']}, ${addressDataMap['state']}";
          _pickUpLocationController.text =
              "${addressDataMap['city']}, ${addressDataMap['state']}";
          currencySymbol = currentUser.currencySymbol;
          isLoading = false;
        });
      }
    });
  }

  OutlineInputBorder buildBoarder({Color color = Colors.blue}) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        color: color,
        width: 1,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(5)),
    );
  }

  InputDecoration inputDecoration(String labelText, {String prefix = ''}) {
    return InputDecoration(
        focusedBorder: buildBoarder(color: Colors.orange),
        errorBorder: buildBoarder(color: Colors.red),
        enabledBorder: buildBoarder(color: Colors.green),
        disabledBorder: buildBoarder(color: Colors.blueGrey),
        border: const UnderlineInputBorder(),
        prefixText: prefix,
        prefixStyle: TextStyle(fontFamily: 'Roboto', fontSize: 16),
        labelText: labelText,
        alignLabelWithHint: true,
        hintStyle: TextStyle(fontSize: 16),
        labelStyle: TextStyle(fontSize: 16),
        errorStyle: TextStyle(fontSize: 11));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue[100],
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).productDetails),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: SafeArea(
          child: isLoading
              ? Utils.loadingWidget(
                  AppLocalizations.of(context).loadingPleaseWait)
              : Card(
                  color: Colors.white,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  AppLocalizations.of(context).sellLocation,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                      color: Colors.indigo[900]),
                                ),
                              ),
                              Utils.buildSeparator(SizeConfig.screenWidth),
                              Container(
                                  height: 85,
                                  alignment: Alignment.center,
                                  child: ToggleButtons(
                                    constraints: BoxConstraints.expand(
                                        height: 50,
                                        width: SizeConfig.screenWidth *
                                            0.9 /
                                            3.21),
                                    borderRadius: BorderRadius.circular(18),
                                    borderWidth: 2,
                                    borderColor: Colors.blue,
                                    selectedBorderColor: Colors.green,
                                    selectedColor: Colors.green,
                                    children: [
                                      Text(AppLocalizations.of(context).myCity),
                                      Text(
                                          AppLocalizations.of(context).myState),
                                      Text(AppLocalizations.of(context)
                                          .myCountry)
                                    ],
                                    isSelected: _isSelected,
                                    onPressed: (int index) {
                                      for (int i = 0;
                                          i < _isSelected.length;
                                          i++) {
                                        _isSelected[i] = i == index;
                                      }
                                      setState(() {});
                                    },
                                  )),
                              const SizedBox(height: 5),
                              SizedBox(
                                  height: 70,
                                  child: TextFormField(
                                    style: TextStyle(fontSize: 18),
                                    controller: _titlecontroller,
                                    maxLength: 50,
                                    //autovalidateMode: AutovalidateMode.always,
                                    textInputAction: TextInputAction.next,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: inputDecoration(
                                        AppLocalizations.of(context).title),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return AppLocalizations.of(context)
                                            .messageIsRequired;
                                      } else if (value.length < 10) {
                                        return AppLocalizations.of(context)
                                            .enterMinimum2Letters
                                            .replaceAll('2', '10');
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _title = value;
                                    },
                                    onChanged: (v) {
                                      if (v.isNotEmpty && v.length == 10) {
                                        setState(() {});
                                      }
                                    },
                                  )),
                              const SizedBox(height: 8),
                              TextFormField(
                                style: TextStyle(fontSize: 18),
                                controller: _descriptioncontroller,
                                //autovalidateMode: AutovalidateMode.always,
                                textInputAction: TextInputAction.next,
                                minLines: 4,
                                maxLines: 7,
                                maxLength: 200,
                                keyboardType: TextInputType.multiline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: inputDecoration(
                                    AppLocalizations.of(context).description),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)
                                        .descriptionIsRequired;
                                  } else if (value.length < 15) {
                                    return AppLocalizations.of(context)
                                        .enterMinimum2Letters
                                        .replaceAll('2', '15');
                                  } else {
                                    return null;
                                  }
                                },
                                onSaved: (value) => _description = value,
                                onChanged: (v) {
                                  if (v.isNotEmpty && v.length == 15) {
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                  height: 70,
                                  child: TextFormField(
                                      style: TextStyle(fontSize: 18),
                                      controller: _pricecontroller,
                                      textInputAction: TextInputAction.done,
                                      minLines: 1,
                                      maxLength: 10,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[.0-9]')),
                                      ],
                                      decoration: inputDecoration(
                                          AppLocalizations.of(context).price,
                                          prefix: currencySymbol),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return AppLocalizations.of(context)
                                              .priceIsRequired;
                                        }
                                        num numb = num.tryParse(value);
                                        if (numb == null || numb < 0) {
                                          return AppLocalizations.of(context)
                                              .priceShouldGreater0;
                                        }
                                        return null;
                                      },
                                      onSaved: (value) => _price = value)),
                              SizedBox(height: 16),
                              SizedBox(
                                  height: 70,
                                  child: TextFormField(
                                    style: TextStyle(fontSize: 18),
                                    controller: _pickUpLocationController,
                                    textInputAction: TextInputAction.done,
                                    maxLines: 1,
                                    keyboardType: TextInputType.streetAddress,
                                    decoration: inputDecoration(
                                        AppLocalizations.of(context).location),
                                    validator: (value) {
                                      if (value.isEmpty || value.length < 3) {
                                        return AppLocalizations.of(context)
                                            .invalid;
                                      }
                                      return null;
                                    },
                                    onSaved: (value) => _pickUpLocation = value,
                                  )),
                              SizedBox(height: 20),
                              Center(
                                child: Utils.customButton(
                                  SizeConfig.screenWidth * 0.75,
                                  widget.editedAdInfo != null
                                      ? AppLocalizations.of(context).submit
                                      : AppLocalizations.of(context)
                                          .continueText,
                                  () async {
                                    if (_formKey.currentState.validate()) {
                                      _formKey.currentState.save();
                                      if (widget.editedAdInfo != null) {
                                        Map<String, String> params = {
                                          "advertisement_option": _isSelected
                                              .indexOf(true)
                                              .toString(),
                                          "ad_id": widget.editedAdInfo.ad_id
                                              .toString(),
                                          "category_id": widget
                                              .editedAdInfo.category_id
                                              .toString(),
                                          'seller_lang':
                                              Localizations.localeOf(context)
                                                  .languageCode,
                                          'price': _price
                                              .split(' ')
                                              .last
                                              .replaceAll(',', ''),
                                          'item_name': _title,
                                          'item_description': _description,
                                          'lat': currentUsersAddress['lat']
                                              .toString(),
                                          'lng': currentUsersAddress['lng']
                                              .toString(),
                                          'pick_up_location': _pickUpLocation
                                        };
                                        ApiRequest.updateAd(params: params);
                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    BottomNavController()));
                                      } else {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) => SelectImagesForAnAd(
                                                advertisementIndex:
                                                    _isSelected.indexOf(true),
                                                categoryId: widget.categoryId,
                                                subCategoryId:
                                                    widget.subCategoryId,
                                                title: _title,
                                                description: _description,
                                                price: _price,
                                                userId: currentUser.user_id,
                                                userLang: currentUser.user_lang,
                                                currentUsersAddress:
                                                    currentUsersAddress,
                                                pickUpLocation: _pickUpLocation,
                                                sellerPhoneNumber:
                                                    currentUser.phoneNumber),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 150)
                            ],
                          )),
                    ),
                  )),
        ));
    //bottomNavigationBar: Utils.buildBottomBar());
  }
}
