setlocal
set URL=http://localhost:9090
set URL=http://iron.eiffel.com/ewo/app--cgi.cgi
set SESS=1234
set NAME=%1
set TEXT=%2

curl %URL%/api/session/%SESS%/item/%NAME% --form "value=%TEXT%"
endlocal
