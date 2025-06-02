require 'gosu'

TOP_COLOR = Gosu::Color.argb(0xFFFADADD) # Light pink
BOTTOM_COLOR = Gosu::Color.argb(0xFFFFF0F5) # Lavender blush
SCREEN_WIDTH = 1000
SCREEN_HEIGHT = 1000

X_ALBUMS_START = 50
Y_ALBUMS_START = 20
ALBUM_SIZE = 250
ALBUM_PADDING = 20

X_TRACKS_START = 50
Y_TRACKS_START = 625

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
      Album.new("30 #1 Hits", "ELvis Presley", "albums/elvis.jpg", []),
      Album.new("No. 6", "Ed Sheeran", "albums/ed.png", [
        Track.new("Beautiful People", "songs/ed_1.mp3"),
        Track.new("I Don't Care", "songs/ed_2.mp3")
      ]),
      Album.new("Midnights", "Taylor Swift", "albums/taylor.jpg", [
        Track.new("Midnight", "songs/taylor_1.mp3"),
        Track.new("Snow On The Beach", "songs/taylor_2.mp3"),
        Track.new("Lavendar Haze", "songs/taylor_3.mp3")
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
    row = 0
    while row < 2
      col = 0
      while col < 2
        index = row * 2 + col
        if index < @albums.size
          album = @albums[index]
          x = X_ALBUMS_START + col * (ALBUM_SIZE + ALBUM_PADDING)
          y = Y_ALBUMS_START + row * (ALBUM_SIZE + ALBUM_PADDING)

          # Draw background frame (lower Z-order)
          Gosu.draw_rect(
            x - 10, y - 10,
            ALBUM_SIZE + 50, ALBUM_SIZE + 50,
            Gosu::Color.argb(0xFFFFF4E1), # soft yellow
            ZOrder[:background]
          )

          # Draw album artwork (higher Z-order)
          w = album.artwork.width.nonzero? || 1
          h = album.artwork.height.nonzero? || 1
          album.artwork.draw(
            x, y, ZOrder[:albums],
            ALBUM_SIZE.to_f / w,
            ALBUM_SIZE.to_f / h
          )
        end
        col += 1
      end
      row += 1
    end
  end

  def draw_track_list
    album = @albums[@selected_album_index]
    return unless album

    i = 0
    while i < album.tracks.length
      y = Y_TRACKS_START + i * 40
      color = (i == @playing_track_index) ? Gosu::Color.argb(0xFFDB7093) : Gosu::Color.argb(0xFF4B0082)
      @font_tracks.draw_text(album.tracks[i].name, X_TRACKS_START, y, ZOrder[:tracks], 1, 1, color)
      i += 1
    end
    
    if @playing_track_index
      now_playing = album.tracks[@playing_track_index].name
      Gosu.draw_rect(X_TRACKS_START - 10, Y_TRACKS_START - 50, 400, 35, Gosu::Color.argb(0xFFFFE4E1), ZOrder[:highlight])
     @font_now_playing.draw_text("Now playing: #{now_playing}", X_TRACKS_START, Y_TRACKS_START - 85, 50, ZOrder[:tracks], 1, 1, Gosu::Color.argb(0xFFDB7093))
    end
  end
 
  def draw_stop_button
    Gosu.draw_rect(SCREEN_WIDTH - 110, 20, 90, 30, Gosu::Color.argb(0xFFD6DBDF), ZOrder[:background])
    @font_now_playing.draw_text("Stop", SCREEN_WIDTH - 100, 25, ZOrder[:tracks], 1, 1, Gosu::Color::BLACK)
  end
 
  def button_down(id)
    if id == Gosu::MsLeft
      mx, my = mouse_x(), mouse_y()
      if mouse_x >= SCREEN_WIDTH - 110 && mouse_x <= SCREEN_WIDTH - 20 &&
        mouse_y >= 20 && mouse_y <= 50
        @current_track&.stop
        @playing_track_index = nil
        return
      end
      # Album selection
      row = 0
      while row < 2
        col = 0
        while col < 2
          index = row * 2 + col
          if index < @albums.size
            x = X_ALBUMS_START + col * (ALBUM_SIZE + ALBUM_PADDING)
            y = Y_ALBUMS_START + row * (ALBUM_SIZE + ALBUM_PADDING)
            if mx >= x && mx <= x + ALBUM_SIZE && my >= y && my <= y + ALBUM_SIZE
              @selected_album_index = index
              @playing_track_index = nil
              @current_track = nil
              return
            end
          end
          col += 1
        end
        row += 1
      end

      # Track selection
      album = @albums[@selected_album_index]
      i = 0
      while i < album.tracks.length
        y = Y_TRACKS_START + i * 40
        if @playing_track_index == i && @current_track
          @current_track.pause
          @playing_track_index = nil
          else
          @current_track&.stop
          @current_track = album.tracks[i].audio_file.play
          @playing_track_index = i
        end
      end
    end
  end
end

MusicPlayer.new.show
