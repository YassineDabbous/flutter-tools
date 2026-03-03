import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class GeoLocatorButton extends StatefulWidget {
  final Coordinates? current;
  final Widget Function(Coordinates)? builder;
  final Function(Coordinates)? onLoaded;
  final Widget? empty;
  const GeoLocatorButton({super.key, this.current, this.builder, this.onLoaded, this.empty});

  @override
  State<GeoLocatorButton> createState() => _GeoLocatorButtonState();
}

class _GeoLocatorButtonState extends State<GeoLocatorButton> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() => isLoading = true);
        Core.get<Locator>()
            .getCurrentPosition()
            .then((value) {
              // widget.maker.form.coordinates = Coordinates(latitude: value.latitude, longitude: value.longitude);
              widget.onLoaded?.call(Coordinates(latitude: value.latitude, longitude: value.longitude));
              setState(() => isLoading = false);
            })
            .onError((error, stackTrace) {
              setState(() => isLoading = false);
              dialogConfirmation(
                context: context,
                title: 'location',
                content:
                    """
${error.toString()}.
${'please open location settings'.i18n()}
""",
                onConfirm: Core.get<Locator>().openAppSettings,
              );
            });
      },
      child: isLoading
          ? const Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
            )
          : Text((widget.current == null || widget.current!.isEmpty) ? 'locate position'.i18n() : 'position located'.i18n()),
    );
  }
}
