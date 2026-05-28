import 'package:flutter/foundation.dart';

enum AppSection { fan, artist, contributor }

/// Manages which app section is active (fan / artist / contributor)
/// and the current tab index within the artist shell.
class SectionProvider extends ChangeNotifier {
  AppSection _section = AppSection.fan;
  int _artistTabIndex = 0;

  AppSection get section => _section;
  int get artistTabIndex => _artistTabIndex;
  bool get isArtistMode => _section == AppSection.artist;
  bool get isContributorMode => _section == AppSection.contributor;

  void switchTo(AppSection section) {
    if (_section == section) return;
    _section = section;
    _artistTabIndex = 0;
    notifyListeners();
  }

  void setArtistTab(int index) {
    if (_artistTabIndex == index) return;
    _artistTabIndex = index;
    notifyListeners();
  }
}
