

db = get_db();

blank_datasets(db, 2, "test_", @(i) struct('type', 'test1', 'number', i))

perform_task( db, db_bookmarks('test1'), t_duplicate_random_value() );

