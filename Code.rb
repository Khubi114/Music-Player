require 'gosu'

# === Constants ===
TOP_COLOR = Gosu::Color.argb(0xFF87CEEB)
BOTTOM_COLOR = Gosu::Color.argb(0xFF4682B4)
SCREEN_WIDTH = 1200
SCREEN_HEIGHT = 800

X_ALBUMS_START = 50
Y_ALBUMS_START = 20
ALBUM_SIZE = 200
ALBUM_PADDING = 80

X_TRACKS_START = 620
Y_TRACKS_START = 80

ALBUMS_PER_ROW = 2
ALBUMS_PER_COL = 2
ALBUMS_PER_PAGE = ALBUMS_PER_ROW * ALBUMS_PER_COL

ZOrder = { background: 0, albums: 1, highlight: 2, tracks: 3 }

def safe_image_load(path)
  Gosu::Image.new(path)
rescue
  Gosu::Image.new(1, 1)
end

class Album
  attr_accessor :title, :artist, :artwork, :tracks

  def initialize(title, artist, artwork_file, tracks)
    @title = title
    @artist = artist
    @artwork = safe_image_load(artwork_file)
    @tracks = tracks
  end
end

class Track
  attr_accessor :name, :audio_file

  def initialize(name, audio_file)
    @name = name
    @audio_file = Gosu::Sample.new(audio_file)
  end
end

