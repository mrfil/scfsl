from subprocess import Popen, PIPE
p = Popen(['python fslinstaller.py'], stdin=PIPE, shell=True)
p.communicate(input='\n')
