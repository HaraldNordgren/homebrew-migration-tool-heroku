puts "Getting build history..."
job_ids = `travis history | awk '{ print $1 }'`
puts "DONE, canceling all jobs except for #{job_ids[0]}"
puts

for id_string in job_ids.split[1..-1]
    job_id = id_string[1..-1]
    puts "Canceling " + job_id
    `travis cancel #{job_id}`
end

