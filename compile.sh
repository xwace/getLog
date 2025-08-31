#!/usr/bin/expect

set ip_head 10.10.35.

#搜索所有网域内可用的ip
# for {set i 151} {$i < 255} {incr i} {
#     set timeout 1
#     spawn ssh root@$ip_head$i
#     expect "password"
# }

spawn sh -c {
    cd build
    echo "\e[36m===choose platform===: \e[0m"
    # read input
    cmake .. -DCHOOSE_PLATFORM=1 #$input
    make -j32 
    ./BFStest }

interact
sleep 20000

# spawn scp ./build/BFStest root@$ip:/home/robot/business/log
# expect "password"
# send "yx113322\r"

# spawn ssh root@$ip
# expect "password:"
# send "yx113322\r"
# expect "#"
# send "cd /home/robot/business/log\r"
# send "./BFStest\r"
# send "rm BFStest;exit"
# interact
