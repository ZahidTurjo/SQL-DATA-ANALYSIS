import mysql.connector
mydb_connection =mysql.connector.connect(
    host="localhost",
    user="root",
    password=""
)

db_name="python_test_db"

my_cursor=mydb_connection.cursor()

query="CREATE DATABASE "+db_name

my_cursor.execute(query)