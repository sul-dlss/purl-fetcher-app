# Learn more: http://github.com/javan/whenever

set :output, '/dev/null'

every 15.minutes do
 rake 'find:deletes[15]' # scan .deletes directory for new deletes
end

# ensures that all changes touch files are processed if the listener was down
every 1.hour do
  rake 'listener:recent_changes:process'
end

every :reboot do
  rake 'listener:restart'
end
