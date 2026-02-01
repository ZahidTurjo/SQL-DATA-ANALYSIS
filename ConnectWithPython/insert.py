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
    INSERT INTO students(roll,name)
    values("1","Turjo")
"""

my_cursor.execute(query)
mydb_connection.commit()
print("INSERT VALUE SUCCESSFULLY")