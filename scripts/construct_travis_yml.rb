require 'yaml'


repo_name = ARGV[0]
output_file = ARGV[1]

formulas = []

skip_builds = {
    "xcode8.2" => [
        "allegro-@4",
        "appledoc-@20",
        "appledoc-@21",
    ],
    "xcode8.1" => [],
    "xcode8" => [],
    "xcode7.3" => [],
    "xcode6.4" => [],
}

if repo_name == 'reference'
    # skip_packages_string = ARGV[0].gsub("-@", "-").gsub("@", "")
    skip_builds.each do |xcode, skip_list|
        new_list = []
        for package in skip_list
            new_list.push(package.sub("-@", "-").sub("@", ""))
        end
        skip_builds[xcode] = new_list
    end

    puts Dir.pwd
    for file_name in Dir["*.rb"]
        puts file_name
        formula = File.basename(file_name, File.extname(file_name))
        formulas.push(formula)
    end

elsif repo_name == 'versions'
    # skip_packages_string = ARGV[0].gsub("-@", "@")
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
end

formulas.sort!

includes = []

before_script = {
    "xcode8.2" => [
        "brew unlink automake",
        "brew unlink autoconf",
        "brew unlink maven",
    ],
    "xcode8.1" => [
        "brew unlink automake",
        "brew unlink autoconf",
        "brew unlink maven",
    ],
    "xcode8" => [
        "brew unlink automake",
        "brew unlink autoconf",
        "brew unlink maven",
        "brew untap homebrew/versions",
    ],
    "xcode7.3" => [
        "brew unlink automake",
        "brew unlink autoconf",
        "brew unlink maven",
        "brew untap homebrew/versions",
    ],
    "xcode6.4" => [
        "brew unlink automake",
        "brew unlink autoconf",
        "brew unlink maven",
        "brew untap homebrew/versions",
    ],
}

# for xcode in ["xcode8.2", "xcode8.1", "xcode8", "xcode7.3", "xcode6.4"]
for xcode in ["xcode8.2"]
    skip_build = skip_builds[xcode]
    before = before_script[xcode]

    for formula in formulas
        if skip_build.include?(formula)
            next
        end

        includes.push({
            "language" => "ruby",
            "env" => "FORMULA=#{formula}",
            "os" => "osx",
            "osx_image" => xcode,
            "before_script" => before,
            "script" => 'travis_wait 50 ruby tests/build_formula.rb $FORMULA',
        })
    end
end

output_yml = {
    "notifications" => {
        "email" => false
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
   file.write output_yml.to_yaml
end
