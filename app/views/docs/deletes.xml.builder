xml.results do
  xml.deletes do
    @deletes.each do |delete|
      xml.delete do
        xml.druid delete.druid
        xml.latest_change delete.deleted_at.iso8601
      end
    end
  end
end
