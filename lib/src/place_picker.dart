import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:google_maps_place_picker_mb/providers/place_provider.dart';
import 'package:google_maps_place_picker_mb/src/autocomplete_search.dart';
import 'package:google_maps_place_picker_mb/src/controllers/autocomplete_search_controller.dart';
import 'package:google_maps_place_picker_mb/src/google_map_place_picker.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import 'package:uuid/uuid.dart';

typedef IntroModalWidgetBuilder = Widget Function(
  BuildContext context,
  Function? close,
);

enum PinState { Preparing, Idle, Dragging }

enum SearchingState { Idle, Searching }

class PlacePicker extends StatefulWidget {
  PlacePicker({
    Key? key,
    required this.apiKey,
    this.onPlacePicked,
    required this.initialPosition,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    this.selectText,
    this.outsideOfPickAreaText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.introModalWidgetBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.pickArea,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceAndroidLocationManager = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.useCameraLocationAsCoordinates = false,
    this.myLocationEnabled: true,
    this.myLocationButtonEnabled: true,
    this.zoomControlsEnabled: true,
    this.zoomGesturesEnabled: true,
    this.mapToolbarEnabled: true,
    this.buildingsEnabled: true,
    this.trafficEnabled: true,
    this.rotateGesturesEnabled: true,
    this.tiltGesturesEnabled: true,
    this.indoorViewEnabled: true,
    this.compassEnabled: true,
    this.scrollGesturesEnabled: true,
    this.activateMapIcons: true,
    this.mapStyle,
    this.customBarWidgetBuilder,
    this.useDefaultSearchBar: true,
    this.iconPlaceColor: Colors.red,
    this.iconPointerColor: Colors.black,
    this.mapTypeColor: Colors.black,
    this.myLocationColor: Colors.black, 
    this.mapToolSeparation: 10, 
    this.mapToolRight:15,
    this.onTapBack,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onMapTypeChanged,
  }) : super(key: key);

  final String apiKey;

  final LatLng initialPosition;
  final bool? useCurrentLocation;
  final LocationAccuracy desiredLocationAccuracy;

  final String? hintText;
  final String? searchingText;
  final String? selectText;
  final String? outsideOfPickAreaText;

  final ValueChanged<String>? onAutoCompleteFailed;
  final ValueChanged<String>? onGeocodingSearchFailed;
  final int autoCompleteDebounceInMilliseconds;
  final int cameraMoveDebounceInMilliseconds;

  final MapType initialMapType;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;
  final int myLocationButtonCooldown;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;

  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;

  /// Visualize Default Map Icon widgets
  final bool activateMapIcons;

  /// Google Maps Configuration
  final bool? myLocationEnabled;

  /// Google Maps Configuration
  final bool? myLocationButtonEnabled;

  /// Google Maps Configuration
  final bool? mapToolbarEnabled;

  /// Google Maps Configuration
  final bool? buildingsEnabled;

  /// Google Maps Configuration
  final bool? trafficEnabled;

  /// Google Maps Configuration
  final bool? rotateGesturesEnabled;

  /// Google Maps Configuration
  final bool? tiltGesturesEnabled;

  /// Google Maps Configuration
  final bool? indoorViewEnabled;

  /// Google Maps Configuration
  final bool? compassEnabled;

  /// Google Maps Configuration
  final bool? scrollGesturesEnabled;

  /// Google Maps Configuration
  final String? mapStyle;
  /// If set the picker can only pick addresses in the given circle area.
  /// The section will be highlighted.
  final CircleArea? pickArea;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResult>? onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// IMPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - builds customized introduction panel.
  ///
  /// None is provided / the map is instantly accessible if you leave it as a null.
  final IntroModalWidgetBuilder? introModalWidgetBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// On Android devices you can set [forceAndroidLocationManager]
  /// to true to force the plugin to use the [LocationManager] to determine the
  /// position instead of the [FusedLocationProviderClient]. On iOS this is ignored.
  final bool forceAndroidLocationManager;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Whether to display appbar backbutton. Defaults to true.
  final bool automaticallyImplyAppBarLeading;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  final bool hidePlaceDetailsWhenDraggingPin;

  final bool useCameraLocationAsCoordinates;
  // Raised when clicking on the back arrow.
  // This will not listen for the system back button on Android devices.
  // If this is not set, but the back button is visible through automaticallyImplyLeading,
  // the Navigator will try to pop instead.
  final VoidCallback? onTapBack;

  /// GoogleMap pass-through events:

  /// Callback method for when the map is ready to be used.
  ///
  /// Used to receive a [GoogleMapController] for this [GoogleMap].
  final MapCreatedCallback? onMapCreated;

