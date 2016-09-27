from flask import Flask, render_template
import random
import os
import json

# start Flask app
#
app = Flask(__name__)

dataFilename = None
dataFile = None
dataDir = os.path.join('..', 'data')


def getLatestFile():
    global dataFilename
    global dataFile
    files = [f for f in os.listdir(dataDir) if f.endswith('.wtf')]
    dataFilename = files[-1]
    print 'last file = ', dataFilename
    dataFile = open(os.path.join(dataDir, dataFilename), 'r')

@app.route('/')
def index():
    getLatestFile()
    return render_template('test.html')

@app.route('/get_next', methods=['GET'])
def get_next():
    global dataFile
    lines = []
    print ' --------- GET ! ---------- '
    while True:
        line = dataFile.readline()
        if not line:
            break # no more lines... for now
        lines.append(line)
        print '    line = ', line
    return json.dumps(lines)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
