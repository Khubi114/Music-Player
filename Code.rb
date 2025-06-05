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

ALBUMS_PER_ROW = 2
ALBUMS_PER_COL = 2
ALBUMS_PER_PAGE = ALBUMS_PER_ROW * ALBUMS_PER_COL

ZOrder = { background: 0, albums: 1, tracks: 2, highlight: 3 }

def safe_image_load(path)
  Gosu::Image.new(path)
rescue
  Gosu::Image.new(1, 1) # 1x1 transparent pixel as placeholder
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
    @font_tracks = Gosu::Font.new(28, name: Gosu.default_font_name)
    @font_now_playing = Gosu::Font.new(24, name: Gosu.default_font_name)
    @font_album = Gosu::Font.new(20, name: Gosu.default_font_name)

    @selected_album_index = 0
    @playing_track_index = nil
    @current_track = nil

    @album_page = 0
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
    draw_gradient_background
    draw_album_grid
    draw_track_list
    draw_stop_button
    draw_album_paging_buttons
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

      # Draw background frame
      Gosu.draw_rect(
        x - 10, y - 10,
        ALBUM_SIZE + 50, ALBUM_SIZE + 50,
        Gosu::Color.argb(0xFFFFF4E1),
        ZOrder[:background]
      )

      # Draw album artwork
      w = album.artwork.width.nonzero? || 1
      h = album.artwork.height.nonzero? || 1
      album.artwork.draw(
        x, y, ZOrder[:albums],
        ALBUM_SIZE.to_f / w,
        ALBUM_SIZE.to_f / h
      )

      # Draw album title and artist
      @font_album.draw_text(album.title, x, y + ALBUM_SIZE + 10, ZOrder[:albums], 1, 1, Gosu::Color::BLACK)
      @font_album.draw_text(album.artist, x, y + ALBUM_SIZE + 35, ZOrder[:albums], 1, 1, Gosu::Color::GRAY)

      col += 1
      if col >= ALBUMS_PER_ROW
        col = 0
        row += 1
      end
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
      @font_now_playing.draw_text("Now playing: #{now_playing}", X_TRACKS_START, Y_TRACKS_START - 85, ZOrder[:tracks], 1, 1, Gosu::Color.argb(0xFFDB7093))
    end
  end

  def draw_stop_button
    Gosu.draw_rect(SCREEN_WIDTH - 110, 20, 90, 30, Gosu::Color.argb(0xFFD6DBDF), ZOrder[:background])
    @font_now_playing.draw_text("Stop", SCREEN_WIDTH - 100, 25, ZOrder[:tracks], 1, 1, Gosu::Color::BLACK)
  end

  def draw_album_paging_buttons
    # Previous
    if @album_page > 0
      Gosu.draw_rect(X_ALBUMS_START, Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)), 100, 40, Gosu::Color::GRAY, ZOrder[:background])
      @font_now_playing.draw_text("Prev", X_ALBUMS_START + 20, Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) + 5, ZOrder[:albums], 1, 1, Gosu::Color::WHITE)
    end
    # Next
    if (@album_page + 1) * ALBUMS_PER_PAGE < @albums.size
      Gosu.draw_rect(X_ALBUMS_START + 150, Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)), 100, 40, Gosu::Color::GRAY, ZOrder[:background])
      @font_now_playing.draw_text("Next", X_ALBUMS_START + 170, Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) + 5, ZOrder[:albums], 1, 1, Gosu::Color::WHITE)
    end
  end

  def button_down(id)
    if id == Gosu::MsLeft
      mx, my = mouse_x(), mouse_y()

      # Stop button
      if mx >= SCREEN_WIDTH - 110 && mx <= SCREEN_WIDTH - 20 &&
         my >= 20 && my <= 50
        @current_track&.stop
        @playing_track_index = nil
        return
      end

      # Album paging buttons
      if @album_page > 0 &&
         mx >= X_ALBUMS_START && mx <= X_ALBUMS_START + 100 &&
         my >= Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) &&
         my <= Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) + 40
        @album_page -= 1
        return
      end
      if (@album_page + 1) * ALBUMS_PER_PAGE < @albums.size &&
         mx >= X_ALBUMS_START + 150 && mx <= X_ALBUMS_START + 250 &&
         my >= Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) &&
         my <= Y_ALBUMS_START + (ALBUMS_PER_COL * (ALBUM_SIZE + ALBUM_PADDING)) + 40
        @album_page += 1
        return
      end

      # Album selection (paged)
      start_index = @album_page * ALBUMS_PER_PAGE
      end_index = [start_index + ALBUMS_PER_PAGE, @albums.size].min
      row = 0
      col = 0
      (start_index...end_index).each do |index|
        x = X_ALBUMS_START + col * (ALBUM_SIZE + ALBUM_PADDING)
        y = Y_ALBUMS_START + row * (ALBUM_SIZE + ALBUM_PADDING)
        if mx >= x && mx <= x + ALBUM_SIZE && my >= y && my <= y + ALBUM_SIZE
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

      # Track selection
      album = @albums[@selected_album_index]
      i = 0
      while i < album.tracks.length
        y = Y_TRACKS_START + i * 40
        if my >= y && my <= y + 30 && mx >= X_TRACKS_START && mx <= X_TRACKS_START + 400
          @current_track&.stop
          @current_track = album.tracks[i].audio_file.play
          @playing_track_index = i
          return
        end
        i += 1
      end
    end
  end
end

MusicPlayer.new.show
