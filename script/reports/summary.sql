SELECT 'PURLs', COUNT(*) FROM purls;
SELECT 'Deleted PURLs', COUNT(*) FROM purls WHERE deleted_at IS NOT NULL;
SELECT 'Published PURLs', COUNT(*) FROM purls WHERE published_at IS NOT NULL;
SELECT 'Published this year', COUNT(*) FROM purls WHERE published_at >= '2016-01-01';
SELECT 'Released to SearchWorks', COUNT(*) FROM purls
  INNER JOIN release_tags ON release_tags.purl_id = purls.id
  WHERE release_tags.name = 'SearchWorks' AND release_tags.release_type;
