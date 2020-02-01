#!/usr/bin/python3
# Creates a program that routinely checks if any unlocked device requests for getting locked
from boltiot import Bolt
from conf import TIME_SL_SPR, BLK_INTV
from conf import DB_USR, DB_PASS, DB_HOST, DB_DbName, TIME_SL_SURV, TPIN, LED
from time import sleep
import json
import mysql.connector

def service_check(device_id, device_api, sql_curr, db):
    # Init bolt instance
    mydevice = Bolt(device_api, device_id)
    # Check device status
    response = mydevice.isOnline()
    if 'online' in response:
        # GLOW RESPONSE BULB
        mydevice.digitalWrite(LED, 'HIGH')
        # CHECK TAMPER PIN
        tamper_pin = json.loads(mydevice.digitalRead(TPIN))
        if tamper_pin['value'] == '1':
            print ("LOCK INIT__DEVICE:", device_id)
            # LOG UPDATE
            sql_curr.callproc('log_update', ('1', 'Lock Activated', '0'))
            db.commit()
            # MOVE TO ACTIVE DEVICES
            sql_curr.callproc('activate_device')
            db.commit()
            # BLINK RESPONSE BULB
            for i in range(3):
                mydevice.digitalWrite(LED, 'LOW')
                sleep(BLK_INTV)
                mydevice.digitalWrite(LED, 'HIGH')
                sleep(BLK_INTV)
        #else:
            # REGISTERED TAMPER
            #sql_curr.callproc('log_update', args = (1, 'Lock found tampered', 1))
            #sql_curr.callproc('faulty_device')
    del mydevice
    return 

if __name__ == "__main__":
    print ('SLEEPER ROUTINE STARTER...')
    # setup connection
    try:
        # Fetch Active Devices
        while(True):
            conn = mysql.connector.connect(user = DB_USR, password = DB_PASS, host = DB_HOST, database = DB_DbName)
            curr = conn.cursor()
            #conn.begin()
            curr.callproc('fetch_ready_devices')
            data = curr.stored_results()
            for datum in data:
                #print(dir(data))
                while(True):
                    # For each active device
                    record = datum.fetchone()
                    #print (record)
                    if record == None:
                        break
                    if 'None' in record:
                        print("NONE: NO READY Devices yet!")
                    else:
                        # SERVICE_CHECK
                        service_check(record[0], record[1], curr, conn)
            #curr.close()
            conn.close()
            sleep(TIME_SL_SPR)
        # CLOSE CONNECTION
    except Exception as err:
        print(err)
