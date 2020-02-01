#!/usr/bin/python3
# Creates api listener to process incoming REST api
from flask import Flask
from flask_restful import Resource, Api, reqparse
from flaskext.mysql import MySQL
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
api = Api(app)
mysql = MySQL()
CORS(app, resources={r"/api/*": {"origins": "*"}})

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response
# MySQL configurations
app.config['MYSQL_DATABASE_USER'] = 'test_bot'
app.config['MYSQL_DATABASE_PASSWORD'] = 'password'
app.config['MYSQL_DATABASE_DB'] = 'TrainDb'
app.config['MYSQL_DATABASE_HOST'] = 'localhost'
app.config['MYSQL_DATABASE_SOCKET'] = ''
mysql.init_app(app)

class ActiveDevices(Resource):
    def get(self):
        conn = mysql.connect()
        curr = conn.cursor()
        curr.callproc('fetch_active_devices')
        data = curr.fetchone()
        if data is None:
            conn.close()
            return
        else:
            id = data[0]
            if data[1] == 1:
                status = 'online'
            else:
                status = 'offline'
            time_upd = datetime.timestamp(data[2])
            time_upd = datetime.fromtimestamp(time_upd)
            conn.close()
            return {'id': id, 'status':status, 'time':str(time_upd)}

class TamperedDevices(Resource):
    def get(self):
        conn = mysql.connect()
        curr = conn.cursor()
        curr.callproc('fetch_tampered_devices')
        data = curr.fetchone()
        if data is None:
            conn.close()
            return
        else:
            id = data[0]
            time_upd = datetime.timestamp(data[1])
            time_upd = datetime.fromtimestamp(time_upd)
            conn.close()
            return {'id': id, 'time':str(time_upd)}

class IdleDevices(Resource):
    def get(self):
        conn = mysql.connect()
        curr = conn.cursor()
        curr.callproc('fetch_idle_devices')
        data = curr.fetchone()
        if data is None:
            conn.close()
            return
        else:
            id = data[0]
            ready = int(data[1])
            halt = int(data[2])
            if ready == 1 and halt == 0:
                status = 'Ready'
            elif ready == 1 and halt == 1:
                status = 'Halt'
            else:
                status = 'UNKNOWN'
            conn.close()
            return {'id': id, 'status':status}

class ResetDevices(Resource):
    def post(self):
        conn = mysql.connect()
        curr = conn.cursor()
        curr.callproc('reset_device')
        conn.commit()
        curr.callproc('update_device_log_msg',('Reset By API',))
        conn.commit()
        conn.close()
        return

class HaltDevices(Resource):
    def post(self):
        conn = mysql.connect()
        curr = conn.cursor()
        curr.callproc('reset_device')
        conn.commit()
        curr.callproc('halt_device')
        conn.commit()
        curr.callproc('update_device_log_msg',('Halt by API',))
        conn.commit()
        conn.close()
        return

api.add_resource(ActiveDevices, '/active')
api.add_resource(TamperedDevices, '/tampered')
api.add_resource(IdleDevices, '/idle')
api.add_resource(ResetDevices, '/reset')
api.add_resource(HaltDevices, '/halt')

if __name__ == "__main__":
    app.run(host='172.20.10.6', debug=True)

