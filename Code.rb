
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF57A0DC)
BOTTOM_COLOR = Gosu::Color.new(0xFF0B3D91)
SCREEN_WIDTH = 900
SCREEN_HEIGHT = 600

X_ALBUMS_START = 20
Y_ALBUMS_START = 20
ALBUM_SIZE = 250
ALBUM_PADDING = 20

X_TRACKS_START = 560
Y_TRACKS_START = 50

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
    @font_tracks = Gosu::Font.new(30)
    @font_now_playing = Gosu::Font.new(25)

    @selected_album_index = 0
    @playing_track_index = nil
    @current_track = nil
  end

  def load_albums
    [
      Album.new("Greatest Hits", "Neil Diamond", "media/NeilDiamond.png", [
        Track.new("Crackling Rose", "media/CracklingRose.mp3"),
        Track.new("Soolaimon", "media/Soolaimon.mp3"),
        Track.new("Sweet Caroline", "media/SweetCaroline.mp3")
      ]),
      Album.new("American Pie", "Don McClean", "media/DonMcClean.png", []),
      Album.new("Greatest Hits", "Platters", "media/ThePlatters.png", [
        Track.new("Twilight Time", "media/TwilightTime.mp3"),
        Track.new("The Great Pretender", "media/TheGreatPretender.mp3")
      ]),
      Album.new("No Secrets", "Carly Simon", "media/CarlySimon.png", [
        Track.new("The Carter Family", "media/TheCarterFamily.mp3"),
        Track.new("Your So Vain", "media/YourSoVain.mp3"),
        Track.new("Embrace Me You Child", "media/EmbraceMeYouChild.mp3")
      ])
    ]
  end

  def draw
    draw_gradient_background
    draw_album_grid
    draw_track_list
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
          album.artwork.draw(
            x, y, ZOrder[:albums],
            ALBUM_SIZE.to_f / album.artwork.width,
            ALBUM_SIZE.to_f / album.artwork.height
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
      color = (i == @playing_track_index) ? Gosu::Color::RED : Gosu::Color::BLACK
      @font_tracks.draw_text(album.tracks[i].name, X_TRACKS_START, y, ZOrder[:tracks], 1, 1, color)
      i += 1
    end

    if @playing_track_index
      now_playing = album.tracks[@playing_track_index].name
      @font_now_playing.draw_text("Now playing: #{now_playing}", X_TRACKS_START, Y_TRACKS_START - 40, ZOrder[:tracks], 1, 1, Gosu::Color::RED)
    end
  end

  def button_down(id)
    if id == Gosu::MsLeft
      mx, my = mouse_x(), mouse_y()

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
        if my >= y && my <= y + 30 && mx >= X_TRACKS_START && mx <= X_TRACKS_START + 300
          @playing_track_index = i
          @current_track = album.tracks[i].audio_file.play
          return
        end
        i += 1
      end
    end
  end
end

MusicPlayer.new.show
