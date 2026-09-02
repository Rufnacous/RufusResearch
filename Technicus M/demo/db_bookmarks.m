function [datasets] = db_bookmarks(bookmark_name)

    bookmarks.test1.filter.type = 'test1';
    bookmarks.aggtest1.filter.type = 'aggregate_test1';

    datasets = get_datasets(Database(), bookmarks.(bookmark_name));
end