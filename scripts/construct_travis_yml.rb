require 'yaml'


def package_specific_before_build_commands(file_without_extension)
    cmd_list = []

    if file_without_extension =~ /gdal[@]?111/
        cmd_list.push("brew unlink gdal")
    #elsif file_without_extension =~ /gnupg[@]?21/
    #    cmd_list.push("brew unlink gnupg2 gpg-agent dirmngr")
    # 'Error: No such keg: /usr/local/Cellar/gnupg2' on xcode<=8
    elsif file_without_extension =~ /go[@]?[0-9]+/
        cmd_list.push("brew unlink go")
    elsif file_without_extension =~ /jpeg[@]?gb|jpeg[@]?6b/
        cmd_list.push("brew unlink jpeg")
    #elsif file_without_extension =~ /ruby[@]?192/
    #    cmd_list.push("brew unlink ruby")
    elsif file_without_extension =~ /subversion/
        cmd_list.push("brew unlink subversion")
    elsif file_without_extension =~ /povray[@]?36/
        cmd_list.push("brew unlink libpng")
    elsif file_without_extension =~ /postgresql[@]?[0-9]+/
        cmd_list.push("brew unlink postgresql")
    #elsif file_without_extension =~ /lz4[@]?r117/
    #    cmd_list.push("brew unlink lz4")
    elsif file_without_extension =~ /appledoc/
        cmd_list.push("rm /usr/local/include/c++")
        cmd_list.push("brew install gcc")
    elsif file_without_extension =~ /duplicity/
        cmd_list.push("pip install testrepository")
    elsif file_without_extension =~ /gcc[@]?6/
        cmd_list.push("rm /usr/local/include/c++")
    elsif file_without_extension =~ /automake/
        cmd_list.push("brew unlink automake")
    elsif file_without_extension =~ /autoconf/
        cmd_list.push("brew unlink autoconf")
    elsif file_without_extension =~ /kafka/
        cmd_list.push("brew cask reinstall java")
    elsif file_without_extension =~ /maven/
        cmd_list.push("brew unlink maven")
    #elsif file_without_extension =~ /open-mpi/
    #    cmd_list.push("brew unlink open-mpi")
    elsif file_without_extension =~ /gst-plugin-good/
        cmd_list.push("brew cask install xquartz")
    end

    return cmd_list
end

repo_name = ARGV[0]
output_file = ARGV[1]
tap_short_name = 'versions'

skip_builds = {
    "xcode8.2" => [
        "allegro@4",
        "appledoc@20",
        "appledoc@21",
        "gcc@43",
        "gcc@44",
        "gcc@45",
        "gcc@46", # Times out, check for problems on migrated!
        "gcc@47", # Times out, check for problems on migrated!
        "gcc@48", # Times out, check for problems on migrated!
        "gcc@49", # Times out, check for problems on migrated!
        "gcc@5", # Times out, check for problems on migrated!
        "go@16",
        "imagemagick-ruby@186", # https://github.com/Homebrew/homebrew-versions/issues/1407
        "llvm@35", # Times out
        "llvm@36", # Times out
        "llvm@37", # Times out
        "nu@0",
        "phantomjs@198",
        "subversion@17",
        "valgrind@38",
    ],
    "xcode8.1" => [
        "allegro@4",
        "gcc@43",
        "gcc@44",
        "gcc@45",
        "gcc@46", # Times out
        "gcc@47", # Times out
        "gcc@48", # Times out
        "gcc@49", # Times out
        "gcc@5", # Times out
        "go@16",
        "imagemagick-ruby@186", # https://github.com/Homebrew/homebrew-versions/issues/1407
        "llvm@35", # Times out
        "llvm@36", # Times out
        "llvm@37", # Times out
        "phantomjs@198",
    ],
    "xcode8" => [
        "gcc@44",
        "gcc@45",
        "gcc@47", # Times out
        "phantomjs@198",
    ],
    "xcode7.3" => [
        "gcc@44",
        "gcc@45",
        "gcc@46", # Times out
        "gcc@47", # Times out
        "phantomjs@198",
    ],
    "xcode6.4" => [
        "gcc@44",
        "gcc@49",
    ],
}

formulas = []
before_script = {}

if repo_name == 'reference'
    tap_author = 'homebrew'
    skip_builds.each do |xcode, skip_list|
        new_list = []
        for package in skip_list
            new_list.push(package.sub("-@", "-").sub("@", ""))
        end
        skip_builds[xcode] = new_list
    end

    for file_name in Dir["*.rb"]
        formula = File.basename(file_name, File.extname(file_name))
        formulas.push(formula)
    end

elsif repo_name == 'versions'
    tap_author = 'haraldnordgren'
    skip_builds.each do |xcode, skip_list|
        new_list = []
        for package in skip_list
            new_list.push(package.sub("-@", "@"))
        end
        skip_builds[xcode] = new_list
    end

    for file_name in Dir["Aliases/*"]
        if file_name == "Aliases/"
            next
        end

        formula = File.basename(file_name)
        formulas.push(formula)
    end

    before_script["xcode8"] = [
        "brew untap homebrew/versions",
    ]
    before_script["xcode7.3"] = [
        "brew untap homebrew/versions",
    ]
    before_script["xcode6.4"] = [
        "brew untap homebrew/versions",
    ]
end

formulas.sort!

before_script_prefix = [
    # "brew unlink maven",
]
before_script_suffix = [
    "brew tap #{tap_author}/#{tap_short_name}",
    "brew update",
]

includes = []
for xcode in ["xcode8.2", "xcode8.1", "xcode8", "xcode7.3", "xcode6.4"]
#for xcode in ["xcode8"]
    skip_build = skip_builds[xcode]

    if before_script.has_key?(xcode)
        xcode_before = before_script[xcode]
    else
        xcode_before = []
    end

    for formula in formulas
        if skip_build.include?(formula)
            next
        end

        unlink_before = package_specific_before_build_commands(formula)
        before = unlink_before + before_script_prefix + xcode_before + before_script_suffix

        # if file_without_extension ~= gst-plugins-bad010
        #    add option to sctip: "--HEAD"

        package_full_name = "#{tap_author}/#{tap_short_name}/#{formula}"
        includes.push({
            "env" => "Formula=#{formula}",
            "os" => "osx",
            "osx_image" => xcode,
            "before_script" => before,
            "script" => "travis_wait 50 ruby tests/build_formula.rb #{package_full_name}",
        })
    end
end

output_yml = {
    "language" => "ruby",
    "notifications" => {
        "email" => false
    },
    "git" => {
        "depth" => 10000,
    },
    "branches" => {
        "only" => [
            "master"
        ]
    },
    "matrix" => {
        "include" => includes
    },
}

#require 'awesome_print'
#ap output_yml.to_yaml
#puts

File.open(output_file,"w") do |file|
   file.write "# This file is auto-generated by #{File.basename(__FILE__)}\n"
   file.write output_yml.to_yaml
end
