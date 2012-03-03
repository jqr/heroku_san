# Adding this to your :after_deploy task this will add an environment variable,
# in this case, "REVISION", to your Heroku environment with the current revision.
task :after_deploy do
  each_heroku_app do |stage|
    revision = stage.revision.split.first
    stage.push_config('REVISION' => revision) if revision
  end
end
