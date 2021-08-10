# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'watir'
require 'uri'
require 'cgi'
require 'base64'
require 'socket'
require 'ostruct'
require 'pp'
require 'rspec'
# generates a JSON-friendly Track class
class Track
  attr_accessor :id, :name, :artist_name, :album_name, :spotify_url

  def as_json(_options = {})
    {
      id: @id,
      name: @name,
      artist_name: @artist_name,
      album_name: @album_name,
      spotify_url: @spotify_url
    }
  end

  def to_json(*options)
    as_json(*options).to_json(*options)
  end
end

# generates a JSON-friendly Playlist class
class Playlist
  attr_accessor :id, :name, :description, :owner_name, :spotify_url, :tracks

  def as_json(_options = {})
    {
      id: @id,
      name: @name,
      description: @description,
      owner_name: @owner_name,
      spotify_url: @spotify_url,
      tracks: @tracks
    }
  end

  def to_json(*options)
    as_json(*options).to_json(*options)
  end
end
CLIENT_ID = 'dca9cbb050c0477897753518bfd9c8ac'
CLIENT_SECRET = '8b235c81d41d444e8e10448be1a4fadc'
REDIRECT_URI = 'http://localhost:8000/'
TOKEN_URL = 'https://accounts.spotify.com/api/token'
GRANT_TYPE = 'authorization_code'
SCOPE = 'playlist-modify-public%20playlist-modify-private%20playlist-read-private'
args = ['--user-data-dir=C:\Users\Andrew\AppData\Local\Google\Chrome\User Data']
browser = Watir::Browser.new :chrome, options: { args: args }
browser.goto("https://accounts.spotify.com/authorize?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{REDIRECT_URI}&scope=#{SCOPE}")
browser.button.fire_event('onclick') if browser.button(id: 'auth-accept').exist?
auth_uri = URI(browser.window.url)
# puts uri
auth_params = CGI.parse(auth_uri.query)
# puts params
code = auth_params['code'].first
# puts code
response = RestClient::Request.new({
                                     method: :post,
                                     url: TOKEN_URL,
                                     payload: { grant_type: GRANT_TYPE,
                                                code: code,
                                                redirect_uri: REDIRECT_URI,
                                                client_id: CLIENT_ID,
                                                client_secret: CLIENT_SECRET }
                                   }).execute do |res, _request, _result|
  case res.code
  when 400
    [:error, JSON.parse(res.to_s)]
  when 200
    [:success, JSON.parse(res.to_s)]
  else
    raise "Invalid #{res}."
  end
end

access_token = response[1]['access_token']
p "i like #{access_token}"

user_id_req = RestClient.get 'https://api.spotify.com/v1/me', { content_type: :json,
                                                                accept: :json,
                                                                authorization: "Bearer #{access_token}" }
user_id = JSON.parse(user_id_req.body)['id']
create_new_playlist = RestClient::Request.new({
                                                method: :post,
                                                url: "https://api.spotify.com/v1/users/#{user_id}/playlists",
                                                payload: { name: 'My new Playlist',
                                                           description: 'Automatically generated playlist.',
                                                           public: false }.to_json,
                                                headers: { content_type: :json,
                                                           accept: :json,
                                                           authorization: "Bearer #{access_token}" }
                                              }).execute do |res, _request, _result|
  case res.code
  when 403
    [:error, JSON.parse(res.to_s)]
  when 201
    [:success, JSON.parse(res.to_s)]
  else
    raise "Invalid #{res.code}"
  end
end
playlist_id = create_new_playlist[1]['id']
p playlist_id
PLAYLIST_ID = '2lysRScB6eJ12VyKJ3SQkZ'
song_uris = %w[spotify:track:02MWAaffLxlfxAUY7c5dvx spotify:track:0zCgWGmDF0aih5qexATyBn
               spotify:track:17Mzg40eYZh2qNDKH5pZWm spotify:track:52Bg6oaos7twR7IUtEpqcE
               spotify:track:5uzkyHsJMkeaHLdNPuvUzP spotify:track:0R6dvBlNevqkzioHLoygbI
               spotify:track:6o39Ln9118FKTMbM4BvcEy spotify:track:32cQeY533XTAc4L6fzcIgG]
add_to_playlist = RestClient::Request.new({
                                            method: :post,
                                            url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                            payload: { uris: song_uris }.to_json,
                                            headers: { content_type: :json,
                                                       accept: :json,
                                                       authorization: "Bearer #{access_token}" }
                                          }).execute do |res, _request, _result|
  case res.code
  when 403
    [:error, JSON.parse(res.to_s)]
  when 201
    [:success, JSON.parse(res.to_s)]
  else
    raise "Invalid #{res.code}"
  end
end
p add_to_playlist.inspect
POSITION = 0
SNAPSHOT_ID_ADD_SONGS = 'MyxiMGE2YWM2ZDA2MjBkMTZiOThmNTAyZGZmMzc1N2Y1MGIzMzY3OGQy'
bottom_up_update_playlist = RestClient::Request.new({
                                                      method: :put,
                                                      url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                                      payload: {   range_start: 7,
                                                                   insert_before: 0,
                                                                   range_length: 1 }.to_json,
                                                      headers: { content_type: :json,
                                                                 accept: :json,
                                                                 authorization: "Bearer #{access_token}" }
                                                    }).execute do |res, _request, _result|
  case res.code
  when 400
    [:error, JSON.parse(res.to_s)]
  when 200
    [:success, JSON.parse(res.to_s)]
  else
    raise "Invalid #{res.code}"
  end
end
p bottom_up_update_playlist.inspect
delete_last_item_playlist = RestClient::Request.new({
                                                      method: :delete,
                                                      url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                                      payload: { tracks: [uri: 'spotify:track:6o39Ln9118FKTMbM4BvcEy'] }.to_json,
                                                      headers: { content_type: :json,
                                                                 accept: :json,
                                                                 authorization: "Bearer #{access_token}" }
                                                    }).execute do |res, _request, _result|
  case res.code
  when 400
    [:error, JSON.parse(res.to_s)]
  when 200
    [:success, JSON.parse(res.to_s)]
  else
    raise "Invalid #{res.code}"
  end
end
p delete_last_item_playlist.inspect
get_updated_playlist = RestClient::Request.new({
                                                 method: :get,
                                                 url: "https://api.spotify.com/v1/playlists/#{playlist_id}",
                                                 headers: { content_type: :json,
                                                            accept: :json,
                                                            authorization: "Bearer #{access_token}" }
                                               }).execute do |res, _request, _result|
  case res.code
  when 403
    [:error, JSON.parse(res.to_s)]
  when 200
    [:success, JSON.parse(res.to_s)]
  else
    raise "Invalid #{res.code}"
  end
end
dump = get_updated_playlist[1]
tracks = []

dump['tracks']['items'].each do |item|
  track = Track.new
  track.id = item['track']['id']
  track.name = item['track']['name']
  track.artist_name = item['track']['album']['artists'][0]['name']
  track.album_name = item['track']['album']['name']
  track.spotify_url = item['track']['external_urls']
  tracks.push(track)
end

myp = Playlist.new
myp.id = dump['id']
myp.name = dump['name']
myp.description = dump['description']
myp.owner_name = dump['owner']['display_name']
myp.spotify_url = dump['href']
myp.tracks = tracks
puts JSON.pretty_generate(myp)
File.write('public/playlist-data.json', JSON.dump(myp))
