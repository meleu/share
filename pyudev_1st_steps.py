from pyudev import Context
for device in Context().list_devices(DEVNAME='/dev/input/js1'):
    device
