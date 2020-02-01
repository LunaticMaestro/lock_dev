#!/usr/bin/python3
# Creates a program that routinly checks the active devices for tamper
#import modules
import mysql.connector, time, json
from conf import DB_USR, DB_PASS, DB_HOST, DB_DbName, TIME_SL_SURV, LED, TPIN
from boltiot import Bolt
from sms_routine import sendSms

def tamper_check(device_id, device_api, sql_curr, db):
    # Init bolt instance
    mydevice = Bolt(device_api, device_id)
    # Check device status
    response = mydevice.isOnline()
    if 'online' in response:
        mydevice.digitalWrite(LED, 'HIGH')
        # CHECK TAMPER PIN
        tamper_pin = json.loads(mydevice.digitalRead(TPIN))
        if tamper_pin['value'] == '1':
            print ("Status OK", device_id)
            # LOG UPDATE
            sql_curr.callproc('log_update', ('1', 'Routine Check', '0'))
            db.commit()
            # ActiveDevice TABLE update
            sql_curr.callproc('update_status', ('1', '0'))
            db.commit()
        else:
            print ("TAMPERED!!_,DEVICE_ID:", device_id)
            # REGISTERED TAMPER
            sql_curr.callproc('update_status', ('1', '1'))
            db.commit()
            sql_curr.callproc('log_update', ('1', 'Lock tampered', '1'))
            db.commit()
            sql_curr.callproc('deactivate_device')
            db.commit()
            # TURN OFF GLOW
            mydevice.digitalWrite(LED, 'LOW')
            # SEND SMS
            sql_curr.callproc('get_tamper_report')
            data = sql_curr.stored_results()
            for d in data:
                row = d.fetchone()
                msg = "TAMPERED DEVICE ID {} TIME {}".format(device_id, row[1])
                sendSms(row[0].strip(), msg)
                break
    else:
        sql_curr.callproc('update_status', ('0', '0'))
        db.commit()
        sql_curr.callproc('log_update', ('0', 'Device OFFLINE', '0'))
        db.commit()
    del mydevice
    return

if __name__ == "__main__":
    # Fetch Active Devices
    while(True):
        # setup connection
        conn = mysql.connector.connect(user = DB_USR, password = DB_PASS, host = DB_HOST, database = DB_DbName)
        curr =  conn.cursor()
        curr.callproc('fetch_active_device_with_api')
        data = curr.stored_results()
        for datum in data:
            #print(dir(data))
            while(True):
                # For each active device
                row = datum.fetchone()
                if row == None:
                    break
                if 'None' in row:
                    print("No Active Devices yet!")
                else:
                    # TAMPER CHECK
                    #print(row)
                    tamper_check(row[0], row[1], curr, conn)
        time.sleep(TIME_SL_SURV)
        # CLOSE CONNECTION
        conn.close()
