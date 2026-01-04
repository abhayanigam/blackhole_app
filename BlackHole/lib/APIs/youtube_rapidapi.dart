import 'dart:convert';

import 'package:blackhole/APIs/rapidapi_config.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

/// YouTube RapidAPI Service for searching videos and getting video details
class YouTubeRapidApi {
  static final YouTubeRapidApi _singleton = YouTubeRapidApi._internal();

  factory YouTubeRapidApi() {
    return _singleton;
  }

  YouTubeRapidApi._internal();

  /// Search for videos on YouTube using RapidAPI
  Future<List<Map>> searchVideos(String query, {int maxResults = 25}) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.youtubeBaseUrl}/search/?q=${Uri.encodeComponent(query)}&hl=en&gl=US',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getYoutubeHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<Map> videos = [];
        
        // Handle different response formats from different RapidAPI providers
        final List? items = result['contents'] ?? result['items'] ?? result['videos'];
        
        if (items != null) {
          for (final item in items) {
            // Try to extract video data from different formats
            final video = item['video'] ?? item['snippet'] ?? item;
            if (video != null && video['videoId'] != null) {
              videos.add(_formatVideoResult(video));
            }
          }
        }
        
        return videos;
      } else {
        Logger.root.severe('YouTube RapidAPI search error: ${response.statusCode}');
      }
    } catch (e) {
      Logger.root.severe('Error in YouTube RapidAPI search: $e');
    }
    return [];
  }

  /// Get video details by ID
  Future<Map?> getVideoDetails(String videoId) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.youtubeBaseUrl}/video/details/?id=$videoId&hl=en&gl=US',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getYoutubeHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _formatVideoDetails(result);
      }
    } catch (e) {
      Logger.root.severe('Error in YouTube RapidAPI video details: $e');
    }
    return null;
  }

  /// Get playlist details
  Future<Map?> getPlaylistDetails(String playlistId) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.youtubeBaseUrl}/playlist/details/?id=$playlistId&hl=en&gl=US',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getYoutubeHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _formatPlaylistDetails(result);
      }
    } catch (e) {
      Logger.root.severe('Error in YouTube RapidAPI playlist details: $e');
    }
    return null;
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.youtubeBaseUrl}/auto-complete/?q=${Uri.encodeComponent(query)}&hl=en&gl=US',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getYoutubeHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<String> suggestions = [];
        
        if (result['results'] != null) {
          for (final suggestion in result['results']) {
            if (suggestion is String) {
              suggestions.add(suggestion);
            } else if (suggestion is Map && suggestion['query'] != null) {
              suggestions.add(suggestion['query'].toString());
            }
          }
        }
        
        return suggestions;
      }
    } catch (e) {
      Logger.root.severe('Error in YouTube RapidAPI suggestions: $e');
    }
    return [];
  }

  /// Get channel details
  Future<Map?> getChannelDetails(String channelId) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.youtubeBaseUrl}/channel/details/?id=$channelId&hl=en&gl=US',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getYoutubeHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _formatChannelDetails(result);
      }
    } catch (e) {
      Logger.root.severe('Error in YouTube RapidAPI channel details: $e');
    }
    return null;
  }

  /// Get trending videos
  Future<List<Map>> getTrendingVideos({String region = 'US', int maxResults = 25}) async {
    try {
      final Uri path = Uri.parse(
        '${RapidApiConfig.youtubeBaseUrl}/trending/?type=music&geo=$region&hl=en',
      );
      final response = await get(
        path,
        headers: RapidApiConfig.getYoutubeHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<Map> videos = [];
        
        final List? items = result['data'] ?? result['items'] ?? result['videos'];
        
        if (items != null) {
          for (final item in items) {
            final video = item['video'] ?? item;
            if (video != null) {
              videos.add(_formatVideoResult(video));
            }
          }
        }
        
        return videos;
      }
    } catch (e) {
      Logger.root.severe('Error in YouTube RapidAPI trending: $e');
    }
    return [];
  }

  // Helper methods to format responses
  Map _formatVideoResult(Map video) {
    String? videoId = video['videoId'] ?? video['id'];
    if (videoId is Map) {
      videoId = videoId['videoId'];
    }
    
    String title = video['title'] ?? video['name'] ?? '';
    if (title is Map) {
      title = title['text'] ?? '';
    }
    
    String channelName = video['channelName'] ?? 
                         video['channelTitle'] ?? 
                         video['author'] ?? 
                         '';
    if (channelName is Map) {
      channelName = channelName['text'] ?? '';
    }
    
    String? thumbnail;
    if (video['thumbnail'] != null) {
      if (video['thumbnail'] is List && (video['thumbnail'] as List).isNotEmpty) {
        thumbnail = video['thumbnail'].last['url'];
      } else if (video['thumbnail'] is Map) {
        thumbnail = video['thumbnail']['url'] ?? 
                   (video['thumbnail']['thumbnails'] as List?)?.last?['url'];
      } else if (video['thumbnail'] is String) {
        thumbnail = video['thumbnail'];
      }
    }
    thumbnail ??= 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
    
    String? duration = video['lengthText'] ?? 
                       video['duration'] ?? 
                       video['length']?['simpleText'];
    if (duration is Map) {
      duration = duration['simpleText'] ?? duration['text'];
    }
    
    String? viewCount = video['viewCount'] ?? 
                        video['views'] ?? 
                        video['viewCountText']?['simpleText'];
    
    return {
      'id': videoId,
      'videoId': videoId,
      'title': title.toString(),
      'artist': channelName.toString(),
      'channelName': channelName.toString(),
      'image': thumbnail,
      'thumbnail': thumbnail,
      'duration': duration?.toString() ?? '',
      'views': viewCount?.toString() ?? '',
      'type': 'video',
      'perma_url': 'https://www.youtube.com/watch?v=$videoId',
      'language': 'YouTube',
      'genre': 'YouTube',
    };
  }

  Map _formatVideoDetails(Map result) {
    final String videoId = result['videoId'] ?? result['id'] ?? '';
    
    String? thumbnail;
    if (result['thumbnail'] != null) {
      if (result['thumbnail'] is List && (result['thumbnail'] as List).isNotEmpty) {
        thumbnail = result['thumbnail'].last['url'];
      } else if (result['thumbnail'] is String) {
        thumbnail = result['thumbnail'];
      }
    }
    thumbnail ??= 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
    
    return {
      'id': videoId,
      'videoId': videoId,
      'title': result['title'] ?? '',
      'artist': result['channelTitle'] ?? result['author'] ?? '',
      'album': result['channelTitle'] ?? result['author'] ?? '',
      'image': thumbnail,
      'thumbnail': thumbnail,
      'duration': result['lengthSeconds'] ?? result['duration'] ?? '',
      'views': result['viewCount'] ?? result['views'] ?? '',
      'description': result['description'] ?? '',
      'publishedAt': result['publishDate'] ?? result['publishedAt'] ?? '',
      'type': 'video',
      'perma_url': 'https://www.youtube.com/watch?v=$videoId',
      'language': 'YouTube',
      'genre': 'YouTube',
    };
  }

  Map _formatPlaylistDetails(Map result) {
    final String playlistId = result['playlistId'] ?? result['id'] ?? '';
    
    String? thumbnail;
    if (result['thumbnail'] != null) {
      if (result['thumbnail'] is List && (result['thumbnail'] as List).isNotEmpty) {
        thumbnail = result['thumbnail'].last['url'];
      } else if (result['thumbnail'] is String) {
        thumbnail = result['thumbnail'];
      }
    }
    
    List<Map> videos = [];
    if (result['videos'] != null) {
      for (final video in result['videos']) {
        videos.add(_formatVideoResult(video));
      }
    }
    
    return {
      'id': playlistId,
      'playlistId': playlistId,
      'title': result['title'] ?? '',
      'description': result['description'] ?? '',
      'image': thumbnail ?? '',
      'channelName': result['channelTitle'] ?? result['author'] ?? '',
      'videoCount': result['videoCount'] ?? videos.length,
      'videos': videos,
      'type': 'playlist',
    };
  }

  Map _formatChannelDetails(Map result) {
    final String channelId = result['channelId'] ?? result['id'] ?? '';
    
    String? thumbnail;
    if (result['avatar'] != null) {
      if (result['avatar'] is List && (result['avatar'] as List).isNotEmpty) {
        thumbnail = result['avatar'].last['url'];
      } else if (result['avatar'] is String) {
        thumbnail = result['avatar'];
      }
    } else if (result['thumbnail'] != null) {
      thumbnail = result['thumbnail'];
    }
    
    return {
      'id': channelId,
      'channelId': channelId,
      'title': result['title'] ?? result['name'] ?? '',
      'description': result['description'] ?? '',
      'image': thumbnail ?? '',
      'subscriberCount': result['subscriberCount'] ?? result['subscribers'] ?? '',
      'videoCount': result['videoCount'] ?? '',
      'type': 'channel',
    };
  }
}
