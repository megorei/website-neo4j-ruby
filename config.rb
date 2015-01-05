activate :dotenv
activate :directory_indexes
activate :syntax
activate :sitemap, :hostname => 'http://www.neo4j-ruby.org'

activate :livereload

set :haml, :format => :html5, :ugly => true
set :markdown_engine, :kramdown

set :images_dir, 'images'
set :css_dir,    'stylesheets'
set :js_dir,     'javascripts'

helpers do
  def show_disqus?
    current_page.path =~ /^how-tos/ && current_page.path != 'how-tos.html'
  end
end

case ENV['TARGET'].to_s.downcase
when 'production'
  activate :deploy do |deploy|
    deploy.method   = :rsync
    deploy.host     = ENV['PRODUCTION_HOST']
    deploy.user     = ENV['PRODUCTION_USER']
    deploy.path     = ENV['PRODUCTION_PATH']
    deploy.clean  = true
  end
else
  activate :deploy do |deploy|
    deploy.method = :rsync
    deploy.host   = ENV['STAGING_HOST']
    deploy.user   = ENV['STAGING_USER']
    deploy.path   = ENV['STAGING_PATH']
    deploy.clean  = true
  end
end

configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
end
