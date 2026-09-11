int nowMillis() => DateTime.now().millisecondsSinceEpoch;

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(Object? value) => value == 1 || value == true;
