require 'open-uri'
require 'fileutils'
require 'time'

puts "[rdbo-archiver]"
puts "Simple tool to archive my doings over the years"

if not File.exist?("README.md")
  download = URI.open('https://raw.githubusercontent.com/rdbo/rdbo/refs/heads/master/README.md')
  IO.copy_stream(download, 'README.md')
end

archives_dir = "rdbo-archives"
if not Dir.exist?(archives_dir)
  Dir.mkdir(archives_dir)
end

readme = File.read("README.md")
projects = readme.scan(/\((https:\/\/github.com\/.+\/.+)\)/).map{|p| p[0].split('/')[-2..].join("/").gsub(/\.git$/, "")}

puts "Projects to archive:"
projects.each do |project|
  puts "  - #{project}"
end
puts

projects.each do |project|
  username, password = project.split("/", 2)
  if Dir.exist?("#{archives_dir}/#{project}")
    puts "Skipped downloading '#{project}', already downloaded"
    next
  end

  FileUtils.mkdir_p("#{archives_dir}/#{username}")

  puts "Downloading '#{project}'..."
  `git clone --recurse-submodules --shallow-submodules "https://github.com/#{project}" "#{archives_dir}/#{project}"`
end

timestamp = Time.now.strftime "%Y-%m-%d"
outfile = "rdbo-archives-#{timestamp}.tar.xz"
puts "Generating archive..."
`tar -cJf "#{outfile}" #{archives_dir}`
puts "Archive '#{outfile}' generated successfully!"
