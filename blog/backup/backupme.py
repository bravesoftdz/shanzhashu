#!/usr/bin/env python
#coding=utf-8
import MySQLdb
import os
import smtplib
import email
import time
import datetime
import mimetypes
import subprocess
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email import Utils, Encoders
import sys
reload(sys)
sys.setdefaultencoding('utf8')

conn = MySQLdb.connect(host='localhost', user='root', passwd='96gong1.com', charset="utf8")
curs = conn.cursor(cursorclass = MySQLdb.cursors.DictCursor)
curs.execute("SET NAMES utf8")
conn.select_db('mydata')

count = curs.execute('SELECT Max(f_id) as MaxId FROM my_content WHERE f_name = \'liuxiao\'')
row = curs.fetchone()
MaxId = row["MaxId"]
print "Max Id got %d" % (MaxId);

oldMaxId = 0;
if os.path.exists("id.txt"):
  lf = open('id.txt' )
  oldMaxId= int(lf.readline());
  print "Old Max Id %d" % (oldMaxId);

  if MaxId <= oldMaxId:
    print "No New Id Found. Exit"
    quit()
else:
  print 'No maxid, do backup.'

count = curs.execute('SELECT f_time, f_content FROM my_content WHERE f_name = \'liuxiao\'')
#print count
body = '';
for i in range(count):
  row = curs.fetchone()
  body = body + '\r\n' + row["f_time"].strftime('%Y-%m-%d %H:%M:%S') + '\r\n' + row["f_content"].encode('utf-8')
curs.close()
conn.close()

f = open('message.txt', 'w')
f.write(body)
f.flush
f.close

path=os.path.realpath(sys.path[0]) + '/message.txt'
print path

f=open(path, 'rb')
s=f.readlines()
#print s
f.close

returnCode = subprocess.call('./zipmsg.py')
print 'returncode:', returnCode  

time.sleep(5)

today = datetime.date.today()

#msg = MIMEText(body, 'plain', 'utf-8')
msg = MIMEMultipart()

msg['From'] = 'shanzhashu@163.com'
msg['To'] = 'liuxiaoshanzhashu@gmail.com'
msg['Subject'] = 'Backup Package ' + today.strftime('%Y-%m-%d %H:%M:%S')

f=open('./message.zip', 'rb')
s=f.read()
#print s
f.close

fd = file('./message.zip',"rb")
mimetype,mimeencoding = mimetypes.guess_type('./message.zip')
if mimeencoding or (mimetype is None):
    mimetype = "application/octet-stream"
maintype,subtype = mimetype.split("/")

if maintype == "text":
    att1 = MIMEText(fd.read(),_subtype = subtype)
else:
    att1 = MIMEBase(maintype,subtype)
    att1.set_payload(fd.read())
    Encoders.encode_base64(att1)
att1.add_header("Content-Disposition","attachment",filename = "message.zip")
fd.close()

#att1 = MIMEText(open('./message.zip', 'rb').read(), 'base64', 'utf-8')
#att1["Content-Type"] = 'application/octet-stream'
#att1["Content-Disposition"] = 'attachment; filename="message.zip"'
msg.attach(att1)

smtp = smtplib.SMTP()
smtp.connect("smtp.163.com", 25)
smtp.login("shanzhashu@163.com", "mypassword")
smtp.sendmail("shanzhashu@163.com", "liuxiaoshanzhashu@gmail.com", msg.as_string())
smtp.quit()
#print msg.as_string()
print "Mail send Success. Record MaxId"

os.remove("message.txt")
os.remove("message.zip")

lf = open('id.txt', 'w');
lf.write(str(MaxId));
lf.close;
print "Backup Success."

