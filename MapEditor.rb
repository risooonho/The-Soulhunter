require 'gosu'
include Gosu

SZ = 30

def get_value(name, source, start)
	line = source.find{|line| line.start_with?(name)}
	{value: eval(line.split(/=\s*/).last), index: source.index(line) + start}
end

MAPS = []

(Dir.entries("Maps") - [".", ".."]).each do |file|
	lines = File.readlines("Maps/" + file)
	start = lines.find_index{|line| line.start_with?("map_x")}
	stop = lines.find_index{|line| line.start_with?("borders")}
	extract = lines[start..stop]
	
	MAPS << {map_x: get_value("map_x", extract, start), map_y: get_value("map_y", extract, start),
		width: get_value("width", extract, start), height: get_value("height", extract, start), file: file,
		borders: get_value("borders", extract, start)}
end

def get_border(borders, dir, i)
	borders[i*4 + dir] ||= 0
end

def set_border(borders, dir, i, val)
	borders[i*4 + dir] = val
end

def img(name)
	$_images ||= {}
	$_images[name] ||= Image.new(name + ".png")
end

class GameWindow < Window
	def initialize
		super(800, 600, false)
		self.caption = "Map Editor"
		@scx = @scy = 32758
	end

	def update
	end

	def draw
		i = 0
		translate(-@scx * SZ, -@scy * SZ) do
			MAPS.each do |room|
				room[:width][:value].times do |dx|
					room[:height][:value].times do |dy|
						x = room[:map_x][:value]
						y = room[:map_y][:value]
						w = room[:width][:value]
						h = room[:height][:value]
						border = lambda{|dir| get_border(room[:borders][:value], dir, dx + dy*w)}
						
						img("Graphics/Map/Room").draw((x + dx) * SZ, (y + dy) * SZ, 0, 1, 1, Color.from_hsv(i*20%360, 1, 1))
						
						img("Graphics/Map/#{border.call(0) == 1 ? 'Wall' : 'Way'}").draw_rot((x + dx) * SZ + SZ/2, (y + dy) * SZ + SZ/2, 0, 0, 0.5, 0.5, 1, 1, Color::RED) if border.call(0) > 0
						img("Graphics/Map/#{border.call(1) == 1 ? 'Wall' : 'Way'}").draw_rot((x + dx) * SZ + SZ/2, (y + dy) * SZ + SZ/2, 0, 90, 0.5, 0.5, 1, 1, Color::RED) if border.call(1) > 0
						img("Graphics/Map/#{border.call(2) == 1 ? 'Wall' : 'Way'}").draw_rot((x + dx) * SZ + SZ/2, (y + dy) * SZ + SZ/2, 0, 180, 0.5, 0.5, 1, 1, Color::RED) if border.call(2) > 0
						img("Graphics/Map/#{border.call(3) == 1 ? 'Wall' : 'Way'}").draw_rot((x + dx) * SZ + SZ/2, (y + dy) * SZ + SZ/2, 0, 270, 0.5, 0.5, 1, 1, Color::RED) if border.call(3) > 0
					end
				end

				i += 1
			end
		end
	end

	def button_down(key)
		if room = get_room(mouse_x/SZ + @scx, mouse_y/SZ + @scy)
			id = mouse_x.div(SZ) + @scx - room[:map_x][:value] + (mouse_y.div(SZ) + @scy - room[:map_y][:value]) * room[:width][:value]
			
			if key == KbW
				border = get_border(room[:borders][:value], 0, id)
				set_border(room[:borders][:value], 0, id, (border+1)%3)
			elsif key == KbD
				border = get_border(room[:borders][:value], 1, id)
				set_border(room[:borders][:value], 1, id, (border+1)%3)
			elsif key == KbS
				border = get_border(room[:borders][:value], 2, id)
				set_border(room[:borders][:value], 2, id, (border+1)%3)
			elsif key == KbA
				border = get_border(room[:borders][:value], 3, id)
				set_border(room[:borders][:value], 3, id, (border+1)%3)
			end
		end

		if key == KbRight
			@scx += 1
		end
	end

	def button_up(id)
	end

	def needs_cursor?
		true
	end
	
	def close
		save
		close! if !button_down?(KbEscape)
	end
	
	def draw_rect(x, y, w, h, c = Color::WHITE)
		draw_quad(x, y, c, x+w, y, c, x+w, y+h, c, x, y+h, c, 0)
	end
	
	def get_room(x, y)
		MAPS.find{|map| map[:map_x][:value] <= x and map[:map_y][:value] <= y and map[:map_x][:value] + map[:width][:value] > x and map[:map_y][:value] + map[:height][:value] > y}
	end
	
	def save
		MAPS.each do |map|
			lines = File.readlines("Maps/" + map[:file])
			map.each_pair do |key, value|
				case key
					when :borders
					lines[value[:index]] = "borders = [ " + value[:value].join(", ") + " ]\n"
				end
			end
			
			f = File.new("Maps/" + map[:file], "wb")
			f.puts lines.join.encode(universal_newline: true)
			f.close
		end
	end
end

GameWindow.new.show