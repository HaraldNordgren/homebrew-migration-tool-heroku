require 'yaml'


repo_name = ARGV[0]
output_file = ARGV[1]

envs = []

if repo_name == 'reference'
    # skip_packages_string = ARGV[0].gsub("-@", "-").gsub("@", "")
    for file_name in Dir["*.rb"]
        formula = File.basename(file_name, File.extname(file_name))
        envs.push("FORMULA=#{formula}")
    end

elsif repo_name == 'versions'
    # skip_packages_string = ARGV[0].gsub("-@", "@")
    for file_name in Dir["Aliases/*"]
        formula = File.basename(file_name)
        envs.push("FORMULA=#{formula}")
    end
end

envs.sort!

includes = []

for env in envs
    # for xcode in ["xcode8.2", "xcode8.1", "xcode8", "xcode7.3", "xcode6.4"]
    for xcode in ["xcode8.2"]
        includes.push({
            "env" => env,
            "osx_image" => xcode,
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
    #"osx_image" => [
    #    "xcode8.2",
    #    "xcode8",
    #],
    #"env" => envs,

    "matrix" => {
        "include" => includes
    },

    "script" => [
        'ruby tests/build_formula.rb $FORMULA'
    ],
}


File.open(output_file,"w") do |file|
   file.write output_yml.to_yaml
end
