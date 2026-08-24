function [bookmark] = db_bookmarks(bookmark_name)

    bookmarks.test1.filter.type = 'test1';

    bookmark = get_datasets(get_db(), bookmarks.(bookmark_name));
end