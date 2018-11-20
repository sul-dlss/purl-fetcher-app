json.extract! collection, :druid, :catkey

json.true_targets collection.true_targets if collection.true_targets.present?
json.false_targets collection.false_targets if collection.false_targets.present?
