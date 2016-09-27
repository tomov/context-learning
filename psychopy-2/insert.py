import mysql.connector

cnx = mysql.connector.connect(user='root', database='context')
cursor = cnx.cursor()

cols = ["participant", "session", "mriMode", "isPractice", "expStart",
    "restaurantNames", "foods", "contextRole", "contextId", "cueId", "sick", "corrAns", "responseKey", "restaurant",
    "food", "roundId", "trialId", "trainOrTest", "stimOnset", "responseTime", "feedbackOnset"]

trial_data = {
    "participant": "9",
    "session": "1",
    "mriMode": "off",
    "isPractice": "1", # convert
    "expStart": "1990-03-02 20:00:00", # convert
    "restaurantNames": "Breakfast at Tiffany's,Sweet Maple,Mission Beach Cafe", # shuffled
    "foods": "food0,food1,food2", # shuffled
    "contextRole": "modulatory",
    "contextId": "1",
    "cueId": "0",
    "sick": "Yes",
    "corrAns": "left",
    "responseKey": "left",
    "restaurant": "Sweet Maple",
    "food": "food0",
    "roundId": "1",
    "trialId": "2",
    "trainOrTest": "train",
    "stimOnset": "2016-03-02 10:00:00.23234", # fmri clock, convert
    "responseTime": "2016-03-02 11:00:00.02423",
    "feedbackOnset": "2016-03-02 11:11:11.234234" # fmri clock, convert
}

insert_query = ("INSERT INTO data (" + ','.join(cols) + ") VALUES (" + ','.join("%(" + s + ")s" for s in cols) + ")")

print insert_query

cursor.execute(insert_query, trial_data)
cnx.commit()


cursor.close()
cnx.close()

