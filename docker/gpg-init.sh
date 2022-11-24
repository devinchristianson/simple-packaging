#!/bin/bash
if [[ $GPG_PRIVATE_KEY && $GPG_KEY_ID ]]; then
    echo "$GPG_PRIVATE_KEY" | gpg --import
    echo "%_signature gpg
    %_gpg_name $GPG_KEY_ID" > /root/.rpmmacros
fi

if [[ $@ ]]; then
    $@
fi