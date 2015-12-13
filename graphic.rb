require 'gosu'
require 'opengl'

class Graphic
  def initialize(value, scale = 2.0)
    if value.is_a? String
      @image = Gosu::Image.new('data/' + value + '.png')
    elsif value.is_a? Gosu::Image
      @image = value
    else
      raise 'invalid value passed to Graphic.initialize'
    end
    GL::BindTexture(GL::GL_TEXTURE_2D, @image.gl_tex_info.tex_name)
    GL::TexParameteri(GL::GL_TEXTURE_2D, GL::GL_TEXTURE_MIN_FILTER, GL::GL_NEAREST)
    GL::TexParameteri(GL::GL_TEXTURE_2D, GL::GL_TEXTURE_MAG_FILTER, GL::GL_NEAREST)
    @scale = scale
  end
  
  def draw(x, y, z, mirror = false)
    @image.draw((mirror ? @image.width * @scale : 0) + x, y, z, (mirror ? -1 : 1 ) * @scale, @scale)
  end
  
  def width
    @image.width
  end
  
  def height
    @image.height
  end
end

class Animation
  def initialize(name, tile_size = 16)
    images = Gosu::Image.load_tiles(Gosu::Image.new('data/' + name + '.png'), tile_size, tile_size)
    @graphics = Array.new(images.size)
    images.each_with_index do |image, i|
      @graphics[i] = Graphic.new(image)
    end
  end
  
  def draw(frame, x, y, z, mirror = false)
    @graphics[frame].draw(x, y, z, mirror)
  end
  
  def size
    @graphics.size
  end
end