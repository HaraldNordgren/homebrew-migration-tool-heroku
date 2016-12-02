require 'fileutils'


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

    #puts "Replacing #{classname_with_version}"
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
            /(^class .*<[ ]*Formula$)/,
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
        puts "Creating #{dirname} folder"
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
        next
    end

    migrated_path = File.join(formula_dir, filename)
    FileUtils.mv(filename, migrated_path)
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

    FileUtils.mv(tmp_file_name,file_name)
    print "."
end

puts
puts "DONE"
puts
puts "MOVING FILES ..."

for handled_package in $handled_packages
    original_filename = handled_package['original_filename']
    package_at_version = handled_package['package_at_version']

    formula_subdir = File.join(formula_dir, package_at_version)
    FileUtils.mkdir_p(formula_subdir)

    migrated_path = File.join(formula_subdir, handled_package['migrated_filename'])
    FileUtils.mv(original_filename, migrated_path)

    symlink_dest = File.join("..", migrated_path)
    symlink_location = File.join(aliases_dir, package_at_version)
    FileUtils.ln_s(symlink_dest, symlink_location)
end

puts "DONE"
puts

