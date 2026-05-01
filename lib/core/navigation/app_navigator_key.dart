import 'package:flutter/material.dart';

/// Global navigator key for imperative navigation outside of the widget tree
/// (e.g. from FcmService on notification tap).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
