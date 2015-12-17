require 'gosu'

require_relative 'title'
require_relative 'game'
require_relative 'gameover'

class GameWindow < Gosu::Window
  attr_accessor :score

  def initialize
    super 640, 480
    self.caption = "Ally's Birthday Counter-Assault"

    @screens = {:title => TitleScreen.new(self),
                :game => GameScreen.new(self),
                :gameover => GameOverScreen.new(self)}

    self.screen = :title
    @score = 0
  end

  def button_down(id)
    @screen.button_down(id)
  end

  def button_up(id)
    @screen.button_up(id)
  end

  def update
    @screen.update
  end

  def draw
    @screen.draw
  end

  # Members
  def screen=(name)
    @screen = @screens[name]
    @screen.reset
  end
end

window = GameWindow.new
window.show
