import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Data class representing the connection details needed to join a LiveKit room
class ConnectionDetails {
  final String serverUrl;
  final String roomName;
  final String participantName;
  final String participantToken;

  ConnectionDetails({
    required this.serverUrl,
    required this.roomName,
    required this.participantName,
    required this.participantToken,
  });

  factory ConnectionDetails.fromJson(Map<String, dynamic> json) {
    return ConnectionDetails(
      serverUrl: json['serverUrl'],
      roomName: json['roomName'],
      participantName: json['participantName'],
      participantToken: json['participantToken'],
    );
  }
}

/// Enhanced TokenService that can work with environment variables
class TokenService {
  // Get credentials from environment variables
  String? get livekitUrl => dotenv.env['LIVEKIT_URL'];
  String? get livekitApiKey => dotenv.env['LIVEKIT_API_KEY'];
  String? get livekitApiSecret => dotenv.env['LIVEKIT_API_SECRET'];
  
  // For hardcoded token usage (development only)
  final String? hardcodedToken = null;

  // Get the sandbox ID from environment variables
  String? get sandboxId {
    final value = dotenv.env['LIVEKIT_SANDBOX_ID'];
    if (value != null) {
      return value.replaceAll('"', '');
    }
    return null;
  }

  // LiveKit Cloud sandbox API endpoint
  final String sandboxUrl = 'https://cloud-api.livekit.io/api/sandbox/connection-details';

  /// Main method to get connection details
  Future<ConnectionDetails> fetchConnectionDetails({
    required String roomName,
    required String participantName,
  }) async {
    // Try hardcoded token first
    final hardcodedDetails = fetchHardcodedConnectionDetails(
      roomName: roomName,
      participantName: participantName,
    );

    if (hardcodedDetails != null) {
      return hardcodedDetails;
    }

    // Try sandbox if sandbox ID is available
    if (sandboxId != null) {
      return await fetchConnectionDetailsFromSandbox(
        roomName: roomName,
        participantName: participantName,
      );
    }

    // Try direct LiveKit URL if available
    if (livekitUrl != null && livekitApiKey != null && livekitApiSecret != null) {
      return await fetchConnectionDetailsFromLiveKit(
        roomName: roomName,
        participantName: participantName,
      );
    }

    throw Exception('No valid LiveKit configuration found. Please set either LIVEKIT_SANDBOX_ID or LIVEKIT_URL with API credentials.');
  }

  /// Fetch connection details from LiveKit Cloud sandbox
  Future<ConnectionDetails> fetchConnectionDetailsFromSandbox({
    required String roomName,
    required String participantName,
  }) async {
    if (sandboxId == null) {
      throw Exception('Sandbox ID is not set');
    }

    final uri = Uri.parse(sandboxUrl).replace(queryParameters: {
      'roomName': roomName,
      'participantName': participantName,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'X-Sandbox-ID': sandboxId!},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          return ConnectionDetails.fromJson(data);
        } catch (e) {
          debugPrint('Error parsing connection details from LiveKit Cloud sandbox, response: ${response.body}');
          throw Exception('Error parsing connection details from LiveKit Cloud sandbox');
        }
      } else {
        debugPrint('Error from LiveKit Cloud sandbox: ${response.statusCode}, response: ${response.body}');
        throw Exception('Error from LiveKit Cloud sandbox');
      }
    } catch (e) {
      debugPrint('Failed to connect to LiveKit Cloud sandbox: $e');
      throw Exception('Failed to connect to LiveKit Cloud sandbox');
    }
  }

  /// Fetch connection details using direct LiveKit URL and credentials
  /// Note: In production, you should have a proper token server
  Future<ConnectionDetails> fetchConnectionDetailsFromLiveKit({
    required String roomName,
    required String participantName,
  }) async {
    // For now, return connection details with URL but without token
    // You'll need to implement token generation on your server or use a pre-generated token
    debugPrint('Warning: Using LiveKit URL without proper token generation. You need to implement a token server for production.');
    
    return ConnectionDetails(
      serverUrl: livekitUrl!,
      roomName: roomName,
      participantName: participantName,
      participantToken: hardcodedToken ?? 'PLACEHOLDER_TOKEN', // You'll need to generate this properly
    );
  }

  /// Use hardcoded credentials (development only)
  ConnectionDetails? fetchHardcodedConnectionDetails({
    required String roomName,
    required String participantName,
  }) {
    if (livekitUrl == null || hardcodedToken == null) {
      return null;
    }

    return ConnectionDetails(
      serverUrl: livekitUrl!,
      roomName: roomName,
      participantName: participantName,
      participantToken: hardcodedToken!,
    );
  }
}