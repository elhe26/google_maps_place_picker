import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:google_maps_place_picker_mb/providers/place_provider.dart';
import 'package:google_maps_place_picker_mb/src/components/animated_pin.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

typedef SelectedPlaceWidgetBuilder = Widget Function(
  BuildContext context,
  PickResult? selectedPlace,
  SearchingState state,
  bool isSearchBarFocused,
);

typedef PinBuilder = Widget Function(
  BuildContext context,
  PinState state,
);

class GoogleMapPlacePicker extends StatelessWidget {
  const GoogleMapPlacePicker({
    Key? key,
    required this.initialTarget,
    required this.appBarKey,
    this.activateMapIcons: true,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.pickArea,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.useCameraLocationAsCoordinates,
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
    this.mapStyle,
    this.customBarWidgetBuilder,
    this.useDefaultSearchBar: true,
    this.iconPlaceColor,
    this.iconPointerColor,
    this.mapTypeColor,
    this.myLocationColor,
    this.mapToolSeparation,
    this.mapToolRight,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.selectText,
    this.outsideOfPickAreaText,
    this.fullMotion = false,
  }) : super(key: key);

  final LatLng initialTarget;
  final GlobalKey appBarKey;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResult>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool? usePinPointingSearch;
  final bool? usePlaceDetailSearch;

  final bool? selectInitialPosition;

  final String? language;
  final CircleArea? pickArea;

  final bool? forceSearchOnZoomChanged;
  final bool? hidePlaceDetailsWhenDraggingPin;

  final bool? useCameraLocationAsCoordinates;

  // Google Maps Configuration
  final bool? myLocationEnabled;
  final bool? myLocationButtonEnabled;
  final bool? mapToolbarEnabled;
  final bool? buildingsEnabled;
  final bool? trafficEnabled;
  final bool? rotateGesturesEnabled;
  final bool? tiltGesturesEnabled;
  final bool? indoorViewEnabled;
  final bool? compassEnabled;
  final bool? scrollGesturesEnabled;
  final String? mapStyle;

  final bool? activateMapIcons;

  final Widget? customBarWidgetBuilder;

  final bool? useDefaultSearchBar;

  final Color? iconPlaceColor;

  final Color? iconPointerColor;

  final Color? mapTypeColor;

  final Color? myLocationColor;

  final double? mapToolSeparation;

  final double? mapToolRight;

  /// GoogleMap pass-through events:
  final Function(PlaceProvider)? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final Function(PlaceProvider)? onCameraIdle;

  // strings
  final String? selectText;
  final String? outsideOfPickAreaText;

  /// Zoom feature toggle
  final bool zoomGesturesEnabled;
  final bool zoomControlsEnabled;

  /// Use never scrollable scroll-view with maximum dimensions to prevent unnecessary re-rendering.
  final bool fullMotion;

