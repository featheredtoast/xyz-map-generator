# frozen_string_literal: true
require 'fileutils'

ROOT_FOLDER = "#{__dir__}/parts/"
START_LEVEL = 13
# starting zoom is 14. up to 22. So 8 passes.
# Then join with black spaces to generate down to 1. 13 passes.
# split filename - get current zoom level, x and y
# next 4 tiles is: current zoom ++
# new-x = x^2-1, x^2
# new-y = y^2-1, y^2
# original size: 1920x1920 -- crop and split from here. resize *up* to 256.

def get_xyz_from_path(path)
  parts = path.gsub(ROOT_FOLDER, "").split("/")
  z = Integer(parts[0])
  x = Integer(parts[1])
  y = Integer(parts[2].gsub(".png", ""))
  { x: x, y: y, z: z }
end

def make_next_tileset(tile)
  xyz = get_xyz_from_path(tile)
  x = xyz[:x]
  y = xyz[:y]
  z = xyz[:z]

  parts_folder_1 = File.join(ROOT_FOLDER, "#{z  + 1 }", "#{(x * 2) - 1 }")
  parts_folder_2 = File.join(ROOT_FOLDER, "#{z  + 1 }", "#{x * 2 }")
  FileUtils.mkdir_p parts_folder_1
  FileUtils.mkdir_p parts_folder_2

  `magick "#{tile}" -crop "2x2@" "#{File.join(ROOT_FOLDER, "temp_%d.png")}"`
  # 0 upper left
  # 1 upper right
  # 2 lower left
  # 3 lower right
  temp_file_1 = File.join(ROOT_FOLDER, "temp_0.png")
  temp_file_2 = File.join(ROOT_FOLDER, "temp_2.png")
  temp_file_3 = File.join(ROOT_FOLDER, "temp_1.png")
  temp_file_4 = File.join(ROOT_FOLDER, "temp_3.png")

  new_file_1 = File.join(parts_folder_1,  "#{(y * 2) - 1}.png")
  new_file_2 = File.join(parts_folder_1,  "#{(y * 2)}.png")
  new_file_3 = File.join(parts_folder_2,  "#{(y * 2) - 1}.png")
  new_file_4 = File.join(parts_folder_2,  "#{(y * 2)}.png")

  FileUtils.mv(temp_file_1, new_file_1)
  FileUtils.mv(temp_file_2, new_file_2)
  FileUtils.mv(temp_file_3, new_file_3)
  FileUtils.mv(temp_file_4, new_file_4)
end

def make_next_zoom(z)
  tile_folder = File.join(ROOT_FOLDER, "#{z}")
  Dir.foreach(tile_folder) do |x_folder|
    next if x_folder == "." || x_folder == ".."

    Dir.foreach(File.join(tile_folder, x_folder)) do |filename|
      next unless filename =~ /png$/
      file = File.join(tile_folder, x_folder, filename)
      make_next_tileset file
    end
  end
end

def resize_image(source, target)
  `magick "#{source}" -resize "256x256" "#{target}"`
end

# 256x256px final sizes
# resize to 256 in the final passes.
# TODO: Resize all 22 levels to 256px
# Resizes a set of files in a folder
def final_resize_pass(tile_folder)
  Dir.foreach(tile_folder) do |filename|
    next unless filename =~ /png$/
    file = tile_folder + filename
    resize_image(file, file)
  end
end

def resize_before_merge(image)
  target = File.join(ROOT_FOLDER, "temp_0.png")
  resize_image(image, target)
  target
end

# Append a list of four images in a grid
# upper left, upper right, lower left, lower right
def append(ul, ur, ll, lr, target)
  cmd = "magick \\( \"#{ul}\" \"#{ur}\" +append \\) \\( \"#{ll}\" \"#{lr}\" +append \\) -background none -append \"#{target}\""
  `#{cmd}`
end

def make_prev_zoom(z, x, y)
  image = File.join(ROOT_FOLDER, "#{z}", "#{x}", "#{y}.png")
  zoom_x = x.odd? ? (x + 1) / 2 : x / 2
  zoom_y = y.odd? ? (y + 1) / 2 : y / 2

  target_folder = File.join(ROOT_FOLDER, "#{z - 1}", "#{zoom_x}")
  FileUtils.mkdir_p target_folder
  target = File.join(target_folder, "#{zoom_y}.png")

  resized = resize_before_merge(image)
  fill = File.join(__dir__, "satisfactory-map-fill.png")
  if x.odd? && y.odd?
    # up left
    append(resized, fill, fill, fill, target)
  elsif x.even? && y.odd?
    # up right
    append(fill, resized, fill, fill, target)
  elsif x.odd? && y.even?
    # down left
    append(fill, fill, resized, fill, target)
  else
    # down right
    append(fill, fill, fill, resized, target)
  end
  FileUtils.rm resized
  { x: zoom_x, y: zoom_y, z: z - 1 }
end

def init
  original_file = File.join(__dir__, "satisfactory-map.png")
  folder_name = File.join(ROOT_FOLDER, "#{START_LEVEL }", "#{(2**START_LEVEL) / 2 }")
  FileUtils.mkdir_p folder_name
  file = File.join(folder_name, "#{(2**START_LEVEL) / 2}.png")
  FileUtils.cp(original_file, file)
  file
end

def clean
  FileUtils.rm_r ROOT_FOLDER
end

def run
  clean
  init
  (START_LEVEL..18).each do |level|
    make_next_zoom level
  end
end

#final_resize_pass("./parts/14/8192/")

#run
make_prev_zoom(13, 4096, 4096)
