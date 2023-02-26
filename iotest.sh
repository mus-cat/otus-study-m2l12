#!/bin/bash
bcount=50000

modprobe bfq
sleep 1
echo "bfq" > /sys/block/sda/queue/scheduler
sleep 1
echo "0" > /sys/block/sda/queue/iosched/low_latency

echo "Generate 2G test random file"
if ! [ -s "./file.rnd" ]; then
 dd if=/dev/urandom of=./file.rnd bs=1M count=2048 status=progress
fi

echo "Run background random read processes"
ionice -c2 -n7 fio ./rthread.fio &>/dev/null &
sleep 10
dd if=./file.rnd of=/dev/null bs=4K count=1000
echo "3" > /proc/sys/vm/drop_caches
sleep 2
dd if=./file.rnd of=/dev/null bs=4K count=1000

echo "Run sequential read our test file 3 times with diff priority"

echo "3" > /proc/sys/vm/drop_caches
sleep 1
echo "File read by process with class best-effort prioroty 7"
time ionice -c2 -n7 dd if=./file.rnd of=/dev/null bs=4K count=$bcount

echo -e "\n"
echo "3" > /proc/sys/vm/drop_caches
sleep 1
echo "File read by process with class beat-effort priority 0"
time ionice -c2 -n0 dd if=./file.rnd of=/dev/null bs=4K count=$bcount

echo -e "\n"
echo "3" > /proc/sys/vm/drop_caches
sleep 1
echo "File read by process with class realtime:"
time ionice -c1 -n7 dd if=./file.rnd of=/dev/null bs=4K count=$bcount

pkill fio

