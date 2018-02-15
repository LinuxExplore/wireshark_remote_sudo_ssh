@echo off

rem Figure out path to plink.exe
set plink="plink.exe"
if not exist %plink% (
	cmd /k echo Please download %plink% from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html and copy to current directory.
	exit /b 1
)

rem Figure out path to wireshark.exe
set wireshark_dir_key="HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Wireshark"
for /f "tokens=3*" %%x in ('reg query %wireshark_dir_key% /v "InstallLocation"') do set wireshark_dir=%%x %%y
if not defined wireshark_dir (
    cmd /k echo Please install Wireshark using Windows installer from https://www.wireshark.org/download.html
    exit /b 1
)
set wireshark="%wireshark_dir%\Wireshark.exe"

rem Ask for hostname if not specified as first parameter
set host=%1
if not defined host (
	set /p host= What SSH host do you want to capture from? 
)

if not defined host (
	cmd /k echo Please define host.
	exit /b 1
)

rem interface for tcpdump capture
set iface=any

rem Default to a sensible pattern if not specified as the third parameter
set pattern="not host %host% and not host 127.0.0.1 and not port 22"

rem Ask for user
set user=%2
if not defined user (
    set /p user= Enter the sudoer username of %host%: 
)

if not defined user (
	cmd /k echo Please enter the username.
	exit /b 1
)

rem Ask for password
set password=%3
if not defined password (
    set /p password= Enter the password of %user%: 
	cls
)

if not defined password (
	cmd /k echo Please enter the password.
	exit /b 1
)

set commands_srv="mkfifo /tmp/test.fifo; chmod +r /tmp/test.fifo; sudo -- sh -c '/usr/sbin/tcpdump -i any -w /tmp/test.fifo -s 0 not port 22; rm -f /tmp/test.fifo'"
set timeout="15"

echo Please enter password of %user% again, wireshark will start in %timeout% seconds.
rem Starting wireshark server in host
START /B plink -t -ssh -l admin -pw %password% %host% sudo -- sh -c 'rm -f /tmp/test.fifo; mkfifo /tmp/test.fifo; chmod +r /tmp/test.fifo; /usr/sbin/tcpdump -i any -w /tmp/test.fifo -s 0 not port 22; rm -f /tmp/test.fifo'
timeout %timeout% > NUL

set commands_client="'cat /tmp/test.fifo' | %wireshark% -k -i -"

rem Run tcpdump with output to pipe and read pipe from wireshark
echo Starting WireShark Application
%plink% -ssh -l admin -pw %password% %host% "cat /tmp/test.fifo" | %wireshark% -k -i -

cls
echo Closing, please wait a while
