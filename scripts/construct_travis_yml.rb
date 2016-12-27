require 'yaml'


repo_name = ARGV[0]
output_file = ARGV[1]

formulas = []

skip_builds = {}
for xcode in ["xcode8.2", "xcode8.1", "xcode8", "xcode7.3", "xcode6.4"]
    skip_builds[xcode] = []
end

skip_builds["xcode8.2"] = ["allegro@4"]

if repo_name == 'reference'
    # skip_packages_string = ARGV[0].gsub("-@", "-").gsub("@", "")
    puts Dir.pwd
    for file_name in Dir["*.rb"]
        puts file_name
        formula = File.basename(file_name, File.extname(file_name))
        formulas.push(formula)
    end

    #    for file_name in Dir["*.rb"]; puts File.basename(file_name, File.extname(file_name)); end

elsif repo_name == 'versions'
    # skip_packages_string = ARGV[0].gsub("-@", "@")
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


# for xcode in ["xcode8.2", "xcode8.1", "xcode8", "xcode7.3", "xcode6.4"]
for xcode in ["xcode8.2"]
    skip_build = skip_builds[xcode]

    for formula in formulas
        if skip_build.include?(formula)
            next
        end

        includes.push({
            "env" => "FORMULA=#{formula}",
            "osx_image" => xcode,
            "script" => 'ruby tests/build_formula.rb $FORMULA',
        })
    end
end

output_yml = {
    "language" => "ruby",
    "notifications" => {
        "email" => false
    },
    "branches" => {
        "only" => [
            "master"
        ]
    },
    "os" => "osx",
    "matrix" => {
        "include" => includes
    },
}


File.open(output_file,"w") do |file|
   file.write output_yml.to_yaml
end
