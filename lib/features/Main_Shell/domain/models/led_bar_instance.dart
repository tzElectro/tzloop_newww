    // lib/features/devices/domain/models/led_bar_instance.dart
    class LedBarInstance {
      final int id;
      final int start;
      final int stop;
      final String? name;
      final bool isMaster;

      LedBarInstance({
        required this.id,
        required this.start,
        required this.stop,
        this.name,
        this.isMaster = false,
      });

      factory LedBarInstance.fromJson(Map<String, dynamic> json) {
        return LedBarInstance(
          id: json['id'] ?? 0,
          start: json['start'],
          stop: json['stop'],
          name: json['name'],
          isMaster: json['id'] == 0,
        );
      }
    }

