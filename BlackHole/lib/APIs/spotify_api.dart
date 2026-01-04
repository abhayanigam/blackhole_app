import 'dart:async';
import 'dart:convert';

import 'package:blackhole/APIs/rapidapi_config.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

class SpotifyApi {
  final List<String> _scopes = [
    'user-read-private',
    'user-read-email',
    'playlist-read-private',
    'playlist-read-collaborative',
  ];

  /// You can signup for spotify developer account and get your own clientID and clientSecret incase you don't want to use these
  final String clientID = '08de4eaf71904d1b95254fab3015d711';
  final String clientSecret = '622b4fbad33947c59b95a6ae607de11d';
  final String redirectUrl = 'app://blackhole/auth';
  final String spotifyApiUrl = 'https://accounts.spotify.com/api';
  final String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  final String spotifyUserPlaylistEndpoint = '/me/playlists';
  final String spotifyPlaylistTrackEndpoint = '/playlists';
  final String spotifyRegionalChartsEndpoint = '/views/charts-regional';
  final String spotifyFeaturedPlaylistsEndpoint = '/browse/featured-playlists';
  final String spotifyBaseUrl = 'https://accounts.spotify.com';
  final String requestToken = 'https://accounts.spotify.com/api/token';

  String requestAuthorization() =>
      'https://accounts.spotify.com/authorize?client_id=$clientID&response_type=code&redirect_uri=$redirectUrl&scope=${_scopes.join('%20')}';

  Future<List<String>> getAccessToken({
    String? code,
    String? refreshToken,
  }) async {
    final Map<String, String> headers = {
      'Authorization':
          "Basic ${base64.encode(utf8.encode("$clientID:$clientSecret"))}",
    };

    Map<String, String>? body;
    if (code != null) {
      body = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUrl
      };
    } else if (refreshToken != null) {
      body = {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      };
    }

    if (body == null) {
      return [];
    }

    try {
      final Uri path = Uri.parse(requestToken);
      final response = await post(path, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map result = jsonDecode(response.body) as Map;
        return <String>[
          result['access_token'].toString(),
          result['refresh_token'].toString(),
          result['expires_in'].toString(),
        ];
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify access token: $e');
    }
    return [];
  }

  Future<List> getUserPlaylists(String accessToken) async {
    try {
      final Uri path =
          Uri.parse('$spotifyApiBaseUrl$spotifyUserPlaylistEndpoint?limit=50');

      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List playlists = result['items'] as List;
        return playlists;
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify user playlists: $e');
    }
    return [];
  }

  Future<List> getAllTracksOfPlaylist(
    String accessToken,
    String playlistId,
  ) async {
    final List tracks = [];
    int totalTracks = 100;

    final Map data = await SpotifyApi().getHundredTracksOfPlaylist(
      accessToken,
      playlistId,
      0,
    );
    totalTracks = data['total'] as int;
    tracks.addAll(data['tracks'] as List);

    if (totalTracks > 100) {
      for (int i = 1; i * 100 <= totalTracks; i++) {
        final Map data = await SpotifyApi().getHundredTracksOfPlaylist(
          accessToken,
          playlistId,
          i * 100,
        );
        tracks.addAll(data['tracks'] as List);
      }
    }
    return tracks;
  }

  Future<Map> getHundredTracksOfPlaylist(
    String accessToken,
    String playlistId,
    int offset,
  ) async {
    try {
      final Uri path = Uri.parse(
        '$spotifyApiBaseUrl$spotifyPlaylistTrackEndpoint/$playlistId/tracks?limit=100&offset=$offset',
      );
      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final result = await jsonDecode(response.body);
        final List tracks = result['items'] as List;
        final int total = result['total'] as int;
        return {'tracks': tracks, 'total': total};
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify playlist tracks: $e');
    }
    return {};
  }

  Future<Map> getTrackDetails(String accessToken, String trackId) async {
    final Uri path = Uri.parse(
      '$spotifyApiBaseUrl/tracks/$trackId',
    );
    final response = await get(
      path,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map;
      return result;
    }
    return {};
  }