class MusicPlayer < Gosu::Window
  def initialize
    super SCREEN_WIDTH, SCREEN_HEIGHT
    self.caption = "Music Player"

    @albums = load_albums
    @font_tracks = Gosu::Font.new(26, name: "Courier")
    @font_now_playing = Gosu::Font.new(22, name: "Courier")
    @font_album = Gosu::Font.new(18, name: "Courier")

    @selected_album_index = nil      # No album selected at startup
    @playing_track_index = nil
    @current_track = nil

    @album_page = 0
    @volume = 0.5
    @loop = false
    @shuffle = false
  end

  def load_albums
    [
      Album.new("AM", "Arctic Monkeys", "albums/arctic.jpg", [
        Track.new("Do I Wanna Know?", "songs/arctic_1.wav"),
        Track.new("Why'd You Only Call Me When You're High?", "songs/arctic_2.wav"),
        Track.new("I Wanna Be Yours", "songs/arctic_3.wav")
      ]),
      Album.new("30 #1 Hits", "Elvis Presley", "albums/elvis.jpg", [
        Track.new("Can't Help Falling in Love", "songs/elvis_1.wav")
      ]),
      Album.new("No. 6", "Ed Sheeran", "albums/ed.png", [
        Track.new("Beautiful People", "songs/ed_1.wav"),
        Track.new("I Don't Care", "songs/ed_2.wav")
      ]),
      Album.new("Midnights", "Taylor Swift", "albums/taylor.jpg", [
        Track.new("Midnight Rain", "songs/taylor_1.wav"),
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
    ]
  end

  def draw
    draw_gradient_background
    draw_album_grid
    draw_track_list
    draw_album_paging_buttons
    draw_controls
  end

  def draw_gradient_background
    draw_quad(
      0, 0, TOP_COLOR,
      0, SCREEN_HEIGHT, BOTTOM_COLOR,
      SCREEN_WIDTH, 0, TOP_COLOR,
      SCREEN_WIDTH, SCREEN_HEIGHT, BOTTOM_COLOR,
      ZOrder[:background]
    )
  end

  def draw_album_grid
    start_index = @album_page * ALBUMS_PER_PAGE
    end_index = [start_index + ALBUMS_PER_PAGE, @albums.size].min
    row = 0
    col = 0
    (start_index...end_index).each do |index|
      album = @albums[index]
      x = X_ALBUMS_START + col * (ALBUM_SIZE + ALBUM_PADDING)
      y = Y_ALBUMS_START + row * (ALBUM_SIZE + ALBUM_PADDING)

      Gosu.draw_rect(
        x - 25, y - 10,
        ALBUM_SIZE + 50, ALBUM_SIZE + 70,
        Gosu::Color.argb(0xFFB0E0E6),
        ZOrder[:background]
      )

      album.artwork.draw(
        x, y, ZOrder[:albums],
        ALBUM_SIZE.to_f / album.artwork.width,
        ALBUM_SIZE.to_f / album.artwork.height
      )

      @font_album.draw_text(album.title, x, y + ALBUM_SIZE + 10, ZOrder[:albums], 1, 1, Gosu::Color.argb(0xFF001382))
      @font_album.draw_text(album.artist, x, y + ALBUM_SIZE + 35, ZOrder[:albums], 1, 1, Gosu::Color.argb(0xFF709DDB))

      col += 1
      if col >= ALBUMS_PER_ROW
        col = 0
        row += 1
      end
    end
  end

  def draw_track_list
    return if @selected_album_index.nil? || @albums[@selected_album_index].nil?
    album = @albums[@selected_album_index]

    album.tracks.each_with_index do |track, i|
      y = Y_TRACKS_START + i * 40
      text_width = @font_tracks.text_width(track.name, 1)
      # Draw highlight for the selected track
      if i == @playing_track_index
        Gosu.draw_rect(X_TRACKS_START - 10, y - 5, text_width + 20, 35, Gosu::Color.argb(0x66FFE4E1), ZOrder[:highlight])
      end
      color = (i == @playing_track_index) ? Gosu::Color.argb(0xFF709DDB) : Gosu::Color.argb(0xFF001382)
      @font_tracks.draw_text(track.name, X_TRACKS_START, y, ZOrder[:tracks], 1, 1, color)
    end

    x = X_TRACKS_START - 5
    y = Y_TRACKS_START - 50
    color = Gosu::Color.argb(0xFF001382)

    if @playing_track_index
      now_playing = album.tracks[@playing_track_index].name
      text = "Now playing: #{now_playing}"
    else
      text = "Tracks"
    end

    @font_now_playing.draw_text(text, x, y, ZOrder[:tracks], 1, 1, color)
    text_width = @font_now_playing.text_width(text, 1)
    # Draw underline
    Gosu.draw_line(x, y + 26, color, x + text_width, y + 26, color, ZOrder[:tracks])
  end

  def draw_album_paging_buttons
    y_offset = Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) + 60

    # Prev button
    prev_enabled = @album_page > 0
    prev_color = prev_enabled ? Gosu::Color.argb(0xFF4682B4) : Gosu::Color.argb(0xFFB0C4DE)
    Gosu.draw_rect(X_ALBUMS_START, y_offset, 100, 40, prev_color, ZOrder[:background])
    @font_now_playing.draw_text("Prev", X_ALBUMS_START + 20, y_offset + 5, ZOrder[:albums], 1, 1, Gosu::Color::WHITE)

    # Next button
    next_enabled = (@album_page + 1) * ALBUMS_PER_PAGE < @albums.size
    next_color = next_enabled ? Gosu::Color.argb(0xFF4682B4) : Gosu::Color.argb(0xFFB0C4DE)
    Gosu.draw_rect(X_ALBUMS_START + 150, y_offset, 100, 40, next_color, ZOrder[:background])
    @font_now_playing.draw_text("Next", X_ALBUMS_START + 170, y_offset + 5, ZOrder[:albums], 1, 1, Gosu::Color::WHITE)

    # --- Page number display ---
    total_pages = (@albums.size.to_f / ALBUMS_PER_PAGE).ceil
    page_text = "Page #{@album_page + 1} / #{total_pages}"
    @font_now_playing.draw_text(page_text, X_ALBUMS_START + 50, y_offset + 50, ZOrder[:albums], 1, 1, Gosu::Color.argb(0xFF001382))
  end

  def draw_controls
    draw_button("Play", 600, 300)
    draw_button("Pause", 600, 350)
    draw_button("Loop", 600, 400)
    draw_button("Shuffle", 600, 450)
    draw_volume_bar 
  end

  def draw_button(text, x, y)
    color =
      if (text == "Loop" && @loop) || (text == "Shuffle" && @shuffle)
        Gosu::Color.argb(0xFF1E90FF) # bright blue for active
      else
        Gosu::Color.argb(0xFF87CEEB) # sky blue for normal
      end
    Gosu.draw_rect(x, y, 100, 40, color)
    @font_album.draw_text(text, x + 10, y + 10, ZOrder[:albums], 1, 1, Gosu::Color.argb(0xFF154360))
  end

  def draw_volume_bar
    Gosu.draw_rect(600, 500, 100, 20, Gosu::Color.argb(0xFF4682B4)) # steel blue
    Gosu.draw_rect(600, 500, @volume * 100, 20, Gosu::Color.argb(0xFF1E90FF)) # dodger blue
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
    # --- Controls on the right ---
    # Volume bar (600, 500, width 100, height 20)
    if x.between?(600, 700) && y.between?(500, 520)
      adjust_volume(x)
      return
    end

    # Play button (600, 300, 100x40)
    if x.between?(600, 700) && y.between?(300, 340)
      play_track
      return
    end

    # Pause button (600, 350, 100x40)
    if x.between?(600, 700) && y.between?(350, 390)
      pause_track
      return
    end

    # Loop button (600, 400, 100x40)
    if x.between?(600, 700) && y.between?(400, 440)
      toggle_loop
      return
    end

    # Shuffle button (600, 450, 100x40)
    if x.between?(600, 700) && y.between?(450, 490)
      toggle_shuffle
      return
    end

    # --- Paging buttons at the bottom ---
    y_offset = Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) + 60

    # Prev button
    if @album_page > 0 &&
       x.between?(X_ALBUMS_START, X_ALBUMS_START + 100) &&
       y.between?(y_offset, y_offset + 40)
      @album_page -= 1
      @selected_album_index = nil
      @playing_track_index = nil
      @current_track&.stop
      @current_track = nil
      return
    end

    # Next button
    if (@album_page + 1) * ALBUMS_PER_PAGE < @albums.size &&
       x.between?(X_ALBUMS_START + 150, X_ALBUMS_START + 250) &&
       y.between?(y_offset, y_offset + 40)
      @album_page += 1
      @selected_album_index = nil
      @playing_track_index = nil
      @current_track&.stop
      @current_track = nil
      return
    end

    # --- Album selection (paged) ---
    start_index = @album_page * ALBUMS_PER_PAGE
    end_index = [start_index + ALBUMS_PER_PAGE, @albums.size].min
    row = 0
    col = 0
    (start_index...end_index).each do |index|
      album_x = X_ALBUMS_START + col * (ALBUM_SIZE + ALBUM_PADDING)
      album_y = Y_ALBUMS_START + row * (ALBUM_SIZE + ALBUM_PADDING)
      if x.between?(album_x, album_x + ALBUM_SIZE) && y.between?(album_y, album_y + ALBUM_SIZE)
        @current_track&.stop
        @selected_album_index = index
        @playing_track_index = nil
        @current_track = nil
        return
      end
      col += 1
      if col >= ALBUMS_PER_ROW
        col = 0
        row += 1
      end
    end

    # --- Track selection ---
    return if @selected_album_index.nil? || @albums[@selected_album_index].nil?
    album = @albums[@selected_album_index]
    album.tracks.each_with_index do |track, i|
      track_y = Y_TRACKS_START + i * 40
      if y.between?(track_y, track_y + 30) && x.between?(X_TRACKS_START, X_TRACKS_START + 400)
        @current_track&.stop
        @current_track = track.audio_file.play(@volume)
        @playing_track_index = i
        return
      end
    end
  end

  def play_track
    return if @selected_album_index.nil? || @albums[@selected_album_index].nil?
    album = @albums[@selected_album_index]
    if @playing_track_index
      @current_track&.stop
      @current_track = album.tracks[@playing_track_index].audio_file.play(@volume)
    elsif album.tracks.any?
      @playing_track_index = 0
      @current_track&.stop
      @current_track = album.tracks[0].audio_file.play(@volume)
    end
  end

  def pause_track
    # Gosu::SampleInstance does not support true pause, so we stop playback
    @current_track&.stop
    @current_track = nil
  end

  def toggle_loop
    @loop = !@loop
  end

  def toggle_shuffle
    @shuffle = !@shuffle
  end

  def toggle_play_pause
    if @current_track
      pause_track
    else
      play_track
    end
  end

  def adjust_volume(x)
    @volume = [[(x - 600) / 100.0, 0.0].max, 1.0].min
    @current_track&.volume = @volume
  end

  def update
    # If a track is playing, check if it has finished
    if @current_track && !@current_track.playing?
      album = @albums[@selected_album_index]
      if @loop
        # Replay the same track
        @current_track = album.tracks[@playing_track_index].audio_file.play(@volume)
      elsif @shuffle
        # Pick a random track from the album (not the same one)
        next_index = rand(album.tracks.size)
        next_index = rand(album.tracks.size) while album.tracks.size > 1 && next_index == @playing_track_index
        @playing_track_index = next_index
        @current_track = album.tracks[@playing_track_index].audio_file.play(@volume)
      else
        # Play next track in album, or stop if at end
        if @playing_track_index && @playing_track_index < album.tracks.size - 1
          @playing_track_index += 1
          @current_track = album.tracks[@playing_track_index].audio_file.play(@volume)
        else
          @current_track = nil
          @playing_track_index = nil
        end
      end
    end
  end
end

MusicPlayer.new.show
