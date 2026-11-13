import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiHttp {
  static const timeout = Duration(seconds: 20);

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      http.get(url, headers: headers).timeout(timeout);

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => http.post(url, headers: headers, body: body, encoding: encoding).timeout(timeout);

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => http.put(url, headers: headers, body: body, encoding: encoding).timeout(timeout);

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => http.patch(url, headers: headers, body: body, encoding: encoding).timeout(timeout);
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => http.delete(url, headers: headers, body: body, encoding: encoding).timeout(timeout);
}