  Future<List<Map>> getFeaturedPlaylists(String accessToken) async {
    try {
      final Uri path = Uri.parse(
        '$spotifyApiBaseUrl/browse/featured-playlists',
      );
      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );
      final List<Map> songsData = [];
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await for (final element in result['playlists']['items']) {
          songsData.add({
            'name': element['name'],
            'id': element['id'],
            'image': element['images'][0]['url'],
            'description': element['description'],
            'externalUrl': element['external_urls']['spotify'],
            'tracks': await SpotifyApi().getAllTracksOfPlaylist(
              accessToken,
              element['id'].toString(),
            ),
          });
        }
      }
      return songsData;
    } catch (e) {
      Logger.root.severe('Error in getting spotify featured playlists: $e');
      return List.empty();
    }
  }

  // RapidAPI-based methods for searching (no OAuth required)
  Future<List<Map>> searchTracks(String query, {int limit = 20}) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.spotifyBaseUrl}/search?q=${Uri.encodeComponent(query)}&type=track&limit=$limit',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getSpotifyHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<Map> tracks = [];
        if (result['tracks'] != null && result['tracks']['items'] != null) {
          for (final track in result['tracks']['items']) {
            tracks.add({
              'name': track['name'],
              'id': track['id'],
              'artist': (track['artists'] as List).isNotEmpty
                  ? track['artists'][0]['name']
                  : 'Unknown',
              'album': track['album']?['name'] ?? '',
              'image': track['album']?['images']?.isNotEmpty == true
                  ? track['album']['images'][0]['url']
                  : '',
              'duration': track['duration_ms'],
              'preview_url': track['preview_url'],
              'external_url': track['external_urls']?['spotify'] ?? '',
            });
          }
        }
        return tracks;
      }
    } catch (e) {
      Logger.root.severe('Error in RapidAPI spotify search: $e');
    }
    return [];
  }

  Future<List<Map>> searchArtists(String query, {int limit = 20}) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.spotifyBaseUrl}/search?q=${Uri.encodeComponent(query)}&type=artist&limit=$limit',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getSpotifyHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<Map> artists = [];
        if (result['artists'] != null && result['artists']['items'] != null) {
          for (final artist in result['artists']['items']) {
            artists.add({
              'name': artist['name'],
              'id': artist['id'],
              'image': artist['images']?.isNotEmpty == true
                  ? artist['images'][0]['url']
                  : '',
              'followers': artist['followers']?['total'] ?? 0,
              'genres': artist['genres'] ?? [],
              'external_url': artist['external_urls']?['spotify'] ?? '',
            });
          }
        }
        return artists;
      }
    } catch (e) {
      Logger.root.severe('Error in RapidAPI spotify artist search: $e');
    }
    return [];
  }

  Future<List<Map>> searchAlbums(String query, {int limit = 20}) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.spotifyBaseUrl}/search?q=${Uri.encodeComponent(query)}&type=album&limit=$limit',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getSpotifyHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<Map> albums = [];
        if (result['albums'] != null && result['albums']['items'] != null) {
          for (final album in result['albums']['items']) {
            albums.add({
              'name': album['name'],
              'id': album['id'],
              'artist': (album['artists'] as List).isNotEmpty
                  ? album['artists'][0]['name']
                  : 'Unknown',
              'image': album['images']?.isNotEmpty == true
                  ? album['images'][0]['url']
                  : '',
              'release_date': album['release_date'] ?? '',
              'total_tracks': album['total_tracks'] ?? 0,
              'external_url': album['external_urls']?['spotify'] ?? '',
            });
          }
        }
        return albums;
      }
    } catch (e) {
      Logger.root.severe('Error in RapidAPI spotify album search: $e');
    }
    return [];
  }

  Future<Map?> getTrackDetailsRapidApi(String trackId) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.spotifyBaseUrl}/tracks?ids=$trackId',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getSpotifyHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['tracks'] != null && (result['tracks'] as List).isNotEmpty) {
          final track = result['tracks'][0];
          return {
            'name': track['name'],
            'id': track['id'],
            'artist': (track['artists'] as List).isNotEmpty
                ? track['artists'][0]['name']
                : 'Unknown',
            'album': track['album']?['name'] ?? '',
            'image': track['album']?['images']?.isNotEmpty == true
                ? track['album']['images'][0]['url']
                : '',
            'duration': track['duration_ms'],
            'preview_url': track['preview_url'],
            'external_url': track['external_urls']?['spotify'] ?? '',
          };
        }
      }
    } catch (e) {
      Logger.root.severe('Error in RapidAPI spotify track details: $e');
    }
    return null;
  }
}
