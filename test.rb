require 'gosu'

TOP_COLOR = Gosu::Color.argb(0xFFFADADD)
BOTTOM_COLOR = Gosu::Color.argb(0xFFFFF0F5)
SCREEN_WIDTH = 2000
SCREEN_HEIGHT = 2000

X_TRACKS_START = 700
Y_TRACKS_START = 70
ALBUM_SIZE = 250
ALBUM_PADDING = 20

ZOrder = { background: 0, albums: 1, tracks: 2, highlight: 3 }

class Album
  attr_accessor :title, :artist, :artwork, :tracks

  def initialize(title, artist, artwork_file, tracks)
    @title = title
    @artist = artist
    @artwork = Gosu::Image.new(artwork_file)
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
    @font_tracks = Gosu::Font.new(28, name: Gosu.default_font_name)
    @font_now_playing = Gosu::Font.new(24, name: Gosu.default_font_name)

    @selected_album_index = 0
    @playing_track_index = nil
    @current_track = nil
  end

  def load_albums
    [
      Album.new("AM", "Arctic Monkeys", "albums/arctic.jpg", [
        Track.new("Do I Wanna Know?", "songs/arctic_1.mp3"),
        Track.new("I Wanna Be Yours", "songs/arctic_2.mp3"),
        Track.new("Why'd You Only Call Me When You're High?", "songs/arctic_3.mp3")
      ]),
      Album.new("30 #1 Hits", "Elvis Presley", "albums/elvis.jpg", []),
      Album.new("No. 6", "Ed Sheeran", "albums/ed.png", [
        Track.new("Beautiful People", "songs/ed_1.mp3"),
        Track.new("I Don't Care", "songs/ed_2.mp3")
      ]),
      Album.new("Midnights", "Taylor Swift", "albums/taylor.jpg", [
        Track.new("Midnight", "songs/taylor_1.mp3"),
        Track.new("Snow On The Beach", "songs/taylor_2.mp3"),
        Track.new("Lavender Haze", "songs/taylor_3.mp3")
      ])
    ]
  end

  def draw
    draw_gradient_background
    draw_album_grid
    draw_track_list
    draw_stop_button
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
    cols = 3
    album_width = ALBUM_SIZE + ALBUM_PADDING
    start_x = (SCREEN_WIDTH - (cols * album_width - ALBUM_PADDING)) / 2
    start_y = 20

    @albums.each_with_index do |album, index|
      col = index % cols
      row = index / cols
      x = start_x + col * album_width
      y = start_y + row * album_width

      Gosu.draw_rect(x - 10, y - 10, ALBUM_SIZE + 50, ALBUM_SIZE + 50, Gosu::Color.argb(0xFFFFF4E1), ZOrder[:background])
      w = album.artwork.width.nonzero? || 1
      h = album.artwork.height.nonzero? || 1
      album.artwork.draw(x, y, ZOrder[:albums], ALBUM_SIZE.to_f / w, ALBUM_SIZE.to_f / h)

      if mouse_over_album?(x, y)
        Gosu.draw_rect(x, y, ALBUM_SIZE, ALBUM_SIZE, Gosu::Color.argb(0x55FFFFFF), ZOrder[:highlight])
      end
    end
  end

  def draw_track_list
    album = @albums[@selected_album_index]
    return unless album

    if album.tracks.empty?
      @font_tracks.draw_text("No tracks available", X_TRACKS_START, Y_TRACKS_START, ZOrder[:tracks], 1, 1, Gosu::Color::GRAY)
      return
    end

    album.tracks.each_with_index do |track, i|
      y = Y_TRACKS_START + i * 40
      color = (i == @playing_track_index) ? Gosu::Color.argb(0xFFDB7093) : Gosu::Color.argb(0xFF4B0082)
      @font_tracks.draw_text(track.name, X_TRACKS_START, y, ZOrder[:tracks], 1, 1, color)
    end

    if @playing_track_index
      now_playing = album.tracks[@playing_track_index].name
      Gosu.draw_rect(X_TRACKS_START - 10, Y_TRACKS_START - 50, 400, 35, Gosu::Color.argb(0xFFFFE4E1), ZOrder[:highlight])
      @font_now_playing.draw_text("Now playing: #{now_playing}", X_TRACKS_START, Y_TRACKS_START - 45, ZOrder[:tracks], 1, 1, Gosu::Color.argb(0xFFDB7093))
    end
  end

  def draw_stop_button
    Gosu.draw_rect(SCREEN_WIDTH - 110, 20, 90, 30, Gosu::Color::GRAY, ZOrder[:highlight])
    @font_now_playing.draw_text("Stop", SCREEN_WIDTH - 100, 25, ZOrder[:tracks], 1, 1, Gosu::Color::WHITE)
  end

  def button_down(id)
    return unless id == Gosu::MsLeft
    mx, my = mouse_x, mouse_y

    # Stop button
    if mx >= SCREEN_WIDTH - 110 && mx <= SCREEN_WIDTH - 20 && my >= 20 && my <= 50
      @current_track&.stop
      @playing_track_index = nil
      return
    end

    # Album selection
    cols = 3
    album_width = ALBUM_SIZE + ALBUM_PADDING
    start_x = (SCREEN_WIDTH - (cols * album_width - ALBUM_PADDING)) / 2
    start_y = 20

    @albums.each_with_index do |album, index|
      col = index % cols
      row = index / cols
      x = start_x + col * album_width
      y = start_y + row * album_width

      if mouse_over_album?(x, y)
        @selected_album_index = index
        @playing_track_index = nil
        @current_track&.stop
        @current_track = nil
        return
      end
    end

    # Track selection
    album = @albums[@selected_album_index]
    album.tracks.each_with_index do |track, i|
      y = Y_TRACKS_START + i * 40
      if my >= y && my <= y + 30 && mx >= X_TRACKS_START && mx <= X_TRACKS_START + 300
        if @playing_track_index == i && @current_track
          @current_track.pause
          @playing_track_index = nil
        else
          @current_track&.stop
          @current_track = track.audio_file.play
          @playing_track_index = i
        end
        return
      end
    end
  end

  def mouse_over_album?(x, y)
    mouse_x >= x && mouse_x <= x + ALBUM_SIZE &&
    mouse_y >= y && mouse_y <= y + ALBUM_SIZE
  end
end

MusicPlayer.new.show
