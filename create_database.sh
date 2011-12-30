#!/bin/bash

# create_database.sh
# eponyms-touch
#
# Created by Pascal Pfiffner on 21.06.10.
# Copyright 2010 Pascal Pfiffner. All rights reserved.


touch 'eponyms.sqlite'

sqlite3 'eponyms.sqlite' <<QUERY_END
	CREATE TABLE IF NOT EXISTS categories (category_id INTEGER PRIMARY KEY, tag VARCHAR UNIQUE, category_en VARCHAR);
QUERY_END

sqlite3 'eponyms.sqlite' <<QUERY_END
	CREATE TABLE IF NOT EXISTS category_eponym_linker (category_id INTEGER, eponym_id INTEGER);
QUERY_END

sqlite3 'eponyms.sqlite' <<QUERY_END
	CREATE TABLE IF NOT EXISTS eponyms (eponym_id INTEGER PRIMARY KEY, identifier VARCHAR UNIQUE, eponym_en VARCHAR, text_en TEXT, created INTEGER, lastedit INTEGER, lastaccess INTEGER, starred INTEGER DEFAULT 0);
QUERY_END
