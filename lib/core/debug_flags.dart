const List<String> kDebugFlagNames = ['__fail', '__delay'];

Map<String, String> readDebugFlags(Uri location) {
  return {
    for (final name in kDebugFlagNames)
      if ((location.queryParameters[name] ?? '').isNotEmpty) name: location.queryParameters[name]!,
  };
}
