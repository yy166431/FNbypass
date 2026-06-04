#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static BOOL ret_yes(id self, SEL _cmd) { return YES; }
static BOOL ret_no(id self, SEL _cmd) { return NO; }
static void ret_void(id self, SEL _cmd, ...) {}
static id ret_nil(id self, SEL _cmd, ...) { return nil; }

static void kill_all_instance_methods(const char *clsName) {
    Class cls = objc_getClass(clsName);
    if (!cls) return;
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    for (unsigned int i = 0; i < count; i++) {
        char ret[8] = {0};
        method_getReturnType(methods[i], ret, sizeof(ret));
        if (ret[0] == 'v') method_setImplementation(methods[i], (IMP)ret_void);
        else if (ret[0] == 'B' || ret[0] == 'c') method_setImplementation(methods[i], (IMP)ret_no);
        else if (ret[0] == '@') method_setImplementation(methods[i], (IMP)ret_nil);
    }
    free(methods);
    Class meta = object_getClass(cls);
    if (!meta) return;
    methods = class_copyMethodList(meta, &count);
    for (unsigned int i = 0; i < count; i++) {
        char ret[8] = {0};
        method_getReturnType(methods[i], ret, sizeof(ret));
        if (ret[0] == 'v') method_setImplementation(methods[i], (IMP)ret_void);
        else if (ret[0] == 'B' || ret[0] == 'c') method_setImplementation(methods[i], (IMP)ret_no);
        else if (ret[0] == '@') method_setImplementation(methods[i], (IMP)ret_nil);
    }
    free(methods);
}

@interface FNBypass : NSObject
@end

@implementation FNBypass

+ (void)load {
    // PHASE 1: Nuke ALL security/integrity classes entirely
    const char *securityClasses[] = {
        "GRNSecurityGuard",
        "GRNSelfIntegrityGuard",
        "GRNFunctionHashGuard",
        "GRNComprehensiveFridaGuard",
        "GRNDispatchOnceGuard",
        "GRNLicenseGuard",
        "IntegrityCheck",
        "KeySharding",
        "TimeTamperProtection",
        "GRNSSLPinning",
    };
    for (int i = 0; i < sizeof(securityClasses)/sizeof(securityClasses[0]); i++) {
        kill_all_instance_methods(securityClasses[i]);
    }

    // PHASE 2: Hook GRNActivationManager auth methods
    Class mgr = objc_getClass("GRNActivationManager");
    if (!mgr) return;

    const char *yes_sels[] = {
        "hasLocalSession",
        "startupValidationPassed",
        "isActivated",
    };
    for (int i = 0; i < 3; i++) {
        Method m = class_getInstanceMethod(mgr, sel_registerName(yes_sels[i]));
        if (m) method_setImplementation(m, (IMP)ret_yes);
    }

    const char *no_sels[] = {
        "isDebuggerAttached",
    };
    for (int i = 0; i < 1; i++) {
        Method m = class_getInstanceMethod(mgr, sel_registerName(no_sels[i]));
        if (m) method_setImplementation(m, (IMP)ret_no);
    }

    const char *void_sels[] = {
        "armActivationForceExitTimerWithReason:",
        "onActivationForceExitTimerFired:",
        "exitApplication",
        "handleSessionInvalidWithMessage:",
        "setFeatureLocked:reason:",
        "clearLocalSession",
        "ensureActivatedOrPresentWithMessage:",
        "ensureActivatedOrPresent",
        "startHeartbeat",
        "sendHeartbeat",
        "sendHeartbeatInternalAllowRefresh:",
        "tryRefreshToken",
        "presentSecurityAlertAndTerminateWithSummary:",
        "stopHeartbeat",
    };
    for (int i = 0; i < 14; i++) {
        Method m = class_getInstanceMethod(mgr, sel_registerName(void_sels[i]));
        if (m) method_setImplementation(m, (IMP)ret_void);
    }
}

@end
