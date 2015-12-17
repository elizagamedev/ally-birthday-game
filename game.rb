require 'gosu'

require_relative 'graphic'

class Buttons
  def initialize
    @pressed = {}
  end

  def reset
    @pressed = {}
  end

  def press(name)
    @pressed[name] = true if name
  end

  def release(name)
    @pressed[name] = false if name
  end

  def pressed?(name)
    return @pressed[name] ? true : false
  end
end

class Gib
  def initialize(anim, x, y, velocity)
    @anim = anim
    @lifetime = 60 * 5

    @x = x
    @y = y
    @giblet = rand(@anim.size)
    @mirror = rand(2) == 1
    @vel_x = rand(velocity * 2) - velocity
    @vel_y = rand(velocity * 2) - velocity
  end

  def update
    @x += @vel_x
    @y += @vel_y
    if @vel_x < 0
      @vel_x += 2
      @vel_x = 0 if @vel_x > 0
    elsif @vel_x > 0
      @vel_x -= 2
      @vel_x = 0 if @vel_x < 0
    end
    if @vel_y < 0
      @vel_y += 2
      @vel_y = 0 if @vel_y > 0
    elsif @vel_y > 0
      @vel_y -= 2
      @vel_y = 0 if @vel_y < 0
    end
    @lifetime -= 1
    return @lifetime <= 0
  end

  def draw(xshake, yshake)
    @anim.draw(@giblet, @x - 4 + xshake, @y - 4 + yshake, 2, @mirror)
  end
end

class Bullet
  attr_accessor :x
  attr_accessor :y

  def initialize(graphic, x, y, t_x, t_y)
    @graphic = graphic
    @x = x
    @y = y

    x_off = t_x - @x
    y_off = t_y - @y
    distance = Math.sqrt(x_off * x_off + y_off * y_off)
    @vel_x = (x_off / distance) * 20
    @vel_y = (y_off / distance) * 20
  end

  def update
    @x += @vel_x
    @y += @vel_y
    return @x < -8 || @x > 640 || @y < -8 || @y > 480
  end

  def draw(xshake, yshake)
    @graphic.draw(@x - 4 + xshake, @y - 4 + yshake, 100)
  end
end

class Ally
  attr_accessor :dir
  attr_accessor :x
  attr_accessor :y

  def initialize
    @anim = Animation.new('ally')
  end

  def reset
    @x = (640 - 32) / 2
    @y = (480 - 32) / 2
    @speed = 4
    @anim_speed = 12
    @anim_frame = 0
    @dir = :right
  end

  def update(btns)
    moving = false
    if btns.pressed? :left
      moving = true
      @x -= @speed
    end
    if btns.pressed? :right
      moving = true
      @x += @speed
    end
    if btns.pressed? :up
      moving = true
      @y -= @speed
    end
    if btns.pressed? :down
      moving = true
      @y += @speed
    end
    @x = 0 if @x < 0
    @x = 640 - 32 if @x > 640 - 32
    @y = 0 if @y < 0
    @y = 480 - 32 if @y > 480 - 32
    if moving
      @anim_frame = (@anim_frame + 1) % @anim_speed
    else
      @anim_frame = 0
    end
  end

  def draw(xshake, yshake)
    frame = @anim_frame / (@anim_speed / 2)
    @anim.draw(frame, @x + xshake, @y + yshake, 5, @dir == :left)
  end
end

class Monster
  attr_accessor :x
  attr_accessor :y

  def initialize(anim, x, y, speed)
    @anim = anim
    @x = x
    @y = y

    @hp = 2

    @speed = speed
    @anim_speed = 20 - speed.to_i * 2
    if @anim_speed < 2
      @anim_speed = 2
    end
    @anim_frame = 0
    @dir = :right
  end

  def update(ally)
    x_off = ally.x - @x
    y_off = ally.y - @y
    distance = Math.sqrt(x_off * x_off + y_off * y_off)
    @x += x_off / distance * @speed
    @y += y_off / distance * @speed
    if x_off < 0
      @dir = :left
    else
      @dir = :right
    end

    # Animate
    @anim_frame = (@anim_frame + 1) % @anim_speed
  end

  def draw(xshake, yshake)
    frame = @anim_frame / (@anim_speed / 2)
    @anim.draw(frame, @x + xshake, @y + yshake, 10, @dir == :left)
  end

  def get_hurt
    @hp -= 1
    return @hp <= 0
  end
end

