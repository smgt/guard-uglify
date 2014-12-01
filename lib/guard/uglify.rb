require 'guard'
require 'guard/plugin'
require 'guard/watcher'

require 'uglifier'

module Guard
  class Uglify < Plugin

    DEFAULTS = {
      :output       => 'js',
      :extension    => '.js',
      :all_on_start => false
    }

    def initialize(options={})
      @options = options
      if options[:input]
        options[:output] = options[:input] unless options.has_key?(:output)
        options[:watchers] << ::Guard::Watcher.new(%r{^#{ options[:input] }/(.+\.js)$})
      end
      options = DEFAULTS.merge(options)
      super
    end

    def start
      if @options[:all_on_start]
        run_all
      end
      ::Guard::UI.info "Guard::Uglify is ready to uglify your sexy code..."
    end

    def run_all
      run_on_change(
        Watcher.match_files(
          self,
          Dir.glob(File.join(::Guard.listener.directory, '**', '*.js')).
          map {|f| f[::Guard.listener.directory.size+1..-1] }
        )
      )
    end

    def run_on_change(paths)
      paths.each do |file|
        if !file.match /\.min\.js$/
          uglify(file)
        end
      end
    end

    private

    def uglify(file)
      begin
        uglified = Uglifier.new.compile(File.read(file))
        #File.open(@output,'w'){ |f| f.write(uglified) }
        uglified_path = write_file(uglified, options[:output], file)
        msg = "Uglified #{File.basename(file)} -> #{File.basename(uglified_path)}"
        ::Guard::UI.info msg
        ::Guard::Notifier.notify msg, :title => 'Guard::Uglify'
        true
      rescue Exception => e
        msg = "Uglifying #{File.basename(file)} failed: #{e}"
        ::Guard::UI.error        msg
        ::Guard::Notifier.notify msg, :title => 'Guard::Uglify', :image => :failed
        false
      end
    end

    def write_file(content, dir, file)
      path = File.join(dir, File.basename(file, '.*')) << options[:extension]
      File.open(path, 'w') {|f| f.write(content) }
      path
    end

  end
end
