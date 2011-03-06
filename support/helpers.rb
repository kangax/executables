def options_for(filename, options)
  require 'optparse'
  # 1. Create instance variables using keys in options hash.
  # 2. Attempt to load their values from config file.
  # 3. Attempt to load their values from command line args.
  # 4. Verify presence of required options.
  #
  # Example:
  # options_for 'filename', :opt1 => { :short => 'o', :type => String, :text => 'Help text', :required => true}
  basename = File.basename(filename)
  set_vars_from_config basename, options
  set_vars_from_args basename, options

  required_varnames = options.keys.select{ |key| options[key][:required] }
  ensure_required_vars required_varnames
end

def set_vars_from_config(basename, options)
  load_config_for(basename) do |config|
    options.keys.each do |key|
      instance_variable_set("@#{key}", config[key.to_s])
    end
  end
end

def set_vars_from_args(filename, options)
  OptionParser.new do |opts|
    opts.banner = "Usage: #{filename} [options]\n"

    options.each_pair do |key, details|
      opts.on("-#{details[:short] || key.to_s.chars.first}", "--#{key} #{key.to_s.upcase}", details[:type] || String, details[:text] || key.to_s) do |v|
        instance_variable_set("@#{key}", v)
      end
    end

  end.parse!
end

def ensure_required_vars(required_varnames)
  if missing_required_vars?(required_varnames)
    list = required_varnames.map{|varname| "--#{varname}"}.join(', ')
    puts "Error: Missing required #{list} option(s)."
    exit(1)
  end
end

def missing_required_vars?(required_varnames)
  required_varnames.any? do |varname|
    var = instance_variable_get("@#{varname}")
    var.nil? || var.to_s.strip == ''
  end
end

def load_config_for(section)
  config_path = "#{File.expand_path(File.dirname(__FILE__))}/config.yml"

  if File.exist?(config_path)
    require 'yaml'
    config = YAML.load(File.read(config_path))[section]

    if config
      yield(config)
    end
  end
end