class GameScreen
  def initialize(win)
    @win = win

    @bg = Graphic.new('grass')
    @crosshair = Graphic.new('crosshair', 1.0)
    @bullet = Graphic.new('bullet')

    @hit_sfx = Gosu::Sample.new('data/hit.wav')
    @explode_sfx = Gosu::Sample.new('data/explode.wav')
    @shoot_sfx = Gosu::Sample.new('data/shoot.wav')
    @die_sfx = Gosu::Sample.new('data/die.wav')

    @buttons = Buttons.new

    @ally = Ally.new
    @monster_anim = Animation.new('enemy')
    @gibs_anim = Animation.new('gibs', 4)

    @song = Gosu::Song.new('data/bgm.ogg')
  end

  def reset
    @dead = false
    @dead_timer = 0
    @score = 0
    @frame = 0
    @bullet_frame = 0

    @shake = 0

    @buttons.reset
    @ally.reset

    @monsters = []
    @bullets = []
    @gibs = []

    @song.play(true)
  end

  def update
    @aim_x = @win.mouse_x
    @aim_y = @win.mouse_y

    if !@dead
      @ally.update(@buttons)
      if @aim_x < @ally.x
        @ally.dir = :left
      else
        @ally.dir = :right
      end

      # Shoot
      if @buttons.pressed? :shoot
        if @bullet_frame % 8 == 0
          @shoot_sfx.play
          x = @ally.x + 2 * (@ally.dir == :right ? 15 : 1)
          y = @ally.y + 2 * 10
          @bullets << Bullet.new(@bullet, x, y, @aim_x, @aim_y)
        end
        @bullet_frame += 1
      else
        @bullet_frame = 0
      end

      # Spawn monsters
      if interval? 0.4
        case rand(4)
        when 0
          x = -32
          y = rand(480 - 32)
        when 1
          x = 640
          y = rand(480 - 32)
        when 2
          x = rand(640 - 32)
          y = -32
        when 3
          x = rand(640 - 32)
          y = 480
        end
        speed = @frame / (60 * 20).to_f + 0.5
        speed = 4 if speed > 4
        @monsters << Monster.new(@monster_anim, x, y, speed)
      end
    end

    # Move gibs
    @gibs.each do |gib|
      @gibs.delete gib if gib.update
    end

    # Move monsters
    if !@dead
      @monsters.each do |monster|
        monster.update(@ally)
        if (monster.x - @ally.x).abs < 16 && (monster.y - @ally.y).abs < 16
          @die_sfx.play
          @song.stop
          @dead = true
          (100).times do |i|
              @gibs << Gib.new(@gibs_anim, monster.x + 16, monster.y + 16, 48)
          end
        end
      end
    end

    # Update bullets, hit monsters
    @bullets.each do |bullet|
      @bullets.delete bullet if bullet.update
      @monsters.each do |monster|
        if bullet.x > monster.x && bullet.x < monster.x + 32 \
            && bullet.y > monster.y && bullet.y < monster.y + 32
          @bullets.delete bullet
          if monster.get_hurt
            @explode_sfx.play
            @score += 1
            @shake += 6
            @monsters.delete monster
            (rand(12) + 12).times do |i|
              @gibs << Gib.new(@gibs_anim, monster.x + 16, monster.y + 16, 32)
            end
          else
            @hit_sfx.play
          end
        end
      end
    end

    @frame += 1
    if @dead
      @dead_timer += 1
      if @dead_timer >= 60 * 2
        @win.score = @score
        @win.screen = :gameover
      end
    end
  end

  def draw
    if @shake > 0
      shake_angle = rand(0..(Math::PI * 2))
      shake_x = @shake * Math.cos(shake_angle)
      shake_y = @shake * Math.sin(shake_angle)
    else
      shake_x = 0
      shake_y = 0
    end

    @bg.draw(shake_x, shake_y, 0)
    @monsters.each { |m| m.draw(shake_x, shake_y) }
    @ally.draw(shake_x, shake_y) if !@dead
    @crosshair.draw(@win.mouse_x - 8, @win.mouse_y - 8, 100) if !@dead
    @bullets.each { |b| b.draw(shake_x, shake_y) }
    @gibs.each { |g| g.draw(shake_x, shake_y) }

    @shake -= 1 if @shake > 0
  end

  # Buttons
  def button_symbol(id)
    case id
    when Gosu::KbLeft, Gosu::KbA
      return :left
    when Gosu::KbRight, Gosu::KbD
      return :right
    when Gosu::KbUp, Gosu::KbW
      return :up
    when Gosu::KbDown, Gosu::KbS
      return :down
    when Gosu::MsLeft
      return :shoot
    end
  end

  def button_down(id)
    @buttons.press(button_symbol id)
  end

  def button_up(id)
    @buttons.release(button_symbol id)
  end

  # Frame operations
  def interval?(seconds)
    @frame % (seconds * 60).to_i == 0
  end
end
