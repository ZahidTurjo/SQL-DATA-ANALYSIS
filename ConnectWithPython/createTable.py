import mysql.connector
db_name="python_test_db"
mydb_connection =mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database=db_name
    )


my_cursor=mydb_connection.cursor()

query="""
    CREATE TABLE students(
    roll varchar(5),
    name varchar(5)
    )
"""

my_cursor.execute(query)