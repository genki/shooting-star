require 'rubygems'
require 'asteroid'
require 'drb/drb'
require 'yaml'
require 'ftools'
require 'shooting_star/config'
require 'shooting_star/shooter'

module ShootingStar
  VERSION = '2.0.1'
  CONFIG = Config.new(
    :config => 'config/shooting_star.yml',
    :pid_file => 'log/shooting_star.pid',
    :log_file => 'log/shooting_star.log',
    :daemon => false,
    :slient => false,
    :session_timeout => 10,
    :sweep_timeout => 500_000)

  def self.configure(options = {})
    if @log_file
      @log_file.close
      @log_file = nil
    end
    config_file = options[:config] || CONFIG.config
    CONFIG.merge!(YAML.load_file(config_file)) if File.exist?(config_file)
    CONFIG.merge!(options)
  end

  def self.shooter
    @@shooter ||= DRbObject.new_with_uri(CONFIG.shooter.uri)
  end

  # install config file and plugin
  def self.init
    base_dir = CONFIG.directory || `pwd`.chop
    config_dir = File.join(base_dir, 'config')
    `mkdir -p #{config_dir}` unless File.exist? config_dir
    config_file = File.join(config_dir, 'shooting_star.yml')
    unless File.exist? config_file
      open(config_file, 'w') do |file|
        open(__FILE__) do |data|
          data.gets("__END__\n")
          file.write data.read
        end
      end
    end
    log_dir = File.join(base_dir, 'log')
    `mkdir -p #{log_dir}` unless File.exist? log_dir
    plugin_dir = File.join(base_dir, 'vendor/plugins')
    `mkdir -p #{plugin_dir}` unless File.exist? plugin_dir
    meteor_strike_dir = File.join(plugin_dir, 'meteor_strike')
    src_dir = File.join(File.dirname(__FILE__),
      '../vendor/plugins/meteor_strike')
    `mkdir -p #{meteor_strike_dir}`
    `cp -Rf #{src_dir}/* #{meteor_strike_dir}`
  end

  def self.start(&block)
    if File.exist?(CONFIG.pid_file)
      log 'shooting_star is already running.'
      return
    end
    if CONFIG.daemon
      Signal.trap(:ALRM){exit} and sleep if fork
      Process.setsid
    end
    require 'shooting_star/shooter'
    @@druby = DRb.start_service(CONFIG.shooter.uri, Shooter.new)
    require 'shooting_star/server'
    Asteroid::run(CONFIG.server.host, CONFIG.server.port, Server) do
      File.open(CONFIG.pid_file, "w") do |file|
        file.puts Process.pid
        file.puts $command_line
      end
      Signal.trap(:INT) do
        Asteroid::stop
        @@druby.stop_service
        log "shooting_star service stopped."
        File.rm_f(CONFIG.pid_file)
      end
      Signal.trap(:EXIT) do
        File.rm_f(CONFIG.pid_file)
        @log_file.close if @log_file
      end
      log "shooting_star service started."
      Process.kill(:ALRM, Process.ppid) if CONFIG.daemon
      block.call if block
    end
  end

  def self.stop
    command = ''
    File.open(CONFIG.pid_file) do |file|
      Process.kill(:INT, pid = file.gets.to_i)
      command = file.gets
    end
    Thread.pass while File.exist?(CONFIG.pid_file)
  rescue Errno::ENOENT
    log "shooting_star service is not running."
  rescue Errno::ESRCH
    File.unlink(CONFIG.pid_file)
  ensure
    return command
  end

  def self.restart
    command = stop
    Thread.pass while File.exist?(CONFIG.pid_file)
    system(command)
  end

  def self.report
    puts "#{'-' * 79}\nconnections channel name\n#{'-' * 79}"
    total_connections = 0
    shooter.channels.each do |channel|
      count = shooter.count(channel)
      puts "%11d %s" % [count, channel]
      puts shooter.listeners(channel).join(',') if CONFIG.with_uid
      puts shooter.signatures(channel).join(',') if CONFIG.with_sig
      total_connections +=  count
    end
    puts "#{'-' * 79}\n%11d %s\n#{'-' * 79}" % [total_connections, 'TOTAL']
  end

  def self.timestamp
    now = Time.now
    "%d%06d" % [now.tv_sec, now.tv_usec]
  end

private
  def self.log(*arg, &block)
    puts(*arg, &block) unless CONFIG.silent
    @log_file ||= open(CONFIG.log_file, 'a')
    @log_file.puts(*arg, &block) if @log_file
  end
end
__END__
server:
  host: 0.0.0.0
  port: 8080
shooter:
  uri: druby://0.0.0.0:7123
