namespace :machine do
  include Aptitude

  desc "Sets up a blank Ubuntu to run our Rails-setup"
  task :init do
    on roles(:app) do
      apt_get_update
      invoke "machine:install:htop"
      invoke "machine:install:language_pack_de"
      invoke "machine:install:unattended_upgrades"
      invoke "machine:install:ntp"
      invoke "machine:install:git"
      invoke "machine:install:nginx"
      invoke "machine:install:fail2ban"
      invoke "machine:install:rvm"
      invoke "machine:install:ruby"
      invoke "machine:install:set_defaults"
      invoke "machine:install:bluepill"
      invoke "machine:install:mysql_dev"
    end 
  end

  desc "Install configs"
  task :setup do
    invoke "nginx:setup"
    invoke "unicorn:setup"
    invoke "upstart:setup"
    invoke "logrotate:setup"
    invoke "bluepill:setup"
  end
  before :setup, "deploy:ensure_folder"

  namespace :install do
    task :set_defaults do
      on roles(:app) do
        execute_script("set_defaults.sh", fetch(:rvm_ruby_version))
        warn "--------------------------------------------------------------------------------------"
        warn "Run 'dpkg-reconfigure -plow unattended-upgrades' to enable automatic security updates!"
        warn "--------------------------------------------------------------------------------------"
      end
    end

    task :language_pack_de do
      on roles(:app) do
        apt_get_install("language-pack-de") unless is_package_installed?("language-pack-de")
      end
    end

    task :ruby do
      on roles(:app) do
        execute :rvm, :install, fetch(:rvm_ruby_version)
      end
    end
    before :ruby, 'rvm:hook'

    task :bluepill do
      on roles(:app) do
        execute :rvmsudo, :gem, :install, :bluepill
        sudo 'mkdir -p /var/run/bluepill'
      end
    end
    before :bluepill, 'rvm:hook'

    task :rvm do
      on roles(:app) do
        execute_script("install_rvm.sh")
      end
    end

    task :mysql_dev do
      on roles(:app) do
        apt_get_install("libmysqlclient-dev") unless is_package_installed?("libmysqlclient-dev")
      end
    end

    task :htop do
      on roles(:app) do
        apt_get_install("htop") unless is_package_installed?("htop")
      end
    end

    task :ntp do
      on roles(:app) do
        apt_get_install("ntp") unless is_package_installed?("ntp")
      end
    end

    task :git do
      on roles(:app) do
        apt_get_install("git") unless is_package_installed?("git")
      end
    end

    task :nginx do
      on roles(:app) do
        apt_get_install("nginx") unless is_package_installed?("nginx")
      end
    end

    task :fail2ban do
      on roles(:app) do
        apt_get_install("fail2ban") unless is_package_installed?("fail2ban")
      end
    end

    task :imagemagick do
      on roles(:app) do
        unless is_package_installed?("imagemagick")
          apt_get_install("imagemagick")
          apt_get_install("libmagickcore-dev")
        end
      end
    end

    task :unattended_upgrades do
      on roles(:app) do
        unless is_package_installed?("unattended-upgrades")
          apt_get_install("unattended-upgrades")
        end
      end
    end

    task :update_rvm_key do
      on roles(:app) do
        execute :gpg, "--keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3"
      end
    end
    before "machine:install:rvm", "machine:install:update_rvm_key"
  end

end