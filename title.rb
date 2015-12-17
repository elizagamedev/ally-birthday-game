require 'gosu'

require_relative 'graphic'

class TitleScreen
  def initialize(win)
    @win = win

    @background = Graphic.new('title')
    @song = Gosu::Song.new('data/title.ogg')
  end

  def reset
    @song.play(true)
  end

  def update
  end

  def draw
    @background.draw(0, 0, 0)
  end

  def button_down(id)
    @win.screen = :game
  end

  def button_up(id)
  end
end
