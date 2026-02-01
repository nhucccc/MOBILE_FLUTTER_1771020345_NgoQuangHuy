import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DebugTournamentsScreen extends StatefulWidget {
  const DebugTournamentsScreen({Key? key}) : super(key: key);

  @override
  State<DebugTournamentsScreen> createState() => _DebugTournamentsScreenState();
}

class _DebugTournamentsScreenState extends State<DebugTournamentsScreen> {
  final ApiService _apiService = ApiService();
  String _debugInfo = 'Initializing...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testTournamentApi();
  }

  Future<void> _testTournamentApi() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading tournaments...';
    });

    try {
      print('DebugTournamentsScreen: Starting API call...');
      final response = await _apiService.get('/tournament');
      print('DebugTournamentsScreen: API Response: $response');
      
      setState(() {
        _debugInfo = 'API Response:\n${response.toString()}';
      });
    } catch (e) {
      print('DebugTournamentsScreen: Error: $e');
      setState(() {
        _debugInfo = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testTournamentApi,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            const Text(
              'Debug Info:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}