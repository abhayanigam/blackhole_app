/// RapidAPI Configuration for Spotify and YouTube APIs
/// 
/// This file contains the API keys and configuration for RapidAPI services.

class RapidApiConfig {
  // RapidAPI Key - same for both Spotify and YouTube
  static const String rapidApiKey = '77f8752d1amsh5c0d547aa1ef8f8p12a92djsna0b6cc94f33b';
  
  // Spotify RapidAPI Configuration
  static const String spotifyHost = 'spotify81.p.rapidapi.com';
  static const String spotifyBaseUrl = 'https://spotify81.p.rapidapi.com';
  
  // YouTube RapidAPI Configuration
  static const String youtubeHost = 'youtube-data8.p.rapidapi.com';
  static const String youtubeBaseUrl = 'https://youtube-data8.p.rapidapi.com';
  
  // Alternative YouTube hosts if needed
  static const String youtubeAltHost = 'youtube-v31.p.rapidapi.com';
  static const String youtubeAltBaseUrl = 'https://youtube-v31.p.rapidapi.com';
  
  // Common headers for RapidAPI requests
  static Map<String, String> getSpotifyHeaders() {
    return {
      'X-RapidAPI-Key': rapidApiKey,
      'X-RapidAPI-Host': spotifyHost,
      'Accept': 'application/json',
    };
  }
  
  static Map<String, String> getYoutubeHeaders() {
    return {
      'X-RapidAPI-Key': rapidApiKey,
      'X-RapidAPI-Host': youtubeHost,
      'Accept': 'application/json',
    };
  }
}
