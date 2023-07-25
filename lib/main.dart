import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final latitudeProvider = StateProvider<double>((ref) => 0.0);
final longitudeProvider = StateProvider<double>((ref) => 0.0);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "GeoLocate",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const Scaffold(
          body: MyHomePage(),
        ));
  }
}

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latitude = ref.watch(latitudeProvider);
    final longitude = ref.watch(longitudeProvider);

    Future<void> checkPermission() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are denied');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
    }

    Future<void> getLocation() async {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      ref.read(latitudeProvider.notifier).update((state) => position.latitude);
      ref
          .read(longitudeProvider.notifier)
          .update((state) => position.longitude);
    }

    useEffect(() {
      checkPermission();
      Timer.periodic(const Duration(microseconds: 1), (timer) {
        getLocation();
      });
      return null;
    });

    return Center(
      child: Column(children: [
        Text(latitude.toString()),
        Text(longitude.toString()),
      ]),
    );
  }
}
