#!/bin/bash
file=$1  #filename
user=$2  #username for ssh
host=$3  #remote hostname or ip
outfile=$4 #output filename


extension=$(echo "${outfile#*.}")

rnd_filename=$(echo $RANDOM | md5sum | head -c 8).$extension
echo "random filename: $rnd_filename"

trap "[ -z "$ctl" ] || ssh -S $ctl -O exit $user@$host" EXIT # closes conn, deletes fifo
sshfifos=~/.ssh/controlmasters
[ -d $sshfifos ] || mkdir -p $sshfifos; chmod 755 $sshfifos
ctl=$sshfifos/$user@$host:22 # ssh stores named socket for open ctrl conn here

ssh -fNMS $ctl $user@$host  # Control Master: Prompts passwd then persists in background

#create remote temp folder
rmtdir=$(ssh -S $ctl $user@$host "mktemp -d /tmp/XXXX"); echo      "Remote dir: $rmtdir"

#copy the file to process to the remote folder
scp -o ControlPath=$ctl "$1" $user@$host:$rmtdir 

#run the process outside
ssh -S $ctl $user@$host "ffmpeg -hwaccel auto -i '$rmtdir/$file' -bsf:v h264_mp4toannexb -sn -map 0:0 -map 0:1 -vcodec libx264 '$rmtdir/$rnd_filename'"

#copy the resulting file back to the local environment
scp -o ControlPath=$ctl $user@$host:$rmtdir/$rnd_filename .

#cleanup: delete files and folders on the remote host
ssh -S $ctl $user@$host "rm $rmtdir/*.*; rmdir $rmtdir"

#change the name of the local file
mv $rnd_filename "$outfile"