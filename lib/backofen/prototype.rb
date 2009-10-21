require 'git'
require 'tmpdir'

module Backofen
  module Prototype
    class << self
      def run(path)
        # Get Repository url
        repo = Git.open(path)
        url = repo.remotes.first.url

        # Clone Repository to Tmp Directory
        puts "Cloning from #{url}.."
        d = Dir.mktmpdir
        tmp_repo = Git.clone(url, 'tmp_clone', :path => d)
        tmp_repo_path = tmp_repo.dir.path
        puts "Cloned to: #{tmp_repo_path}"

        # Create local patches (working, index)
        patch_working_file_path = File.join(tmp_repo_path, 'patch_working')
        patch_index_file_path = File.join(tmp_repo_path, 'patch_index')

        puts "Creating patches.."
        %x(cd #{path} && git diff -p > patch_working)
        %x(cd #{path} && git diff --cached -p > patch_index)

        # Apply patches to tmp clone
        %x(mv #{path}/patch_working #{patch_working_file_path})
        %x(mv #{path}/patch_index #{patch_index_file_path})
       
        puts "Applying patches.."
        %x(cd #{tmp_repo_path} && git apply patch_working)
        %x(cd #{tmp_repo_path} && git apply patch_index)
        
        # Prepare Rails
        if File.exist?(File.join(path, 'config', 'database.yml'))
          puts "Found a Rails application.."
          # Simply the most beautiful way to determine a Rails app
          %x(cp #{path}/config/database.yml #{tmp_repo_path}/config/)
        end

        # Run rspec && cucumber
        system("cd #{tmp_repo_path} && rake db:migrate && rake spec && rake cucumber")
        
        # Return result
        puts $?.exitstatus == 0 ? 'Integration succeeded' : 'Integration failed'
        exit($?.exitstatus)
      end
    end
  end
end
