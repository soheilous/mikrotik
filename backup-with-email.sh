export file=ROS-Export

delay 5s

log/info "Current configuration exported successfully!"

system/backup/save name=ROS-Backup dont-encrypt=yes

delay 5s

log/info "ROS backed up successfully!"

tool/e-mail/send to=soheilvatanpoor@gmail.com subject="Daily Backup | $[/system/identity/get name] | $[/system/clock/get date]" body="This is a daily backup from ROS and UM DB. RouterOS version is $[/system/resource/get version]" file=ROS-Backup.backup,ROS-Export.rsc


/system/script/run Backup