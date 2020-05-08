Build with

    docker build --tag smbmount_test .

and run with

    docker run --privileged --cap-add SYS_ADMIN --cap-add DAC_READ_SEARCH --name smbmount_test smbmount_test

References:

    https://github.com/moby/moby/issues/22197
    https://stackoverflow.com/questions/27989751/mount-smb-cifs-share-within-a-docker-container
