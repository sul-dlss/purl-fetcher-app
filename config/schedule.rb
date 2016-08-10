# Learn more: http://github.com/javan/whenever

set :output, '/dev/null'

every 1.day do
 rake 'find:all' # does full scan of everything both changes and delete
end

every 15.minutes do
 rake 'find:deletes[15]' # scan .deletes directory for new deletes
end
