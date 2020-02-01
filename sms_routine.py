# Creates a program to send sms using twillo api

import conf, json, time 
from boltiot import Sms, Bolt 

def sendSms(phno, msg):
    #print ('SMS')
    print (type(phno))
    print ("_",phno,"_")
    #print (msg)
    sms = Sms(conf.SID, conf.AUTH_TOKEN, phno, conf.FROM_NUMBER)
    try:
        print("SMS REQ")
        response = sms.send_sms(msg)
        print("RESP OF SMS TWIL: "+ str(response))
        print("     RESP STATUS: "+ str(response.status))
    except Exception as e:
        print ("Error",e)

#sendSms('+919998887776', 'msg')
