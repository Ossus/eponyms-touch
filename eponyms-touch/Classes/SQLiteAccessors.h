/*
 *  SQLiteAccessors.h
 *  RenalApp
 *
 *  Created by Pascal Pfiffner on 18.08.09.
 *  Copyright 2009 Pascal Pfiffner. All rights reserved.
 *
 */

#import <sqlite3.h>


int prepareSqliteStatement(sqlite3 *db, sqlite3_stmt **intoStatement, const char *sqlString);
int stepSqlite(sqlite3_stmt *hs);

int beginSqliteTransaction(sqlite3 *db);
int endSqliteTransaction(sqlite3 *db);
