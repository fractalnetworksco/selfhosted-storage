# Volume registration
POST /api/v1/s4/volume
- move endpoint to volume metadata api that triggers celery task to setup onlyrc, creates user directory and sets authorized_key with --restrict-to-path
- sets restrict to path on borg serve to the volume repo and reposnap directory of the volume

# Volume Syncing
- repo-snap endpoint will return temporarty remote for agent to sync from
 - it also gets or creates a DeviceVolumeSyncEvent that stores the last_synced timestamp that will be updated once the device has succesfully synced
/api/v1/s4/volumes/<vol-id>/<device-id>/sync
{
    "remote": "borg@remote:/volumes/<user-id>/reposnaps/<volume-id>/<snap-id>"
}
- agent calls `s4 sync <reposnap_tmp_remote>` which will pull using the temp remote
- volumes without app instance use an all zero UUID

## Reposnap cleanup
- once agent has synced from temp remote it will POST to endpoint that will teardown reposnap and log that the device has successfully synced
    DELETE /api/v1/s4/volumes/<vol-id>/reposnap/<snap-id>
- periodic task that looks for reposnaps older than 1 minute that no longer have an active borg lock and removes them


# System services
- implement s4 as a mosaic system service
