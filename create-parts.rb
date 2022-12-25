require 'fileutils'

ROOT_FOLDER = "#{__dir__}/parts/"
START_LEVEL= 14
# starting zoom is 14. up to 22. So 8 passes.
# Then join with black spaces to generate down to 1. 13 passes.
def make_next_tileset(tile)
  parts = tile.gsub(ROOT_FOLDER, "").split("/")
  puts parts
  z = Integer(parts[0])
  x = Integer(parts[1])
  y = Integer(parts[2].gsub(".png", ""))

  parts_folder_1 = "#{ROOT_FOLDER}#{z+1}/#{(x**2)-1}"
  parts_folder_2 = "#{ROOT_FOLDER}#{z+1}/#{x**2}"
  FileUtils.mkdir_p parts_folder_1
  FileUtils.mkdir_p parts_folder_2

  # split filename - get current zoom level, x and y
  # next 4 tiles is: current zoom ++
  # new-x = x^2-1, x^2
  # new-y = y^2-1, y^2
  # original size: 1920x1920 -- crop and split from here. resize *up* to 256.
end

# 256x256px final sizes
# resize down to 256 in the final passes.
# TODO: Resize all 22 levels down to 256px
# Resizes a set of files in a folder
def final_resize_pass(tile_folder)
  Dir.foreach(tile_folder) do |filename|
    next unless filename =~ /png$/
    file = tile_folder + filename
    `magick "#{file}" -resize "256x256\>" "#{file}"`
  end
end

def init
  original_file = "#{__dir__}/satisfactory-map.png"
  folder_name = "#{ROOT_FOLDER}#{(2**14)/2}/"
  FileUtils.mkdir_p folder_name
  file = "#{folder_name}#{(2**14)/2}.png"
  FileUtils.cp(original_file, file)
end

def clean
  FileUtils.rm_r ROOT_FOLDER
end

#final_resize_pass("./parts/14/8192/")

#make_next_tileset(ROOT_FOLDER + "14/8192/8192.png")
init
