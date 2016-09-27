from flask import Flask, render_template
import random
import os
import json

import mysql.connector

cols = ["participant", "session", "mriMode", "isPractice", "expStart",
        "restaurantNames", "foods", "contextRole", "contextId", "cueId", "sick", "corrAns", "responseKey", "reactionTime", "responseIsCorrect", "restaurant",
        "food", "roundId", "trialId", "trainOrTest", "stimOnset", "responseTime", "feedbackOnset"]

query = ("SELECT " + ','.join(cols) + " FROM data WHERE participant = %s AND session = %s ORDER BY id")

# start Flask app
#
app = Flask(__name__)

@app.route('/')
def index():
    return render_template('test.html')

@app.route('/get_next', methods=['GET'])
def get_next():
    cnx = mysql.connector.connect(user='root', database='context')
    cursor = cnx.cursor()
    cursor.execute(query, ('', '001'))
    res = []
    for row in cursor:
        res.append([str(x) for x in list(row)])
    cursor.close()
    cnx.close()
    print res
    return json.dumps(res)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
