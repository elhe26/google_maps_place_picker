import 'package:flutter/material.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ignore: implementation_imports, unused_import
import 'package:google_maps_place_picker_mb/src/google_map_place_picker.dart'; // do not import this yourself
import 'dart:io' show Platform;

// Your api key storage.
// import 'keys.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Light Theme
  final ThemeData lightTheme = ThemeData.light().copyWith(
    // Background color of the FloatingCard
    cardColor: Colors.white,
  );

  // Dark Theme
  final ThemeData darkTheme = ThemeData.dark().copyWith(
    // Background color of the FloatingCard
    cardColor: Colors.grey,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Map Place Picker Demo',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static final kInitialPosition = LatLng(-33.8567844, 151.213108);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PickResult? selectedPlace;
  bool showPlacePickerInContainer = false;
  bool showGoogleMapInContainer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Google Map Place Picker Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Platform.isAndroid && !showPlacePickerInContainer
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Switch(
                            value:
                                AndroidGoogleMapsFlutter.useAndroidViewSurface,
                            onChanged: (value) {
                              setState(() {
                                showGoogleMapInContainer = false;
                                AndroidGoogleMapsFlutter.useAndroidViewSurface =
                                    value;
                              });
                            }),
                        Text("Use Hybrid Composition"),
                      ],
                    )
                  : Container(),
              !showPlacePickerInContainer
                  ? ElevatedButton(
                      child: Text("Load Place Picker"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return PlacePicker(
                                resizeToAvoidBottomInset:
                                    false, // only works on fullscreen, less flickery
                                apiKey: Platform.isAndroid
                                    ? "APIKeys.androidApiKey"
                                    : "APIKeys.iosApiKey",
                                hintText: "Find a place ...",
                                searchingText: "Please wait ...",
                                selectText: "Select place",
                                outsideOfPickAreaText: "Place not in area",
                                initialPosition: HomePage.kInitialPosition,
                                useCurrentLocation: true,
                                selectInitialPosition: true,
                                usePinPointingSearch: true,
                                usePlaceDetailSearch: true,
                                zoomGesturesEnabled: true,
                                zoomControlsEnabled: true,
                                useDefaultSearchBar: false,
                                //usePlaceDetailSearch: true,
                                onPlacePicked: (result) {
                                  selectedPlace = result;
                                  Navigator.of(context).pop();
                                },
                                customBarWidgetBuilder: ElevatedButton(
                                  child: Text("Press"),
                                  onPressed: () {},
                                ),
                                //forceSearchOnZoomChanged: true,
                                //automaticallyImplyAppBarLeading: false,
                                //autocompleteLanguage: "ko",
                                //region: 'au',
                                //selectInitialPosition: true,
                                selectedPlaceWidgetBuilder:
                                    (_, result, state, isSearchBarFocused) {
                                  print(
                                      "state: $state, isSearchBarFocused: $isSearchBarFocused");
                                  return isSearchBarFocused
                                      ? Container()
                                      : FloatingCard(
                                          bottomPosition:
                                              0.0, // MediaQuery.of(context) will cause rebuild. See MediaQuery document for the information.
                                          leftPosition: 0.0,
                                          rightPosition: 0.0,
                                          width: 500,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          child: state ==
                                                  SearchingState.Searching
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator())
                                              : ElevatedButton(
                                                  child: Text("Pick Here"),
                                                  onPressed: () {
                                                    // IMPORTANT: You MUST manage selectedPlace data yourself as using this build will not invoke onPlacePicker as
                                                    //            this will override default 'Select here' Button.
                                                    setState(() {
                                                      selectedPlace = result;
                                                    });

                                                    print(
                                                        "do something with [${selectedPlace?.geometry ?? 0}] data");
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                        );
                                },
                                pinBuilder: (context, state) {
                                  if (state == PinState.Idle) {
                                    return Icon(Icons.favorite_border);
                                  } else {
                                    return Icon(Icons.favorite);
                                  }
                                },
                                onTapBack: () {
                                  setState(() {
                                    showPlacePickerInContainer = false;
                                  });
                                });
                          }),
                          // selectedPlace == null
                          //     ? Container()
                          //     : Text(selectedPlace?.formattedAddress),
                          // selectedPlace == null
                          //     ? Container()
                          //     : Text("(lat: " +
                          //         selectedPlace!.geometry!.location.lat
                          //             .toString() +
                          //         ", lng: " +
                          //         selectedPlace!.geometry!.location.lng
                          //             .toString() +
                          //         ")"),
                          // #region Google Map Example without provider
                          // showPlacePickerInContainer
                          //     ? Container()
                          //     : ElevatedButton(
                          //         child: Text("Toggle Google Map w/o Provider"),
                          //         onPressed: () {
                          //           setState(() {
                          //             showGoogleMapInContainer =
                          //                 !showGoogleMapInContainer;
                          //           });
                          //         },
                          //       ),
                          // !showGoogleMapInContainer
                          //     ? Container()
                          //     : Container(
                          //         width:
                          //             MediaQuery.of(context).size.width * 0.75,
                          //         height:
                          //             MediaQuery.of(context).size.height * 0.25,
                          //         child: GoogleMap(
                          //           zoomGesturesEnabled: false,
                          //           zoomControlsEnabled: false,
                          //           myLocationButtonEnabled: false,
                          //           compassEnabled: false,
                          //           mapToolbarEnabled: false,
                          //           initialCameraPosition: new CameraPosition(
                          //               target: HomePage.kInitialPosition,
                          //               zoom: 15),
                          //           mapType: MapType.normal,
                          //           myLocationEnabled: true,
                          //           onMapCreated:
                          //               (GoogleMapController controller) {},
                          //           onCameraIdle: () {},
                          //           onCameraMoveStarted: () {},
                          //           onCameraMove: (CameraPosition position) {},
                          //         )),
                        );
                      },
                    )
                  : selectedPlace == null
                      ? Container()
                      : Text(selectedPlace?.formattedAddress ?? ""),
            ],
          ),
        ));
  }
}
