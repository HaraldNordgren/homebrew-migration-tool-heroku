require 'fileutils'
require 'json'


def replace_brew_class (file_name, regex_captures)
    package = regex_captures[0]
    version = regex_captures[1]
    #puts "Matched #{package} with version #{version}"

    classname = ""
    for word in package.split("-")
        classname += word.capitalize
    end

    classname_with_version = classname
    for word in version.split("-")
        classname_with_version += word.capitalize
    end

    text = File.read(file_name)

    if not text.match(/#{classname_with_version}/)
        classname_with_version.tr!(".", "")
    end

    if not text.match(/#{classname_with_version}/)
        mismatched_version = text.match(/^class #{classname}([0-9\.]+)/)
        if mismatched_version
            classname_with_version = classname + mismatched_version[1]
        end
    end

    text.sub!(
        /(^class )#{classname_with_version}([ ]*<[ ]*Formula$)/,
        '\1' + classname + '\2'
    )

    text.gsub!(
        /^  conflicts_with "#{package}",( |\n).*\n\n/,
        ''
    )

    if not text.match("^  version ")
        text.sub!(
            /(^class #{classname}[ ]*<[ ]*Formula$)/,
            '\1' + "\n" + '  version "' + version + '"'
        )
    end

    File.write(file_name, text)

    package_at_version = package + "@" + version
    $handled_packages.push({
        'classname_with_version' => classname_with_version,
        'package_at_version' => package_at_version,
        'file_without_extension' => File.basename(file_name, File.extname(file_name)),
        'original_filename' => file_name,
        'migrated_filename' => package + ".rb",
    })
end

aliases_dir = "Aliases"
formula_dir = "Formula"

for dirname in [aliases_dir, formula_dir]
    unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
    end
end

puts
puts "RENAMING CLASSES ..."

$handled_packages = []

for filename in Dir["*.rb"]
    version = filename.match(/(^.*?)([0-9]-lts).rb$/)
    if version
        replace_brew_class(filename, version.captures)
        next
    end
    
    version = filename.match(/(^.*?)-(lts|legacy|r[0-9]+[a-z]?).rb$/)
    if version
        replace_brew_class(filename, version.captures)
        next
    end

    version = filename.match(/(^.*?)[-]?([0-9\.]+[a-z]?).rb$/)
    if version
        replace_brew_class(filename, version.captures)
        #next
    end
end

puts "DONE"
puts
puts "REPLACING REFERENCES WITH VERSIONED NAME"

for file_name in Dir["*.rb"]

    tmp_file_name = file_name + ".tmp"
    open(tmp_file_name, 'w') do |tmp_file|

        File.open(file_name).each_line do |line|

            if line =~ /^[ ]+(url|homepage|mirror|\#include) /
                tmp_file.puts line
                next
            end

            for handled_package in $handled_packages
                file_without_extension = handled_package['file_without_extension']
                line.gsub!(
                    /#{file_without_extension}/,
                    handled_package['package_at_version']
                )
            end

            tmp_file.puts line
        end
    end

    FileUtils.mv(tmp_file_name, file_name)
    system("git add #{file_name}")
    print "."
end

puts
puts "DONE"

puts
puts "UPDATING HANDLED_PACKAGES FILE"

handled_packages_file = "migrated_packages.json"

if File.file?(handled_packages_file)
    handled_packages_history = JSON.load(File.read(handled_packages_file))
    #handled_packages_history = JSON.parse(File.read(handled_packages_file))

    for handled_package in $handled_packages
        found_in_history = false

        for saved_package in handled_packages_history
            if saved_package['file_without_extension'] == handled_package['file_without_extension']
                found_in_history = true
                break
            end
        end

        if not found_in_history
            puts "New package #{handled_package['file_without_extension']}"
            handled_packages_history.push(handled_package)
        end
    end
else
    handled_packages_history = $handled_packages
end

File.open(handled_packages_file, 'w') do |f|
    f.write(JSON.pretty_generate(handled_packages_history))
end
system("git add #{handled_packages_file}")

puts "DONE"
puts
puts "MOVING FILES ..."

for handled_package in handled_packages_history
    original_filename = handled_package['original_filename']
    package_at_version = handled_package['package_at_version']

    formula_subdir = File.join(formula_dir, package_at_version)
    FileUtils.mkdir_p(formula_subdir)

    migrated_path = File.join(formula_subdir, handled_package['migrated_filename'])
    system("git add #{original_filename}")
    system("git mv #{original_filename} #{migrated_path}")

    symlink_dest = File.join("..", migrated_path)
    symlink_location = File.join(aliases_dir, package_at_version)
    FileUtils.ln_s(symlink_dest, symlink_location)
    system("git add #{symlink_location}")
end

puts "DONE"
puts

