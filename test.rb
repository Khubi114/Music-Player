require 'gosu'

class Album
 attr_reader :title, :artist, :artwork, :tracks

 def initialize(title, artist, artwork, tracks)
 @title = title
 @artist = artist
 @artwork = artwork
 @tracks = tracks
 end
end

class Track
 attr_reader :name, :filename

 def initialize(name, filename)
 @name = name
 @filename = filename
 @sample = Gosu::Sample.new(filename)
 @instance = nil
 end

 def play
 stop
 @instance = @sample.play
 end

 def pause
 # Gosu::SampleInstance does not support pause, so we stop it
 stop
 end

 def stop
 @instance&.stop
 @instance = nil
 end

 def playing?
 @instance && @instance.playing?
 end

 def volume=(vol)
 @instance&.volume = vol
 end

 def current_position
 0 # Placeholder, Gosu::SampleInstance does not provide position
 end

 def length
 1 # Placeholder, Gosu::SampleInstance does not provide length
 end
end

class MusicPlayer < Gosu::Window
 X_ALBUMS_START = 50
 Y_ALBUMS_START = 50
 ALBUM_SIZE = 150
 ALBUM_PADDING = 20
 ALBUMS_PER_PAGE = 6

 def initialize
 super 800, 600
 self.caption = "Music Player"

 @albums = load_albums
 @album_page = 0
 @selected_album_index = nil
 @selected_track_index = nil
 @playing_track = nil
 @font_album = Gosu::Font.new(20)
 @font_now_playing = Gosu::Font.new(30)
 @volume = 0.5
 @loop = false
 @shuffle = false
 @playlist = []
 @playlist_index = 0
 end

 def load_albums
 # Add as many albums as you want here for testing paging
 [
 Album.new("AM", "Arctic Monkeys", "albums/arctic.jpg", [
 Track.new("Do I Wanna Know?", "songs/arctic_1.wav"),
 Track.new("I Wanna Be Yours", "songs/arctic_2.wav"),
 Track.new("Why'd You Only Call Me When You're High?", "songs/arctic_3.wav")
 ]),
 Album.new("30 #1 Hits", "Elvis Presley", "albums/elvis.jpg", [
 Track.new("Can't Help Falling in Love", "songs/elvis_1.wav")
 ]),
 Album.new("No. 6", "Ed Sheeran", "albums/ed.png", [
 Track.new("Beautiful People", "songs/ed_1.wav"),
 Track.new("I Don't Care", "songs/ed_2.wav")
 ]),
 Album.new("Midnights", "Taylor Swift", "albums/taylor.jpg", [
 Track.new("Midnight", "songs/taylor_1.wav"),
 Track.new("Snow On The Beach", "songs/taylor_2.wav"),
 Track.new("Lavendar Haze", "songs/taylor_3.wav")
 ]),
 Album.new("Narrated For You", "Alec Benjamin", "albums/alec.jpg", [
 Track.new("Let me down slowly", "songs/alec_1.wav"),
 Track.new("Water Fountain", "songs/alec_2.wav")
 ]),
 Album.new("Chase Atlantic", "Chase Atlantic", "albums/chase.jpg", [
 Track.new("Into It", "songs/chase_1.wav"),
 Track.new("Swim", "songs/chase_2.wav")
 ]),
 Album.new("The Eminem Show", "Eminem", "albums/eminem.jpg", [
 Track.new("Superman", "songs/em_1.wav")
 ]),
 Album.new("Starboy", "The Weekend", "albums/weekend.jpg", [
 Track.new("Starboy", "songs/weekend_1.wav"),
 Track.new("Stargirl Interlude", "songs/weekend_2.wav")
 ])
 # Add more albums as needed
 ]
 end

 def draw
 draw_background
 draw_albums
 draw_now_playing
 draw_controls
 end

 def draw_background
 Gosu.draw_rect(0, 0, 800, 600, Gosu::Color::BLACK)
 end

 def draw_albums
 @albums.each_with_index do |album, index|
 x = X_ALBUMS_START + (index % ALBUMS_PER_PAGE) * (ALBUM_SIZE + ALBUM_PADDING)
 y = Y_ALBUMS_START + (index / ALBUMS_PER_PAGE) * (ALBUM_SIZE + ALBUM_PADDING)
 draw_album(album, x, y)
 end
 end

 def draw_album(album, x, y)
 Gosu.draw_rect(x, y, ALBUM_SIZE, ALBUM_SIZE, Gosu::Color::WHITE)
 @font_album.draw_text(album.title, x + 10, y + 10, 1, 1, 1, Gosu::Color::BLACK)
 @font_album.draw_text(album.artist, x + 10, y + 40, 1, 1, 1, Gosu::Color::BLACK)
 end

 def draw_now_playing
 if @playing_track
 @font_now_playing.draw_text("Now Playing: #{@playing_track.name}", 50, 500, 1, 1, 1, Gosu::Color::WHITE)
 end
 end

 def draw_controls
 draw_volume_control
 draw_playback_controls
 draw_progress_bar
 draw_loop_shuffle
 end

 def draw_volume_control
 Gosu.draw_rect(650, 50, 100, 20, Gosu::Color::GRAY)
 Gosu.draw_rect(650, 50, @volume * 100, 20, Gosu::Color::GREEN)
 end

 def draw_playback_controls
 draw_button("Play", 650, 100)
 draw_button("Pause", 650, 150)
 draw_button("Next", 650, 200)
 draw_button("Prev", 650, 250)
 end

 def draw_button(text, x, y)
 Gosu.draw_rect(x, y, 100, 40, Gosu::Color::WHITE)
 @font_album.draw_text(text, x + 10, y + 10, 1, 1, 1, Gosu::Color::BLACK)
 end

 def draw_progress_bar
 if @playing_track
 progress = @playing_track.current_position / @playing_track.length
 Gosu.draw_rect(50, 550, 700, 20, Gosu::Color::GRAY)
 Gosu.draw_rect(50, 550, progress * 700, 20, Gosu::Color::GREEN)
 end
 end

 def draw_loop_shuffle
 draw_button("Loop", 650, 300)
 draw_button("Shuffle", 650, 350)
 end

 def update
 handle_input
 update_playing_track
 end

 def handle_input
 if Gosu.button_down?(Gosu::KB_LEFT)
 @album_page -= 1 if @album_page > 0
 elsif Gosu.button_down?(Gosu::KB_RIGHT)
 @album_page += 1 if @album_page < (@albums.size / ALBUMS_PER_PAGE)
 end
 end

 def update_playing_track
 if @playing_track && !@playing_track.playing?
 if @loop
 @playing_track.play
 elsif @shuffle
 play_random_track
 else
 play_next_track
 end
 end
 end

 def play_random_track
 @playing_track = @albums.sample.tracks.sample
 @playing_track.play
 end

 def play_next_track
 @playlist_index = (@playlist_index + 1) % @playlist.size
 @playing_track = @playlist[@playlist_index]
 @playing_track.play
 end

 def button_down(id)
 case id
 when Gosu::MsLeft
 handle_mouse_click(mouse_x, mouse_y)
 when Gosu::KB_SPACE
 toggle_play_pause
 end
 end

 def handle_mouse_click(x, y)
 if x.between?(650, 750)
 case y
 when 50..70
 adjust_volume(x)
 when 100..140
 play_track
 when 150..190
 pause_track
 when 200..240
 play_next_track
 when 250..290
 play_previous_track
 when 300..340
 toggle_loop
 when 350..390
 toggle_shuffle
 end
 else
 select_album_or_track(x, y)
 end
 end

 def adjust_volume(x)
 @volume = (x - 650) / 100.0
 @playing_track.volume = @volume if @playing_track
 end

 def play_track
 @playing_track.play if @playing_track
 end

 def pause_track
 @playing_track.pause if @playing_track
 end

 def play_previous_track
 @playlist_index = (@playlist_index - 1) % @playlist.size
 @playing_track = @playlist[@playlist_index]
 @playing_track.play
 end

 def toggle_loop
 @loop = !@loop
 end

 def toggle_shuffle
 @shuffle = !@shuffle
 end

 def select_album_or_track(x, y)
 @albums.each_with_index do |album, index|
 album_x = X_ALBUMS_START + (index % ALBUMS_PER_PAGE) * (ALBUM_SIZE + ALBUM_PADDING)
 album_y = Y_ALBUMS_START + (index / ALBUMS_PER_PAGE) * (ALBUM_SIZE + ALBUM_PADDING)
 if x.between?(album_x, album_x + ALBUM_SIZE) && y.between?(album_y, album_y + ALBUM_SIZE)
 @selected_album_index = index
 @playlist = album.tracks
 @playlist_index = 0
 @playing_track = @playlist[@playlist_index]
 @playing_track.play
 break
 end
 end
 end

 def toggle_play_pause
 if @playing_track
 if @playing_track.playing?
 @playing_track.pause
 else
 @playing_track.play
 end
 end
 end
end

MusicPlayer.new.show