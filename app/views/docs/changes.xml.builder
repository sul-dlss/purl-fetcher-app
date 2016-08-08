xml.results do
  xml.changes do
    @changes.each do |change|
      xml.change do
        xml.druid change.druid
        xml.latest_change change.indexed_at.iso8601
        xml.true_targets do
          change.release_tags.where(release_type: true).each do |true_target|
            xml.true_target true_target.name
          end
        end
        xml.false_targets do
          change.release_tags.where(release_type: false) do |false_target|
            xml.false_target false_target.name
          end
        end
        xml.collections do
          change.collections.each do |collection|
            xml.collection collection.druid
          end
        end
      end
    end
  end
end
