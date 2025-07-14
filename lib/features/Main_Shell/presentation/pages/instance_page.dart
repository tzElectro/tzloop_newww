import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/segment_instance.dart';
import '../../../../core/services/wled_api_service.dart';
import '../../domain/models/device_provider.dart';

@RoutePage()
class InstancePage extends ConsumerStatefulWidget {
  const InstancePage({Key? key}) : super(key: key);

  @override
  ConsumerState<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends ConsumerState<InstancePage> {
  final _apiService = UnifiedWledService();
  List<SegmentInstance> _segments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  Future<void> _loadSegments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentDevice = ref.read(deviceProvider).firstOrNull;
      if (currentDevice == null) {
        throw Exception('No device selected');
      }

      final state = await _apiService.getState(currentDevice.info.ip);
      final segmentsData = state['seg'] as List?;

      if (segmentsData == null) {
        throw Exception('No segments found in device state');
      }

      final segments = segmentsData.map((segment) {
        final data = Map<String, dynamic>.from(segment);
        return SegmentInstance.fromJson(data);
      }).toList();

      setState(() {
        _segments = segments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSegments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSegments,
      child: ListView.builder(
        itemCount: _segments.length,
        itemBuilder: (context, index) {
          final segment = _segments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: segment.color,
                child: Icon(
                  segment.isMaster ? Icons.star : Icons.lightbulb,
                  color: segment.color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              title: Text(
                segment.name.isNotEmpty
                    ? segment.name
                    : 'Segment ${segment.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('LEDs ${segment.start} - ${segment.stop}'),
              trailing: Switch(
                value: segment.isActive,
                onChanged: (value) async {
                  try {
                    final currentDevice = ref.read(deviceProvider).firstOrNull;
                    if (currentDevice == null) return;

                    await _apiService.setSegmentState(
                        currentDevice.info.ip, segment.id, value);
                    await _loadSegments();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to toggle segment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
