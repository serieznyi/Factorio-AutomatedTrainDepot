#!/usr/bin/env python
# Original code taken from https://forums.factorio.com/viewtopic.php?f=69&t=93693

from PIL import Image
import os, math, argparse
from pathlib import Path

script_dir = os.path.abspath(os.path.join(__file__, ".."))
runtime_dir = os.path.abspath(os.path.join(__file__, "../../../tmp"))
max_icon_size = 64
mipmap_levels = 4

def crop_canvas(old_image, size):
  old_image = old_image.crop(old_image.getbbox())
  old_width, old_height = old_image.size
  if old_width > size or old_height > size:
    largest = (old_width >= old_height) and old_width or old_height
    old_image = old_image.resize((int(size*old_width/largest),int(size*old_height/largest)), Image.LANCZOS)
    old_width, old_height = old_image.size
  x1 = int(math.floor((size - old_width) / 2))
  y1 = int(math.floor((size - old_height) / 2))
  newImage = Image.new("RGBA", (size, size), (0,0,0,0))
  newImage.paste(old_image, (x1, y1, x1 + old_width, y1 + old_height))
  return newImage


def create_mipmap(outputf, inputf, size, levels):
  original = crop_canvas(Image.open(inputf),size)
  mipmap = Image.new("RGBA", (int(size * ((1-0.5**levels)/0.5)), size), (0,0,0,0))
  offset = 0
  for i in range(0,levels):
    new_size = int(size * (0.5**i))
    copy = original.resize((new_size, new_size), Image.LANCZOS)
    mipmap.paste(copy, box = (offset, 0))
    offset += new_size
  mipmap.save(outputf)


def getOutputDir(options) -> str:
    output_dir = None
    if options.output_dir is None:
        output_dir = runtime_dir
    else:
        output_dir = os.path.abspath(options.output_dir.strip())

    if not os.path.exists(output_dir) or not os.path.isdir(output_dir):
        print("Path `" + output_dir + "` not exists or not directory")
        exit(1)

    return output_dir

def getFilesForProcess(options) -> list:
    files_for_process = []

    if not os.path.exists(options.input):
        print("File or directory `" + output_dir + "` not exists");
        exit(1)

    if os.path.isdir(options.input):
        for dirpath, dirs, files in os.walk(options.input):
            for filename in files:
                files_for_process.append(os.path.abspath(options.input + "/" +  filename))
    else:
        files_for_process.append(os.path.abspath(options.input))

    return list(filter(lambda v: ".png" in v, files_for_process))

def main():
    parser = argparse.ArgumentParser(
        description='''
            Generate minmap files from source images.
            Support only PNG files
        ''',
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        'input',
        help="Path to image or directory with images",
    )

    parser.add_argument(
        '--output-dir',
        help="Absolute path to output dir. \nDefault value: " + runtime_dir,
    )

    options = parser.parse_args()

    output_dir = getOutputDir(options)

    files = getFilesForProcess(options)

    print("Output directory: " + output_dir)

    for file_path in files:
          print("Process file: " + file_path)
          create_mipmap(runtime_dir + "/" + os.path.basename(file_path), file_path, max_icon_size, mipmap_levels)

if __name__ == '__main__':
    main()