import signal
import time

SIGTERM_RECEIVED = False
def signal_hanler(sig, frame):
    print("Received signal", sig)
    if sig == signal.SIGTERM:
        SIGTERM_RECEIVED = True

catchable_sigs = set(signal.Signals) - {signal.SIGKILL, signal.SIGSTOP}
for sig in catchable_sigs:
    signal.signal(sig, signal_hanler)

while True:
    time.sleep(0.1)
    if SIGTERM_RECEIVED:
        print("Begin faking 5-sec cleanup on preemption")
        time.sleep(5)
        print("End faking 5-sec cleanup on preemption")
        # Still exit with non-zero code to ensure requeued
        raise SystemExit(42)