  /// Called when the camera starts moving.
  ///
  /// This can be initiated by the following:
  /// 1. Non-gesture animation initiated in response to user actions.
  ///    For example: zoom buttons, my location button, or marker clicks.
  /// 2. Programmatically initiated animation.
  /// 3. Camera motion initiated in response to user gestures on the map.
  ///    For example: pan, tilt, pinch to zoom, or rotate.
  final Function(PlaceProvider)? onCameraMoveStarted;

  /// Called repeatedly as the camera continues to move after an
  /// onCameraMoveStarted call.
  ///
  /// This may be called as often as once every frame and should
  /// not perform expensive operations.
  final CameraPositionCallback? onCameraMove;

  /// Called when camera movement has ended, there are no pending
  /// animations and the user has stopped interacting with the map.
  final Function(PlaceProvider)? onCameraIdle;

  /// Called when the map type has been changed.
  final Function(MapType)? onMapTypeChanged;

  /// Allow user to make visible the zoom button & toggle on & off zoom gestures
  final bool zoomGesturesEnabled;
  final bool zoomControlsEnabled;

  /// This will build a custom bar instead of the default search bar
  final Widget? customBarWidgetBuilder;

  /// This will activate/deactivate the search bar to use the customBarWidgetBuilder
  final bool useDefaultSearchBar;

  /// This will change color  of Icon Place
  final Color iconPlaceColor;

  /// This will change color  of Pointer
  final Color iconPointerColor;

  /// This will change color  of layer button
  final Color mapTypeColor;

  /// This will change color  of location button
  final Color myLocationColor;

  /// This will change the height of separation between layer and location buttons
  final double? mapToolSeparation;

  /// This will change right separation from  view
  final double? mapToolRight;

  @override
  _PlacePickerState createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  GlobalKey appBarKey = GlobalKey();
  late final Future<PlaceProvider> _futureProvider;
  PlaceProvider? provider;
  SearchBarController searchBarController = SearchBarController();
  bool showIntroModal = true;

  @override
  void initState() {
    super.initState();

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    if (widget.useDefaultSearchBar) {
      searchBarController.dispose();
    }

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = Uuid().v4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);
    if (widget.useCurrentLocation != null && widget.useCurrentLocation!) {
      await provider.updateCurrentLocation(widget.forceAndroidLocationManager);
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (value) async {
        searchBarController.clearOverlay();
        return Future.value(value);
      },
      child: FutureBuilder<PlaceProvider>(
        future: _futureProvider,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
            provider = snapshot.data;

            return MultiProvider(
              providers: [
                ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
              ],
              child: Stack(children: [
                Scaffold(
                key: ValueKey<int>(provider.hashCode),
                resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  key: appBarKey,
                  automaticallyImplyLeading: false,
                  iconTheme: Theme.of(context).iconTheme,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  titleSpacing: 0.0,
                  
                  title: widget.useDefaultSearchBar
                      ? _buildSearchBar(context)
                      : widget.customBarWidgetBuilder,
                ),
                body: _buildMapWithLocation(),
              ),
            _buildIntroModal(context),
              ],),);
          }


