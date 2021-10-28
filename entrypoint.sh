#!/bin/bash

# Default value for USER_ID
USER_ID=${LOCAL_USER_ID:-9001}
echo "USERNAME: $USERNAME, UID: $USER_ID"

# Create User
useradd --shell /bin/bash -u $USER_ID -d /home/$USERNAME -o -c "" $USERNAME

# Create Directory only if it doesn't exist
# This prevents the issue - useradd: warning: the home directory already exists.
if [ ! -d "/home/$USERNAME" ]; then
    mkdir /home/$USERNAME
fi

cp -r /root/.eldev /home/$USERNAME
chown -R $USER_ID:$USER_ID /home/$USERNAME
export PATH=$PATH:/home/$USERNAME/.eldev/bin

# Execute the process as the given user
exec /usr/sbin/gosu $USERNAME "$@"
