// Asserts the IOKit power-management port ShutOff uses is reachable. Never calls IOPMSleepSystem.
import IOKit.pwr_mgt
let port = IOPMFindPowerManagement(kIOMainPortDefault)
precondition(port != 0, "IOPMFindPowerManagement returned 0")
IOServiceClose(port)
print("ok: IOPM port \(port)")