          final children = <Widget>[];
          if (snapshot.hasError) {
            children.addAll([
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ]);
          } else {
            children.add(CircularProgressIndicator());
          }
          
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            );
          },
        ));
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: <Widget>[
        widget.automaticallyImplyAppBarLeading || widget.onTapBack != null
            ? IconButton(
                onPressed: () {
                  if (!showIntroModal ||
                      widget.introModalWidgetBuilder == null) {
                    if (widget.onTapBack != null) {
                      widget.onTapBack!();
                      return;
                    }
                    Navigator.maybePop(context);
                  }
                },
                icon: Icon(
                  Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                ),
                color: Colors.black.withAlpha(128),
                padding: EdgeInsets.zero)
            : SizedBox(width: 15),
        Expanded(
          child: AutoCompleteSearch(
              appBarKey: appBarKey,
              searchBarController: searchBarController,
              sessionToken: provider!.sessionToken,
              hintText: widget.hintText,
              searchingText: widget.searchingText,
              debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
              onPicked: (prediction) {
                _pickPrediction(prediction);
              },
              onSearchFailed: (status) {
                if (widget.onAutoCompleteFailed != null) {
                  widget.onAutoCompleteFailed!(status);
                }
              },
              autocompleteOffset: widget.autocompleteOffset,
              autocompleteRadius: widget.autocompleteRadius,
              autocompleteLanguage: widget.autocompleteLanguage,
              autocompleteComponents: widget.autocompleteComponents,
              autocompleteTypes: widget.autocompleteTypes,
              strictbounds: widget.strictbounds,
              region: widget.region,
              initialSearchString: widget.initialSearchString,
              searchForInitialValue: widget.searchForInitialValue,
              autocompleteOnTrailingWhitespace:
                  widget.autocompleteOnTrailingWhitespace),
        ),
        SizedBox(width: 5),
      ],
    );
  }

  _pickPrediction(Prediction prediction) async {
    provider!.placeSearchingState = SearchingState.Searching;

    final PlacesDetailsResponse response =
        await provider!.places.getDetailsByPlaceId(
      prediction.placeId!,
      sessionToken: provider!.sessionToken,
      language: widget.autocompleteLanguage,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      if (widget.onAutoCompleteFailed != null) {
        widget.onAutoCompleteFailed!(response.status);
      }
      return;
    }

    provider!.selectedPlace = PickResult.fromPlaceDetailResult(response.result);

    // Prevents searching again by camera movement.
    provider!.isAutoCompleteSearching = true;

    await _moveTo(provider!.selectedPlace!.geometry!.location.lat,
        provider!.selectedPlace!.geometry!.location.lng);

    provider!.placeSearchingState = SearchingState.Idle;
  }

  _moveTo(double latitude, double longitude) async {
    GoogleMapController? controller = provider!.mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16,
        ),
      ),
    );
  }

  _moveToCurrentPosition() async {
    if (provider!.currentPosition != null) {
      await _moveTo(provider!.currentPosition!.latitude,
          provider!.currentPosition!.longitude);
    }
  }

  Widget _buildMapWithLocation() {
    if (widget.useCurrentLocation!) {
      return FutureBuilder(
          future: provider!
              .updateCurrentLocation(widget.forceAndroidLocationManager),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              if (provider!.currentPosition == null) {
                return _buildMap(widget.initialPosition);
              } else {
                return _buildMap(LatLng(provider!.currentPosition!.latitude,
                    provider!.currentPosition!.longitude));
              }
            }
          });
    } else {
      return FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 1)),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _buildMap(widget.initialPosition);
          }
        },
      );
    }
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapPlacePicker(
      fullMotion: !widget.resizeToAvoidBottomInset,
      initialTarget: initialTarget,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      pickArea: widget.pickArea,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      mapToolbarEnabled: widget.mapToolbarEnabled,
      buildingsEnabled: widget.buildingsEnabled,
      trafficEnabled: widget.trafficEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      indoorViewEnabled: widget.indoorViewEnabled,
      compassEnabled: widget.compassEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      mapStyle: widget.mapStyle,
      activateMapIcons: widget.activateMapIcons,
      useDefaultSearchBar: widget.useDefaultSearchBar,
      iconPlaceColor: widget.iconPlaceColor,
      iconPointerColor: widget.iconPointerColor,
      mapTypeColor: widget.mapTypeColor,
      myLocationColor: widget.myLocationColor,
      customBarWidgetBuilder: widget.customBarWidgetBuilder,
      mapToolSeparation: widget.mapToolSeparation,
      mapToolRight: widget.mapToolRight,
      selectText: widget.selectText,
      outsideOfPickAreaText: widget.outsideOfPickAreaText,
      onToggleMapType: () {
        provider!.switchMapType();
        if (widget.onMapTypeChanged != null) {
          widget.onMapTypeChanged!(provider!.mapType);
        }
      },
      onMyLocation: () async {
        // Prevent to click many times in short period.
        if (provider!.isOnUpdateLocationCooldown == false) {
          provider!.isOnUpdateLocationCooldown = true;
          Timer(Duration(seconds: widget.myLocationButtonCooldown), () {
            provider!.isOnUpdateLocationCooldown = false;
          });
          await provider!
              .updateCurrentLocation(widget.forceAndroidLocationManager);
          await _moveToCurrentPosition();
        }
      },
      onMoveStart: () {
        if (widget.useDefaultSearchBar) {
          searchBarController.reset();
        }
      },
      onPlacePicked: widget.onPlacePicked,
      useCameraLocationAsCoordinates: widget.useCameraLocationAsCoordinates,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
    );
  }

  Widget _buildIntroModal(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return showIntroModal && widget.introModalWidgetBuilder != null
          ? Stack(children: [
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Material(
                  type: MaterialType.canvas,
                  color: Color.fromARGB(128, 0, 0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: ClipRect(),
                ),
              ),
              widget.introModalWidgetBuilder!(context, () {
                setState(() {
                  showIntroModal = false;
                });
              })
            ])
          : Container();
    });
  }
}
