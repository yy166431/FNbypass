#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static BOOL ret_yes(id self, SEL _cmd) { return YES; }
static BOOL ret_no(id self, SEL _cmd) { return NO; }
static void ret_void(id self, SEL _cmd, ...) {}

__attribute__((constructor))
static void bypass_init(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class mgr = objc_getClass("GRNActivationManager");
        if (!mgr) return;

        SEL sels_yes[] = {
            sel_registerName("hasLocalSession"),
            sel_registerName("startupValidationPassed"),
            sel_registerName("isActivated"),
        };
        for (int i = 0; i < 3; i++) {
            Method m = class_getInstanceMethod(mgr, sels_yes[i]);
            if (m) method_setImplementation(m, (IMP)ret_yes);
        }

        SEL sels_no[] = {
            sel_registerName("isDebuggerAttached"),
        };
        for (int i = 0; i < 1; i++) {
            Method m = class_getInstanceMethod(mgr, sels_no[i]);
            if (m) method_setImplementation(m, (IMP)ret_no);
        }

        SEL sels_void[] = {
            sel_registerName("armActivationForceExitTimerWithReason:"),
            sel_registerName("onActivationForceExitTimerFired:"),
            sel_registerName("exitApplication"),
            sel_registerName("handleSessionInvalidWithMessage:"),
            sel_registerName("setFeatureLocked:reason:"),
            sel_registerName("clearLocalSession"),
        };
        for (int i = 0; i < 6; i++) {
            Method m = class_getInstanceMethod(mgr, sels_void[i]);
            if (m) method_setImplementation(m, (IMP)ret_void);
        }
    });
}
