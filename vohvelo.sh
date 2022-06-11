#!/bin/bash
user=aresuser
host=192.168.31.114

trap "[ -z "$ctl" ] || ssh -S $ctl -O exit $user@$host" EXIT # closes conn, deletes fifo
sshfifos=~/.ssh/controlmasters
[ -d $sshfifos ] || mkdir -p $sshfifos; chmod 755 $sshfifos
ctl=$sshfifos/$user@$host:22 # ssh stores named socket for open ctrl conn here

ssh -fNMS $ctl $user@$host  # Control Master: Prompts passwd then persists in background

#lcldir=$(mktemp -d /tmp/XXXX);                           echo -e "\nLocal  dir: $lcldir"
rmtdir=$(ssh -S $ctl $user@$host "mktemp -d /tmp/XXXX"); echo      "Remote dir: $rmtdir"

scp -o ControlPath=$ctl $1 $user@$host:$rmtdir 

ssh -S $ctl $user@$host "ffmpeg -hwaccel auto -i $rmtdir/$1 -bsf:v h264_mp4toannexb -sn -map 0:0 -map 0:1 -vcodec libx264 $rmtdir/out.mp4"
scp -o ControlPath=$ctl $user@$host:$rmtdir/out.mp4 .
ssh -S $ctl $user@$host "rm $rmtdir/*.*; rmdir $rmtdir"
