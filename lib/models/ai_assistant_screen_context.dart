class AiAssistantScreenContext {
  AiAssistantScreenContext({
    required this.screenName,
    required this.route,
    required this.stage,
    required this.goal,
    this.visibleFields = const <String>[],
    this.filledFields = const <String, String>{},
    this.notes = const <String>[],
  });

  final String screenName;
  final String route;
  final String stage;
  final String goal;
  final List<String> visibleFields;
  final Map<String, String> filledFields;
  final List<String> notes;
}
