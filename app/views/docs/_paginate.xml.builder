xml.pages do
  xml.current_page object.current_page
  xml.next_page object.next_page
  xml.prev_page object.prev_page
  xml.total_pages object.total_pages
  xml.per_page object.limit_value
  xml.offset_value object.offset_value
  xml.first_page object.first_page?
  xml.last_page object.last_page?
end
