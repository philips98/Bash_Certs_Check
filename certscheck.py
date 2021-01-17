import subprocess

#output = subprocess.run(['openssl', 'x509', '-enddate', '-noout', '-in', 'test0.com.crt'], stdout=subprocess.PIPE)
#output.stdout.decode('utf-8')
#subprocess.popen('certcheck.sh')
output = subprocess.check_output(['openssl', 'x509', '-enddate', '-noout', '-in', 'test4.com.crt'])
print(output)