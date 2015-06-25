require 'readline'

namespace :deploy_mate do

  desc 'Installs the needed capistrano files to deploy with the mate.'
  task :install do |t,args|
    puts "I'm your DEPLOY_MATE."
    puts "We will setting up your deployment now."

    @ssh_name = ask("[01/13] SSH-Hostname for the server", "#{@app_name}-#{@stage_name}")
    @ruby_version = ask("[02/13] Ruby-Version (the RVM-way, e.g. ruby-2.2.0)", guess_ruby_version)
    @db_engine = ask_until("[03/13] What db are you using?", %w( postgresql mysql ), "mysql")
    @app_name = ask("[04/13] App-Name (for nginx, servers, etc.)", guess_app_name)
    @repo_url = ask("[05/13] Url-Location of git-repo", "git@github.com:hanseventures/#{@app_name}.git")
    @is_rails = yes_or_no?("[06/13] Is this a RAILS project ?", (rails_present? ? "yes" : "no"))
    @needs_imagemagick = yes_or_no?("[07/13] Does this project need ImageMagick ?", (needs_imagemagick? ? "yes" : "no"))
    @uses_sidekiq = yes_or_no?("[08/13] Does this project use Sidekiq ?", (uses_sidekiq? ? "yes" : "no"))
    @stage_name = ask("[09/13] Give the first stage a name", "prestage")
    @branch_name = ask("[10/13] Branch to deploy '#{@stage_name}' from", "dev")
    @host_name = ask("[11/13] Web-URL for '#{@stage_name}'", "#{@stage_name}.#{@app_name}")
    @environment = ask("[12/13] #{@stage_name}'s environment (RACK_ENV/RAILS_ENV)", "#{@stage_name}")
    @needs_elasticsearch = yes_or_no?("[13/13] Do you need ElasticSearch on this machine ?", "no")

    puts "Aye!"
    puts "Worrrrking..."

    config_template("Capfile.erb", "Capfile")
    sleep 1
    config_template("deploy.rb.erb", "config/deploy.rb")
    sleep 1
    FileUtils.mkdir_p("config/deploy") unless File.exists?("config/deploy")
    config_template("deploy/stage.rb.erb", "config/deploy/#{@stage_name}.rb")
    sleep 1

    puts "You can activate OPTIONAL components e.g. 'whenever' in deploy.rb/Capfile."

    puts "Arr, be dun working!"
  end

end

def config_template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  compiled = ERB.new(erb).result(binding)
  File.open(to, "wb") { |f| f.write(compiled) }
  puts "'#{to}'"
end

def uses_sidekiq?
  defined? Sidekiq
end

def needs_imagemagick?
  defined? RMagick || defined? MiniMagick
end

def rails_present?
  defined? Rails
end

def guess_app_name
  Dir.pwd.split(File::SEPARATOR).last
end

def guess_ruby_version
  ruby_version = nil
  ruby_version = cat_file(".ruby-version")
  ruby_version.strip! if ruby_version
  unless ruby_version
    gem_file_content = cat_file("Gemfile")
    if gem_file_content
      match =  gem_file_content.match("^ruby '(?<version>[0-9.]*)'")
      if match
        ruby_version = "ruby-" + match["version"]
      end
    end
  end
  ruby_version
end

def yes_or_no?(prompt, default = nil)
  answer = "undefined"
  while(!["yes", "no"].include?(answer))
    answer = ask("#{prompt} [yes/no]:", (default == "yes" ? "yes" : "no"))
  end
  (answer == "yes")
end

def ask_until(prompt, answers, default)
  begin
    answer = ask("#{prompt} (#{answers.join(', ')})", default).downcase
  end until answers.include? answer
  answer
end

def ask(prompt, default = nil)
  if default
    Readline.pre_input_hook = -> {
      Readline.insert_text(default)
      Readline.redisplay
    }
  end
  data = Readline.readline("#{prompt}: ")
  return data.chomp
end

def cat_file(filename)
  File.open(filename, 'rb') { |f| f.read } if File.exist?(filename)
end