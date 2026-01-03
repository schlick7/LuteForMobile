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
  List<TTSVoice> _availableVoices = [];
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
    final groupedVoices = <String, List<TTSVoice>>{};
    for (final voice in _availableVoices) {
      final locale = voice.locale.isEmpty ? 'Other' : voice.locale;
      groupedVoices.putIfAbsent(locale, () => []);
      groupedVoices[locale]!.add(voice);
    }
    final sortedLocales = groupedVoices.keys.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Voice'),
            if (_availableVoices.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _fetchVoices();
                },
                child: const Text('Refresh', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
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
                      SizedBox(height: 8),
                      Text(
                        'Try downloading TTS voices in your device settings',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedLocales.length,
                  itemBuilder: (context, localeIndex) {
                    final locale = sortedLocales[localeIndex];
                    final voices = groupedVoices[locale]!;
                    return ExpansionTile(
                      title: Text(
                        locale,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${voices.length} voices'),
                      initiallyExpanded:
                          widget.selectedVoice != null &&
                          voices.any((v) => v.name == widget.selectedVoice),
                      children: voices.map((voice) {
                        return ListTile(
                          dense: true,
                          title: Text(voice.displayName.split(' [')[0]),
                          subtitle:
                              voice.quality != null ||
                                  voice.isNetworkConnectionRequired
                              ? Text(
                                  '${voice.quality != null ? '${voice.quality} • ' : ''}${voice.isNetworkConnectionRequired ? 'Online' : 'Local'}',
                                )
                              : null,
                          trailing: widget.selectedVoice == voice.name
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            widget.onVoiceChanged(voice.name);
                            Navigator.of(context).pop();
                          },
                        );
                      }).toList(),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Voice name',
                hintText: 'e.g., en-us-x-sfg#female_2-local',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: You can find available voice names in the voice picker or by running the app with debug logging.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
    final selectedVoiceObj = _availableVoices.firstWhere(
      (v) => v.name == widget.selectedVoice,
      orElse: () => TTSVoice(name: widget.selectedVoice ?? '', locale: ''),
    );

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
          widget.selectedVoice != null && selectedVoiceObj.name.isNotEmpty
              ? selectedVoiceObj.displayName
              : 'Select a voice',
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
