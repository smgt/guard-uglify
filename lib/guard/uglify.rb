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

    # @return [Array<String>] Paths of all sass/scss files
    def files
      Watcher.match_files self, Dir['**/*.js']
    end

    def start
      if @options[:all_on_start]
        run_all
      end
      ::Guard::UI.info "Guard::Uglify is ready to uglify your sexy code..."
    end

    def run_all
      run_on_changes files
    end

    def run_on_changes(paths)
      paths.each do |file|
        if !file.match(/\.min\.js$/)
          uglify(file)
        end
      end
    end

    private

    def uglify(file)
      begin
        uglified = Uglifier.new(@options[:uglifier]).compile(File.read(file))
        uglified_path = write_file(uglified, options[:output], file.sub(/.js$/, '.min.js'))
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
