#jscottpilgrim

require 'propane'

class JuliaBrot < Propane::App
#class JuliaBrot < Processing::App

	def settings
		size 1000, 1000, P2D

		@center = [0.0, 0.0]
		@range_default = 4.0

		@x_range = @range_default
		@y_range = @x_range * height / width
		@zoom = @x_range / width

		@julia_param = [0.1994, -0.613]

		#length of julia loop in frames
		@loop_length = 120
	end

	def setup
		sketch_title 'JuliaBrot'
		#frame_rate 20

		#initialize some parameters
		@mode = 'mandelbrot'
		@line_drawing = false
		@line_start = [0, 0]
		@julia_loop_begin = [0, 0]
		@julia_loop_end = [0, 0]
		@loop_time = 0
		@paused = false
		@edp_enable = false

		#load shaders
		@mandelbrot_shader = load_shader data_path('MandelbrotDE.glsl')
		@mandelbrot_shader.set 'resolution', width.to_f, height.to_f
		@mandelbrot_shader2 = load_shader data_path('MandelbrotDE-double.glsl')
		@mandelbrot_shader2.set 'resolution', width.to_f, height.to_f

		@julia_shader = load_shader data_path('JuliaDE.glsl')
		@julia_shader.set 'resolution', width.to_f, height.to_f
		@julia_shader2 = load_shader data_path('JuliaDE-double.glsl')
		@julia_shader2.set 'resolution', width.to_f, height.to_f
	end

	def mandelbrot_draw
		if @edp_enable
			s = @mandelbrot_shader2
		else
			s = @mandelbrot_shader
		end

		s.set 'center', @center[0], @center[1]
		s.set 'zoom', @zoom
		shader s

		rect 0, 0, width, height

		reset_shader
	end

	def julia_draw
		if @edp_enable
			s = @julia_shader2
		else
			s = @julia_shader
		end

		s.set 'center', @center[0], @center[1]
		s.set 'zoom', @zoom
		s.set 'juliaParam', @julia_param[0], @julia_param[1]
		shader s

		rect 0, 0, width, height

		reset_shader
	end

	def julia_loop_draw
		#calculate julia param with interpolation from julia_loop_begin to julia_loop_end using loop_time
		real_dif = @julia_loop_end[0] - @julia_loop_begin[0]
		imag_dif = @julia_loop_end[1] - @julia_loop_begin[1]
		m = Math.sin( ((2 * Math::PI) / (@loop_length * 2)) * @loop_time)
		real_offset = m * real_dif
		imag_offset = m * imag_dif
		r = @julia_loop_begin[0] + real_offset
		i = @julia_loop_begin[1] + imag_offset
		@julia_param = [r, i]

		#increment time for next frame
		@loop_time += 1
		#reset loop time when cycle is complete
		if @loop_time == @loop_length
			@loop_time = 0
		end

		julia_draw

	end

	def draw
		case @mode
		when 'mandelbrot'
			mandelbrot_draw
		when 'julia'
			julia_draw
		when 'julia_loop'
			julia_loop_draw
		end

		#show where line for julia loop would be drawn when clicked
		if @line_drawing
			stroke 100, 0, 0
			stroke_weight 3
			line @line_start[0], @line_start[1], mouse_x, mouse_y
			no_stroke
		#unable to zoom or pan when line drawing
		elsif key_pressed?
			#pan with arrow keys
			#zoom in with z, zoom out with x
			if key == CODED
				if key_code == UP and @center[1] < 3.0
					@center[1] += @y_range / 60
				elsif key_code == DOWN and @center[1] > -3.0
					@center[1] -= @y_range / 60
				elsif key_code == LEFT and @center[0] > -3.0
					@center[0] -= @x_range / 60
				elsif key_code == RIGHT and @center[0] < 3.0
					@center[0] += @x_range / 60
				end
			else
				if (key == 'z' or key == 'Z') #and (@x_range > 0.00005) #threshold where single precision is not accurate enough and pixelates
					@x_range -= @x_range / 60
					@y_range -= @y_range / 60
					@zoom = @x_range / width
				elsif (key == 'x' or key =='X') and (@x_range < 10)
					@x_range += @x_range / 60
					@y_range += @y_range / 60
					@zoom = @x_range / width
				end
			end
		end
	end

	def reset
		#reset to standard view mandelbrot
		@center = [0.0, 0.0]
		@x_range = @range_default
		@y_range = @x_range * height / width
		@zoom = @x_range / width
		@mode = 'mandelbrot'
		@line_drawing = false
		@line_start = [0, 0]
		@julia_loop_begin = [0, 0]
		@julia_loop_end = [0, 0]
		@loop_time = 0
		@paused = false
	end

	def key_released
		if key == 'r' or key == 'R'
			#reset to standard mandelbrot with r key
			reset
		elsif key == 'p' or key == 'P'
			#pause julia loop on frame
			if @mode == 'julia_loop'
				@mode = 'julia'
				@paused = true
			elsif @paused
				@mode = 'julia_loop'
				@paused = false
			end
		elsif key == 'y' or key == 'Y'
			#print state
			puts "Mode: #{@mode}"
			puts "Center: #{@center}"
			puts "Zoom: #{@zoom}"
			puts "X-Range: #{@x_range}"
			puts "Y-Range: #{@y_range}"
			if @mode != 'mandelbrot'
				puts "Julia Seed: #{@julia_param}"
				if @mode == 'julia_loop'
					puts "Julia Seed Start: #{@julia_loop_begin}"
					puts "Julia Seed End: #{@julia_loop_end}"
					puts "Loop Time: #{@loop_time}"
				end
			end
		elsif key == 'd' or key == 'D'
			#turn on or off emulated double precision
			#@edp_enable = !@edp_enable
			if @edp_enable
				puts "Shader Precision: Float"
				@edp_enable = false
				frame_rate 60
			else
				puts "Shader Precision: Double"
				@edp_enable = true
				frame_rate 20
			end
		end
	end

	def mouse_clicked
		if @line_drawing == true
			#select ending point for julia loop
			x_min = @center[0] - @x_range/2
			x_max = @center[0] + @x_range/2
			y_min = @center[1] - @y_range/2
			y_max = @center[1] + @y_range/2
			@julia_loop_end = [map1d(mouse_x, (0...width), (x_min..x_max)), map1d(mouse_y, (0..height), (y_max..y_min))]
			@line_drawing = false
			@center = [0.0, 0.0]
			@x_range = @range_default
			@y_range = @x_range * height / width
			@zoom = @x_range / width
			@mode = 'julia_loop'
			@loop_time = 0
		else
			if @mode == 'mandelbrot'
				#from mandelbrot use mouse to choose seed(s) for julia set(s)
				if mouse_button == RIGHT
					#start line for julia loop
					@line_drawing = true
					@line_start = [mouse_x, mouse_y]
					x_min = @center[0] - @x_range/2
					x_max = @center[0] + @x_range/2
					y_min = @center[1] - @y_range/2
					y_max = @center[1] + @y_range/2
					@julia_loop_begin = [map1d(mouse_x, (0...width), (x_min..x_max)), map1d(mouse_y, (0..height), (y_max..y_min))]
				else
					#left click for static julia set
					x_min = @center[0] - @x_range/2
					x_max = @center[0] + @x_range/2
					y_min = @center[1] - @y_range/2
					y_max = @center[1] + @y_range/2
					@julia_param = [map1d(mouse_x, (0...width), (x_min..x_max)), map1d(mouse_y, (0..height), (y_max..y_min))]
					@center = [0.0, 0.0]
					@x_range = @range_default
					@y_range = @x_range * height / width
					@zoom = @x_range / width
					@mode = 'julia'
				end
			end
		end
	end

end

JuliaBrot.new