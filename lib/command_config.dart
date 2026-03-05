
class CommandConfig {
  final int time;
  bool flag; // Remove 'final' here to allow updates.
  final String command;

  CommandConfig({
    required this.time,
    required this.flag,
    required this.command,
  });

  factory CommandConfig.fromJson(Map<String, dynamic> json) {
    return CommandConfig(
      time: json['time'],
      flag: json['flag'],
      command: json['command'],
    );
  }
}
