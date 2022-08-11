import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:peervendors/models/customer_info.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/views/edit_profile.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:peervendors/helpers/user_preferences.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel currentUser;
  UserPreferences cUP = UserPreferences();
  final bool isEditable;

  @override
  UserProfileState createState() => UserProfileState();
  UserProfilePage(
      {Key key,
      @required this.cUP,
      @required this.currentUser,
      @required this.isEditable})
      : super(key: key);
}

class UserProfileState extends State<UserProfilePage> {
  UserModelProfile userProfile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setUserPrefs();
  }

  Future setUserPrefs() async {
    setState(() {
      isLoading = true;
    });
    ApiRequest.getUserInfo(widget.currentUser.user_id, addReviews: 1)
        .then((profile) {
      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    });
  }

  Widget _buildListOfReviews(BuildContext context) {
    List<CustomerReviews> reviews = userProfile.reviews;
    return reviews.length > 0
        ? SizedBox(
            height: 1200,
            child: ListView.builder(
                primary: false,
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Container(
                          height: 75,
                          width: 70,
                          color: Colors.cyan[100],
                          child: CircleAvatar(
                              backgroundImage: NetworkImage(
                            'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/' +
                                reviews[index].profile_picture,
                          ))),
                      title: Text(
                        '${reviews[index].username}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${reviews[index].review_text}'),
                      trailing: Column(children: [
                        SmoothStarRating(
                          allowHalfRating: true,
                          onRated: (v) {},
                          starCount: 5,
                          rating: reviews[index].review_star,
                          size: 8.0,
                          isReadOnly: true,
                          spacing: 4,
                          defaultIconData: Icons.star_border,
                        ),
                        Text(
                            '${reviews[index].review_star.toStringAsFixed(1)}/5.0'),
                        Text(reviews[index].review_date)
                      ]),
                      isThreeLine: true,
                    ),
                  );
                }))
        : _buildContainerText(
            context, 'You have only 1 system generated review.');
  }

  Widget _buildFullName(String name) {
    return Text(name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(AppLocalizations.of(context).accountMetrics),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: SafeArea(
          child: isLoading
              ? Utils.loadingWidget(
                  AppLocalizations.of(context).loadingPleaseWait)
              : SingleChildScrollView(
                  primary: true,
                  child: Column(
                    children: <Widget>[
                      Utils.buildStack(
                          SizeConfig.screenWidth,
                          SizeConfig.screenHeight,
                          'https://pvendors.s3.eu-west-3.amazonaws.com/profile_pictures/' +
                              widget.currentUser.profilePicture),
                      const SizedBox(height: 10),
                      _buildFullName(
                        userProfile.customer_info.username,
                      ),
                      _buildStatContainer(),
                      _buildBio(context),
                      Utils.buildSeparator(SizeConfig.screenWidth),
                      const SizedBox(height: 10.0),
                      _buildContainerText(context,
                          'Get in Touch with ${widget.currentUser.username.split(" ")[0]},'),
                      const SizedBox(height: 8.0),
                      _buildEditProfile(context),
                      const SizedBox(height: 8.0),
                      Utils.buildSeparator(SizeConfig.screenWidth),
                      _buildFullName(AppLocalizations.of(context).reviews),
                      Utils.buildSeparator(SizeConfig.screenWidth),
                      _buildListOfReviews(context)
                    ],
                  ),
                )),
    );
  }

  Widget _buildProfileStats(String label, String count) {
    TextStyle _statLabelTextStyle = const TextStyle(
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w200,
    );

    TextStyle _statCountTextStyle = const TextStyle(
      color: Colors.black54,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count,
          style: _statCountTextStyle,
        ),
        Text(
          label,
          style: _statLabelTextStyle,
        ),
      ],
    );
  }

  Widget _buildStatContainer() {
    return Container(
      height: 60.0,
      margin: const EdgeInsets.only(top: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF4F7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildProfileStats(AppLocalizations.of(context).adsCreated,
              '${userProfile.customer_info.number_of_ads}'),
          _buildProfileStats(AppLocalizations.of(context).numReviews,
              '${userProfile.customer_info.number_of_reviews}'),
          _buildProfileStats(AppLocalizations.of(context).avgRating,
              '${userProfile.customer_info.avg_review.toStringAsFixed(1)}/5.0'),
        ],
      ),
    );
  }

  Widget _buildBio(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        userProfile.customer_info.profile_message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w400, //try changing weight to w500 if not thin
          fontStyle: FontStyle.italic,
          color: Color(0xFF799497),
          fontSize: 16.0,
        ),
      ),
    );
  }

  Widget _buildContainerText(BuildContext context, String text) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  Widget _buildEditProfile(BuildContext context) {
    return SizedBox(
        height: 35,
        width: 200,
        child: ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfile(
                        currentUser: widget.currentUser,
                        cUP: widget.cUP,
                        intendToAddPhone: false))),
            style: Utils.roundedButtonStyle(radius: 5),
            child: Text(
              AppLocalizations.of(context).editProfile,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            )));
  }
}
