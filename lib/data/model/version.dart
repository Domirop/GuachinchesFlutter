class Version {
  late String _id;
  late String _iosVersion;
  late String _androidVersion;

  String get id => _id;
  String get iosVersion => _iosVersion;
  String get androidVersion => _androidVersion;

  Version({String? id, String? iosVersion, String? androidVersion}) {
    _id = id ?? "";
    _iosVersion = iosVersion ?? "";
    _androidVersion = androidVersion ?? "";
  }

  Version.fromJson(dynamic json) {
    _id = json["id"] ?? "";
    _iosVersion = json["iosVersion"] ?? "";
    _androidVersion = json["AndroidVersion"] ?? "";
  }

  @override
  String toString() {
    return 'Version{_id: $_id, _iosVersion: $_iosVersion, _androidVersion: $_androidVersion}';
  }
}
