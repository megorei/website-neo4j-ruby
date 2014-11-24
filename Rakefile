task :default => :build

desc 'build website'
task :build do
  puts '---> Build website'
  system 'bundle exec middleman build'
  puts '---> Fix permissions'
  system 'chmod -R +r build/*'
end

namespace :deploy do
  def deploy(env)
    puts "---> Deploying to #{env}"
    system "TARGET=#{env} bundle exec middleman deploy"
  end

  def add_http_auth
    raise 'Missing file: http_auth_staging' if !File.exist?('http_auth_staging')
    puts '---> Add Basic Auth'
    system 'cat http_auth_staging >> build/.htaccess'
  end

  def add_http_rewrite(env)
    puts "---> Add Rewrite for #{env}"
    system "cat http_rewrite_#{env} >> build/.htaccess"
  end

  desc 'Deploy to staging'
  task :staging do
    Rake::Task['build'].invoke
    add_http_rewrite(:staging)
    add_http_auth
    deploy :staging
  end

  desc 'Deploy to production'
  task :production do
    Rake::Task['build'].invoke
    add_http_rewrite(:production)
    deploy :production
  end
end

desc 'Deploy to staging'
task :deploy do
  Rake::Task['deploy:staging'].invoke
end
