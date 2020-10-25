gcloud compute instances move
#Snapshot preparation
sudo shutdown -h mow
#If unmount isn't possible
#complete pending writes and flush cache
sudo sync
#suspend writing to the disk device
sudo fsfreeze -f /mount/point
