# Learn more: http://github.com/javan/whenever

set :output, '/dev/null'

every 15.minutes do
 rake 'find:deletes[15]' # scan .deletes directory for new deletes
end

every 1.hour do
  rake 'listener:touch_all' # ensure touch files get processed
end
