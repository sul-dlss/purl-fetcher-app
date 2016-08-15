if true_targets.present?
  xml.true_targets do
    true_targets.each do |true_target|
      xml.true_target true_target
    end
  end
end