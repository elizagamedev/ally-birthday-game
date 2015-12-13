require 'gosu'

require_relative 'graphic'

class GameOverScreen
  def initialize(win)
    @win = win
    
    @background = Graphic.new('gameover')
    @song = Gosu::Song.new('data/gameover.wav')
  end
  
  def reset
    @song.play
    @text = Graphic.new(Gosu::Image.from_text(@win.score.to_s, 20, {:font => 'data/TerminusTTF.ttf', :align => :center}))
  end
  
  def update
    @win.screen = :title if !@song.playing?
  end
  
  def draw
    @background.draw(0, 0, 0)
    @text.draw((640 - @text.width) / 2, 120 * 2, 1)
  end
  
  def button_down(id)
  end
  
  def button_up(id)
  end
end