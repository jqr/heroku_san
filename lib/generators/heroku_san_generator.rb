class HerokuSanGenerator < Rails::Generators::Base
  source_root File.expand_path("../../templates", __FILE__)

  def copy_initializer_file
    copy_file "heroku.example.yml", "config/heroku.yml"
  end
end