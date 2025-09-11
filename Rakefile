require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'fileutils'

# Run with `rake spec`
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--format', 'documentation']
end

# Generate Gemfile.lock for Ruby 2.2 and below (Bundler 1.x)
task :generate_gemfile_lock_ruby22 do
  puts 'Generating Gemfile.lock for Ruby 2.2 and below (Bundler 1.x)...'

  # Copy current Gemfile.lock and modify bundler version
  if File.exist?('Gemfile.lock')
    content = File.read('Gemfile.lock')
    content.gsub!(/bundler \(~> 2\.7\)/, 'bundler (~> 1.17)')
    content.gsub!(/BUNDLED WITH\s*\n\s*2\.7\.2/, "BUNDLED WITH\n   1.17.3")
    File.write('Gemfile.lock.ruby22', content)
    puts 'Generated Gemfile.lock.ruby22'
  else
    puts 'Error: No existing Gemfile.lock found'
  end
end

# Generate both Gemfile.lock files
task generate_gemfile_locks: %i[generate_gemfile_lock_ruby22] do
  puts 'Generated both Gemfile.lock files for different Ruby/Bundler versions'
end

task default: :spec
