import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/providers/tts_provider.dart';
import 'package:lute_for_mobile/core/network/tts_service.dart';

class OnDeviceVoiceSelector extends ConsumerStatefulWidget {
  final String? selectedVoice;
  final ValueChanged<String?> onVoiceChanged;

  const OnDeviceVoiceSelector({
    super.key,
    this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  ConsumerState<OnDeviceVoiceSelector> createState() =>
      _OnDeviceVoiceSelectorState();
}

class _OnDeviceVoiceSelectorState extends ConsumerState<OnDeviceVoiceSelector> {
  List<String> _availableVoices = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVoices();
  }

  Future<void> _fetchVoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(ttsServiceProvider);
      if (service is OnDeviceTTSService) {
        final voices = await service.getAvailableVoices();
        if (mounted) {
          setState(() {
            _availableVoices = voices;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Not using on-device TTS';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showVoicePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Voice'),
        content: SizedBox(
          width: double.maxFinite,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _fetchVoices();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : _availableVoices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 48),
                      SizedBox(height: 16),
                      Text('No voices found on this device'),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableVoices.length,
                  itemBuilder: (context, index) {
                    final voice = _availableVoices[index];
                    return ListTile(
                      title: Text(voice),
                      trailing: widget.selectedVoice == voice
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        widget.onVoiceChanged(voice);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (_availableVoices.isNotEmpty)
            TextButton(
              onPressed: () {
                _showManualInput();
              },
              child: const Text('Enter Manually'),
            ),
        ],
      ),
    );
  }

  void _showManualInput() {
    final controller = TextEditingController(text: widget.selectedVoice ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Voice Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Voice name',
            hintText: 'e.g., en-us, com.apple.ttsbundle.Tingting-compact',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                widget.onVoiceChanged(value.isEmpty ? null : value);
              }
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showVoicePicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Voice',
          hintText: 'Select a voice',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          widget.selectedVoice ?? 'Select a voice',
          style: TextStyle(
            color: widget.selectedVoice != null
                ? null
                : Colors.grey.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