  _searchByCameraLocation(PlaceProvider provider) async {
    // We don't want to search location again if camera location is changed by zooming in/out.

    // ? Check if zoom has changed
    // bool hasZoomChanged = provider.cameraPosition != null &&
    //     provider.prevCameraPosition != null &&
    //     provider.cameraPosition!.zoom != provider.prevCameraPosition!.zoom;

    if (forceSearchOnZoomChanged == false &&
        provider.prevCameraPosition != null &&
        provider.prevCameraPosition!.target.latitude ==
            provider.cameraPosition!.target.latitude &&
        provider.prevCameraPosition!.target.longitude ==
            provider.cameraPosition!.target.longitude) {
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    provider.placeSearchingState = SearchingState.Searching;

    final GeocodingResponse response =
        await provider.geocoding.searchByLocation(
      Location(
          lat: provider.cameraPosition!.target.latitude,
          lng: provider.cameraPosition!.target.longitude),
      language: language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      print("Camera Location Search Error: " + response.errorMessage!);
      if (onSearchFailed != null) {
        onSearchFailed!(response.status);
      }
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    if (usePlaceDetailSearch!) {
      final PlacesDetailsResponse detailResponse =
          await provider.places.getDetailsByPlaceId(
        response.results[0].placeId,
        language: language,
      );

      if (detailResponse.errorMessage?.isNotEmpty == true ||
          detailResponse.status == "REQUEST_DENIED") {
        print("Fetching details by placeId Error: " +
            detailResponse.errorMessage!);
        if (onSearchFailed != null) {
          onSearchFailed!(detailResponse.status);
        }
        provider.placeSearchingState = SearchingState.Idle;
        return;
      }

      provider.selectedPlace =
          PickResult.fromPlaceDetailResult(detailResponse.result);
    } else {
      provider.selectedPlace =
          PickResult.fromGeocodingResult(response.results[0]);
    }

    if (useCameraLocationAsCoordinates!) {
      if (provider.selectedPlace != null) {
        Geometry geometry = Geometry(
            location: Location(
                lat: provider.cameraPosition!.target.latitude,
                lng: provider.cameraPosition!.target.longitude));
        PickResult pickResult = PickResult(
            placeId: provider.selectedPlace!.placeId,
            geometry: geometry,
            formattedAddress: provider.selectedPlace!.formattedAddress,
            types: provider.selectedPlace!.types,
            addressComponents: provider.selectedPlace!.addressComponents);
        provider.selectedPlace = pickResult;
        print(provider.selectedPlace!.geometry);
      }
    }

    provider.placeSearchingState = SearchingState.Idle;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (this.fullMotion)
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  _buildGoogleMap(
                    context,
                    myLocationEnabled!,
                    myLocationButtonEnabled!,
                    zoomControlsEnabled,
                    zoomGesturesEnabled,
                    mapToolbarEnabled!,
                    buildingsEnabled!,
                    trafficEnabled!,
                    rotateGesturesEnabled!,
                    tiltGesturesEnabled!,
                    indoorViewEnabled!,
                    compassEnabled!,
                    scrollGesturesEnabled!,
                    mapStyle,
                  ),
                  _buildPin(iconPlaceColor!, iconPointerColor!),
                  _buildFloatingCard(),
                  if (activateMapIcons ?? true) _buildMapIcons(context),
                ],
              ),
            ),
          ),
        if (!this.fullMotion)
          _buildGoogleMap(
            context,
            myLocationEnabled!,
            myLocationButtonEnabled!,
            zoomControlsEnabled,
            zoomGesturesEnabled,
            mapToolbarEnabled!,
            buildingsEnabled!,
            trafficEnabled!,
            rotateGesturesEnabled!,
            tiltGesturesEnabled!,
            indoorViewEnabled!,
            compassEnabled!,
            scrollGesturesEnabled!,
            mapStyle,
          ),
        if (!this.fullMotion) _buildPin(iconPlaceColor!, iconPointerColor!),
        _buildFloatingCard(),
        _buildMapIcons(context),
        _buildZoomButtons()
      ],
    );
  }

  Widget _buildGoogleMapInner(PlaceProvider? provider, MapType mapType) {
    CameraPosition initialCameraPosition =
        CameraPosition(target: this.initialTarget, zoom: 15);
    return GoogleMap(
      zoomGesturesEnabled: this.zoomGesturesEnabled,
      zoomControlsEnabled:
          false, // we use our own implementation that supports iOS as well, see _buildZoomButtons()
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      initialCameraPosition: initialCameraPosition,
      mapType: mapType,
      myLocationEnabled: true,
      circles: pickArea != null && pickArea!.radius > 0
          ? Set<Circle>.from([pickArea])
          : Set<Circle>(),
      onMapCreated: (GoogleMapController controller) {
        if (provider == null) return;
        provider.mapController = controller;
        provider.setCameraPosition(null);
        provider.pinState = PinState.Idle;

        // When select initialPosition set to true.
        if (selectInitialPosition!) {
          provider.setCameraPosition(initialCameraPosition);
          _searchByCameraLocation(provider);
        }

        if (onMapCreated != null) {
          onMapCreated!(controller);
        }
      },
      onCameraIdle: () {
        if (provider == null) return;
        if (provider.isAutoCompleteSearching) {
          provider.isAutoCompleteSearching = false;
          provider.pinState = PinState.Idle;
          provider.placeSearchingState = SearchingState.Idle;
          return;
        }

        // Perform search only if the setting is to true.
        if (usePinPointingSearch!) {
          // Search current camera location only if camera has moved (dragged) before.
          if (provider.pinState == PinState.Dragging) {
            // Cancel previous timer.
            if (provider.debounceTimer?.isActive ?? false) {
              provider.debounceTimer!.cancel();
            }
            provider.debounceTimer =
                Timer(Duration(milliseconds: debounceMilliseconds!), () {
              _searchByCameraLocation(provider);
            });
          }
        }

        provider.pinState = PinState.Idle;

        if (onCameraIdle != null) {
          onCameraIdle!(provider);
        }
      },
      onCameraMoveStarted: () {
        if (provider == null) return;
        if (onCameraMoveStarted != null) {
          onCameraMoveStarted!(provider);
        }

        provider.setPrevCameraPosition(provider.cameraPosition);

        // Cancel any other timer.
        provider.debounceTimer?.cancel();

        // Update state, dismiss keyboard and clear text.
        provider.pinState = PinState.Dragging;

        // Begins the search state if the hide details is enabled
        if (this.hidePlaceDetailsWhenDraggingPin!) {
          provider.placeSearchingState = SearchingState.Searching;
        }

        onMoveStart!();
      },
      onCameraMove: (CameraPosition position) {
        if (provider == null) return;
        provider.setCameraPosition(position);
        if (onCameraMove != null) {
          onCameraMove!(position);
        }
      },
      // gestureRecognizers make it possible to navigate the map when it's a
      // child in a scroll view e.g ListView, SingleChildScrollView...
      gestureRecognizers: Set()
        ..add(Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer())),
    );
  }

  Widget _buildGoogleMap(
    BuildContext context,
    bool myLocationEnabled,
    bool myLocationButtonEnabled,
    bool zoomControlsEnabled,
    bool zoomGesturesEnabled,
    bool mapToolbarEnabled,
    bool buildingsEnabled,
    bool trafficEnabled,
    bool rotateGesturesEnabled,
    bool tiltGesturesEnabled,
    bool indoorViewEnabled,
    bool compassEnabled,
    bool scrollGesturesEnabled,
    String? mapStyle,
  ) {
    return Selector<PlaceProvider, MapType>(
        selector: (_, provider) => provider.mapType,
        builder: (_, data, __) {
          PlaceProvider provider = PlaceProvider.of(context, listen: false);
          CameraPosition initialCameraPosition =
              CameraPosition(target: initialTarget, zoom: 15);

          return GoogleMap(
            initialCameraPosition: initialCameraPosition,
            mapType: data,
            myLocationEnabled: myLocationEnabled,
            myLocationButtonEnabled: myLocationButtonEnabled,
            zoomControlsEnabled: zoomControlsEnabled,
            zoomGesturesEnabled: zoomGesturesEnabled,
            mapToolbarEnabled: mapToolbarEnabled,
            buildingsEnabled: buildingsEnabled,
            trafficEnabled: trafficEnabled,
            rotateGesturesEnabled: rotateGesturesEnabled,
            tiltGesturesEnabled: tiltGesturesEnabled,
            indoorViewEnabled: indoorViewEnabled,
            compassEnabled: compassEnabled,
            scrollGesturesEnabled: scrollGesturesEnabled,

            onMapCreated: (GoogleMapController controller) async {
              provider.mapController = controller;
              provider.setCameraPosition(null);
              provider.pinState = PinState.Idle;

              if (mapStyle != null) {
                await provider.mapController!.setMapStyle(mapStyle);
              }

              // When select initialPosition set to true.
              if (selectInitialPosition!) {
                provider.setCameraPosition(initialCameraPosition);
                _searchByCameraLocation(provider);
              }
            },
            onCameraIdle: () {
              if (provider.isAutoCompleteSearching) {
                provider.isAutoCompleteSearching = false;
                provider.pinState = PinState.Idle;
                return;
              }

              // Perform search only if the setting is to true.
              if (usePinPointingSearch!) {
                // Search current camera location only if camera has moved (dragged) before.
                if (provider.pinState == PinState.Dragging) {
                  // Cancel previous timer.
                  if (provider.debounceTimer?.isActive ?? false) {
                    provider.debounceTimer!.cancel();
                  }
                  provider.debounceTimer =
                      Timer(Duration(milliseconds: debounceMilliseconds!), () {
                    _searchByCameraLocation(provider);
                  });
                }
              }

              provider.pinState = PinState.Idle;
            },
            onCameraMoveStarted: () {
              provider.setPrevCameraPosition(provider.cameraPosition);

              // Cancel any other timer.
              provider.debounceTimer?.cancel();

              // Update state, dismiss keyboard and clear text.
              provider.pinState = PinState.Dragging;

              // Begins the search state if the hide details is enabled
              if (this.hidePlaceDetailsWhenDraggingPin!) {
                provider.placeSearchingState = SearchingState.Searching;
              }

              onMoveStart!();
            },
            onCameraMove: (CameraPosition position) {
              provider.setCameraPosition(position);
            },
            // gestureRecognizers make it possible to navigate the map when it's a
            // child in a scroll view e.g ListView, SingleChildScrollView...
            gestureRecognizers: Set()
              ..add(Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer())),
          );
        });
    // TODO: Try this solution instead of the above one
    // builder: (_, data, __) => this._buildGoogleMapInner(PlaceProvider.of(context, listen: false), data)
    // );
  }

  Widget _buildPin(Color iconPlaceColor, Color iconPointerColor) {
    return Center(
      child: Selector<PlaceProvider, PinState>(
        selector: (_, provider) => provider.pinState,
        builder: (context, state, __) {
          if (pinBuilder == null) {
            return _defaultPinBuilder(
              context,
              state,
              iconPlaceColor,
              iconPointerColor,
            );
          } else {
            return Builder(
                builder: (builderContext) =>
                    pinBuilder!(builderContext, state));
          }
        },
      ),
    );
  }

  Widget _defaultPinBuilder(
    BuildContext context,
    PinState state,
    Color iconPlaceColor,
    Color iconPointerColor,
  ) {
    if (state == PinState.Preparing) {
      return Container();
    } else if (state == PinState.Idle) {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.place, size: 36, color: iconPlaceColor),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: iconPointerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedPin(
                  child: Icon(
                    Icons.place,
                    size: 36,
                    color: iconPlaceColor,
                  ),
                ),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: iconPointerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFloatingCard() {
    return Selector<PlaceProvider,
        Tuple4<PickResult?, SearchingState, bool, PinState>>(
      selector: (_, provider) => Tuple4(
          provider.selectedPlace,
          provider.placeSearchingState,
          provider.isSearchBarFocused,
          provider.pinState),
      builder: (context, data, __) {
        if ((data.item1 == null && data.item2 == SearchingState.Idle) ||
            data.item3 == true ||
            data.item4 == PinState.Dragging &&
                this.hidePlaceDetailsWhenDraggingPin!) {
          return Container();
        } else {
          if (selectedPlaceWidgetBuilder == null) {
            return _defaultPlaceWidgetBuilder(context, data.item1, data.item2);
          } else {
            return Builder(
                builder: (builderContext) => selectedPlaceWidgetBuilder!(
                    builderContext, data.item1, data.item2, data.item3));
          }
        }
      },
    );
  }

  Widget _buildZoomButtons() {
    return Selector<PlaceProvider, Tuple2<GoogleMapController?, LatLng?>>(
      selector: (_, provider) => new Tuple2<GoogleMapController?, LatLng?>(
          provider.mapController, provider.cameraPosition?.target),
      builder: (context, data, __) {
        if (!this.zoomControlsEnabled ||
            data.item1 == null ||
            data.item2 == null) {
          return Container();
        } else {
          return Positioned(
            bottom: 50,
            right: 10,
            child: Card(
              elevation: 4.0,
              child: Container(
                width: 40,
                height: 100,
                child: Column(
                  children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          double currentZoomLevel =
                              await data.item1!.getZoomLevel();
                          currentZoomLevel = currentZoomLevel + 2;
                          data.item1!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: data.item2!,
                                zoom: currentZoomLevel,
                              ),
                            ),
                          );
                        }),
                    SizedBox(height: 2),
                    IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () async {
                          double currentZoomLevel =
                              await data.item1!.getZoomLevel();
                          currentZoomLevel = currentZoomLevel - 2;
                          if (currentZoomLevel < 0) currentZoomLevel = 0;
                          data.item1!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: data.item2!,
                                zoom: currentZoomLevel,
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _defaultPlaceWidgetBuilder(
      BuildContext context, PickResult? data, SearchingState state) {
    return FloatingCard(
      bottomPosition: MediaQuery.of(context).size.height * 0.1,
      leftPosition: MediaQuery.of(context).size.width * 0.15,
      rightPosition: MediaQuery.of(context).size.width * 0.15,
      width: MediaQuery.of(context).size.width * 0.7,
      borderRadius: BorderRadius.circular(12.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: state == SearchingState.Searching
          ? _buildLoadingIndicator()
          : _buildSelectionDetails(context, data!),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 48,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildSelectionDetails(BuildContext context, PickResult result) {
    bool canBePicked = pickArea == null ||
        pickArea!.radius <= 0 ||
        Geolocator.distanceBetween(
                pickArea!.center.latitude,
                pickArea!.center.longitude,
                result.geometry!.location.lat,
                result.geometry!.location.lng) <=
            pickArea!.radius;
    MaterialStateColor buttonColor = MaterialStateColor.resolveWith(
        (states) => canBePicked ? Colors.lightGreen : Colors.red);
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Text(
            result.formattedAddress!,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          (canBePicked && (selectText?.isEmpty ?? true)) ||
                  (!canBePicked && (outsideOfPickAreaText?.isEmpty ?? true))
              ? SizedBox.fromSize(
                  size: Size(56, 56), // button width and height
                  child: ClipOval(
                    child: Material(
                      child: InkWell(
                          overlayColor: buttonColor,
                          onTap: () {
                            if (canBePicked) {
                              onPlacePicked!(result);
                            }
                          },
                          child: Icon(
                              canBePicked
                                  ? Icons.check_sharp
                                  : Icons.app_blocking_sharp,
                              color: buttonColor)),
                    ),
                  ),
                )
              : SizedBox.fromSize(
                  size: Size(MediaQuery.of(context).size.width * 0.8,
                      56), // button width and height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Material(
                      child: InkWell(
                          overlayColor: buttonColor,
                          onTap: () {
                            if (canBePicked) {
                              onPlacePicked!(result);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  canBePicked
                                      ? Icons.check_sharp
                                      : Icons.app_blocking_sharp,
                                  color: buttonColor),
                              SizedBox.fromSize(size: new Size(10, 0)),
                              Text(
                                  canBePicked
                                      ? selectText!
                                      : outsideOfPickAreaText!,
                                  style: TextStyle(color: buttonColor))
                            ],
                          )),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  Widget _buildMapIcons(BuildContext context) {
    if (appBarKey.currentContext == null) {
      return Container();
    }
    final RenderBox appBarRenderBox =
        appBarKey.currentContext!.findRenderObject() as RenderBox;
    return Positioned(
      top: appBarRenderBox.size.height,
      right: mapToolRight,
      child: Column(
        children: <Widget>[
          enableMapTypeButton!
              ? Container(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    elevation: 4.0,
                    onPressed: onToggleMapType,
                    child: Icon(
                      Icons.layers,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : mapTypeColor,
                    ),
                  ),
                )
              : Container(),
          SizedBox(height: mapToolSeparation),
          enableMyLocationButton!
              ? Container(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    elevation: 4.0,
                    onPressed: onMyLocation,
                    child: Icon(
                      Icons.my_location,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : mapTypeColor,
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
