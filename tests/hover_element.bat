setlocal
set URL=http://localhost:9090
set NAME=%1

curl %URL%/api/message/hover/%NAME% 
endlocal
