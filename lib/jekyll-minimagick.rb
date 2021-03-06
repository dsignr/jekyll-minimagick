require 'mini_magick'

module Jekyll
  module JekyllMinimagick

    class GeneratedImageFile < Jekyll::StaticFile
      # Initialize a new GeneratedImage.
      #   +site+ is the Site
      #   +base+ is the String path to the <source>
      #   +dir+ is the String path between <source> and the file
      #   +name+ is the String filename of the file
      #   +preset+ is the Preset hash from the config.
      #
      # Returns <GeneratedImageFile>
      def initialize(site, base, dir, name, preset, f)
        @site = site
        @base = base
        @dir  = dir
        @name = name
        # Delete these as they are directly passed to image magick
        @dst_dir = preset.delete('destination')
        @dst_sub_dir = preset.delete('destination_subfolder')
        @src_dir = preset.delete('source')
        @src_sub_dir = preset.delete('source_subfolder')
        @commands = preset
        @f = f
      end

      # Obtains source file path by substituting the preset's source directory
      # for the destination directory.
      #
      # Returns source file path.
      def path
        @f
      end

      # Use MiniMagick to create a derivative image at the destination
      # specified (if the original is modified).
      #   +dest+ is the String path to the destination dir
      #
      # Returns false if the file was not modified since last time (no-op).
      def write(dest)
        dest_path = destination(dest)

        return false if File.exist? dest_path and !modified?

        self.class.mtimes[path] = mtime

        FileUtils.mkdir_p(File.dirname(dest_path))
        image = ::MiniMagick::Image.open(path)
        @commands.each_pair do |command, arg|
          image.send command, arg
        end
        image.write dest_path

        true
      end

    end

    class MiniMagickGenerator < Generator
      safe true

      # Utility function to generate the destination folder
      def destination(f, preset)
        folder_name = File.dirname(f)
        # Remove everything before the project folder name
        # Eg. Remove '/Users/nrk/Desktop/Projects/ecofactory.shop'
        folder_name = folder_name.gsub! (Dir.pwd + "/"), ""
        # Append the destination subfolder - inside the source folder
        # KISS - Keep it simple, stupid
        folder_name + "/" + preset["destination_subfolder"]
      end

      # Find all image files in the source directories of the presets specified
      # in the site config.  Add a GeneratedImageFile to the static_files stack
      # for later processing.
      def generate(site)
        return unless site.config['mini_magick']
        site.config['mini_magick'].each_pair do |name, preset|
          # Find all the files first
          files = []
          Find.find(File.join(site.source, preset['source'])) do |path|
            files << path if path =~ /.*\.png|jpg|jpeg|gif$/ && path =~ /#{preset['source_subfolder']}/
          end
          # Generate
          Dir.glob(files) do |f|
            site.static_files << GeneratedImageFile.new(site, site.source, destination(f, preset), File.basename(f), preset.clone, f)
          end
        end
      end
    end

  end
end
