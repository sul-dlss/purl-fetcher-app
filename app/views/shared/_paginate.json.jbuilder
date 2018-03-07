json.pages do
  json.current_page object.current_page
  json.next_page object.next_page
  json.prev_page object.prev_page
  json.total_pages object.total_pages
  json.per_page object.limit_value
  json.offset_value object.offset_value
  json.first_page? object.first_page?
  json.last_page?(object.last_page? || object.out_of_range?)
end
