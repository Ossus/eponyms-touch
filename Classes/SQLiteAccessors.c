/*
 * SQLiteAccessors.c
 * RenalApp
 *
 * Created by Pascal Pfiffner on 18.08.09.
 * Adapted from source code by Marcus Grimm mgrimm@medcom-online.de
 * Copyright 2009 Pascal Pfiffner. All rights reserved.
 *
 */


#include <stdio.h>
#include <unistd.h>
#include <sqlite3.h>
#include "SQLiteAccessors.h"

#define kSQLITENumMaxRetries 4
#define kSQLITESleepMilliSec 50



// Prepares a SQLite statement retrying upon failure
int prepareSqliteStatement(sqlite3 *db, sqlite3_stmt **intoStatement, const char *sqlString)
{
	int n = 0;
	int response;
	
	// try to prepare
	do {
		response = sqlite3_prepare_v2(db, sqlString, -1, intoStatement, 0);
		if ((response == SQLITE_BUSY) || (response == SQLITE_LOCKED)) {
			n++;
			usleep(kSQLITESleepMilliSec);
		}
	}
	while ((n < kSQLITENumMaxRetries) && ((response == SQLITE_BUSY) || (response == SQLITE_LOCKED)));
	
	// no success after all
	if (response != SQLITE_OK) {
		fprintf(stderr, "SQLite: prepareSqliteStatement failed: (%d) %s \n", response, sqlite3_errmsg(db));
		fprintf(stderr, "Statement: %s \n", sqlString);
		return 0;
	}
	
	// success!
	return 1;
}


// Step an SQLite statement
int stepSqlite(sqlite3_stmt *query)
{
	int n = 0;
	int response;
	
	// try to step
	do {
		response = sqlite3_step(query);
		if (response == SQLITE_LOCKED) {
			response = sqlite3_reset(query);		// Note: This will return SQLITE_LOCKED as well...
			n++;
			usleep(kSQLITESleepMilliSec);
		}
		else if ((response == SQLITE_BUSY)) {
			n++;
			usleep(kSQLITESleepMilliSec);
		}
	}
	while ((n < kSQLITENumMaxRetries) && ((response == SQLITE_BUSY) || (response == SQLITE_LOCKED)));
	
	// no success after all...
	if (n == kSQLITENumMaxRetries) {
		fprintf(stderr, "sqlite3_step Timeout, response = %d\n", response);
	}
	
	// report multiple tries
	if (n > 2) {
		fprintf(stderr, "sqlite3_step tries: %d\n", n);
	}
	
	// report SQLITE_MISUSE
	if (response == SQLITE_MISUSE) {
		fprintf(stderr, "sqlite3_step misuse\n");
	}
	
	return response;
}


// Begin an exclusive transaction
int beginSqliteTransaction(sqlite3 *db)
{
	int response;
	sqlite3_stmt *bt_stmt;
	bt_stmt = NULL;
	if (db == NULL) {
		fprintf(stderr, "SQLite: beginSqliteTransaction: No DB connection!\n");
		return 0;
	}
	
	// prepare failed
	if (!prepareSqliteStatement(db, &bt_stmt, "BEGIN EXCLUSIVE TRANSACTION")) {
		fprintf(stderr, "SQLite: Begin Transaction error\n");
		return 0;
	}
	
	// execute!
	response = stepSqlite(bt_stmt);
	sqlite3_finalize(bt_stmt);
	
	// something went wrong
	if (response != SQLITE_DONE) {
		fprintf(stderr, "SQLite: beginSqliteTransaction Timeout/Error, Errorcode = %d \n", response);
		return 0;
	}
	
	return 1;
}


// End the exclusive transaction
int endSqliteTransaction(sqlite3 *db)
{
	int response;
	sqlite3_stmt *bt_stmt;
	if (db == NULL) {
		fprintf(stderr, "SQLite: endSqliteTransaction: No DB connection!\n");
		return 0;
	}
	
	// prepare failed
	if (!prepareSqliteStatement(db, &bt_stmt, "COMMIT")) {
		fprintf(stderr, "SQLite: endSqliteTransactionaction prepare failed/timeout\n");
		return 0;
	}
	
	// execute the commit
	response = stepSqlite(bt_stmt);
	sqlite3_finalize(bt_stmt);
	
	if (response != SQLITE_DONE) {
		fprintf(stderr, "SQLite: endSqliteTransaction Step Timeout, code = %d\n", response);
		return 0;
	}
	
	return 1;
}

