json.purls do
  json.array! @purls, partial: 'purls/purl', as: :purl
end
json.partial! 'shared/paginate', locals: { object: @purls }
