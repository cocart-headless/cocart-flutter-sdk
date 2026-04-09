import 'dart:convert';

import 'package:http/http.dart' as http;

/// A mock HTTP client for testing that returns preconfigured responses.
class MockHttpClient extends http.BaseClient {
  final List<MockResponse> _responses = [];
  final List<http.BaseRequest> requests = [];

  void enqueue(MockResponse response) => _responses.add(response);

  void enqueueJson(Map<String, dynamic> body,
      {int statusCode = 200, Map<String, String>? headers}) {
    _responses.add(MockResponse(
      statusCode: statusCode,
      body: jsonEncode(body),
      headers: headers ?? {},
    ));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);

    if (_responses.isEmpty) {
      throw StateError('No mock responses queued for ${request.url}');
    }

    final mock = _responses.removeAt(0);
    return http.StreamedResponse(
      Stream.value(utf8.encode(mock.body)),
      mock.statusCode,
      headers: mock.headers,
      request: request,
    );
  }
}

class MockResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  const MockResponse({
    this.statusCode = 200,
    this.body = '{}',
    this.headers = const {},
  });
}
