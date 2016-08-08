json.deletes @deletes do |delete|
  json.druid delete.druid
  json.latest_change delete.deleted_at
end
