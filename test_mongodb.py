from mongomock import MongoClient

client = MongoClient()
db = client.test_db
col = db.test_col
col.insert_one({"name": "test", "value": 42})
doc = col.find_one({"name": "test"})
assert doc["value"] == 42, "MongoDB mock test failed"
print("All MongoDB mock tests passed!")
