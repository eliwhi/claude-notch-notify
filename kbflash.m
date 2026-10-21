// kbflash: flash the MacBook keyboard backlight and the caps lock LED, then restore them.
//
// Backlight: Apple's private CoreBrightness framework (KeyboardBrightnessClient),
// which is what Control Centre uses on Apple Silicon MacBooks.
// Caps lock LED: IOKit HID, by writing the keyboard's LED output element directly.
// This lights the LED without actually turning caps lock on.
//
// Build:
//   clang -fobjc-arc -framework Foundation -framework IOKit \
//     -F /System/Library/PrivateFrameworks -framework CoreBrightness \
//     kbflash.m -o kbflash
//
// Usage:
//   ./kbflash [backlight_flashes=2] [caps_flashes=5] [on_ms=400] [off_ms=250]
//   KBFLASH_DEBUG=1 ./kbflash   (prints what it's doing)

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/hid/IOHIDUsageTables.h>
#import <mach/mach_time.h>

@interface KeyboardBrightnessClient : NSObject
- (NSArray *)copyKeyboardBacklightIDs;
- (float)brightnessForKeyboard:(unsigned long long)keyboardID;
- (BOOL)setBrightness:(float)level fadeSpeed:(int)fadeSpeed commit:(BOOL)commit forKeyboard:(unsigned long long)keyboardID;
- (BOOL)isAutoBrightnessEnabledForKeyboard:(unsigned long long)keyboardID;
- (BOOL)enableAutoBrightness:(BOOL)enable forKeyboard:(unsigned long long)keyboardID;
@end

static BOOL verbose;

// A caps lock LED element on one keyboard device, plus its state before we started.
@interface CapsLED : NSObject
@property (nonatomic) IOHIDDeviceRef device;
@property (nonatomic) IOHIDElementRef element;
@property (nonatomic) CFIndex original;
@end
@implementation CapsLED
@end

static void setCapsLEDs(NSArray<CapsLED *> *leds, CFIndex value) {
    for (CapsLED *led in leds) {
        IOHIDValueRef v = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, led.element, mach_absolute_time(), value);
        IOReturn r = IOHIDDeviceSetValue(led.device, led.element, v);
        CFRelease(v);
        if (verbose) fprintf(stderr, "kbflash: caps LED -> %ld (0x%x)\n", (long)value, r);
    }
}

static NSArray<CapsLED *> *findCapsLEDs(IOHIDManagerRef manager) {
    NSMutableArray<CapsLED *> *leds = [NSMutableArray array];

    IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef)@{
        @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
        @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_Keyboard),
    });
    IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);

    NSSet *devices = (__bridge_transfer NSSet *)IOHIDManagerCopyDevices(manager);
    NSDictionary *match = @{ @kIOHIDElementUsagePageKey: @(kHIDPage_LEDs) };
    for (id d in devices) {
        IOHIDDeviceRef device = (__bridge IOHIDDeviceRef)d;
        NSArray *elements = (__bridge_transfer NSArray *)IOHIDDeviceCopyMatchingElements(
            device, (__bridge CFDictionaryRef)match, kIOHIDOptionsTypeNone);
        for (id e in elements) {
            if (IOHIDElementGetUsage((__bridge IOHIDElementRef)e) != kHIDUsage_LED_CapsLock) continue;
            CapsLED *led = [CapsLED new];
            led.device = device;
            led.element = (__bridge IOHIDElementRef)e;
            IOHIDValueRef current = NULL;
            led.original = IOHIDDeviceGetValue(device, led.element, &current) == kIOReturnSuccess && current
                ? IOHIDValueGetIntegerValue(current) : 0;
            [leds addObject:led];
        }
    }
    if (verbose) fprintf(stderr, "kbflash: found %lu caps lock LED(s)\n", (unsigned long)leds.count);
    return leds;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        int backlightFlashes = argc > 1 ? atoi(argv[1]) : 2;
        int capsFlashes      = argc > 2 ? atoi(argv[2]) : 5;
        int onMs             = argc > 3 ? atoi(argv[3]) : 400;
        int offMs            = argc > 4 ? atoi(argv[4]) : 250;
        int flashes = MAX(backlightFlashes, capsFlashes);
        verbose = getenv("KBFLASH_DEBUG") != NULL;

        // Keyboard backlight (optional: we still flash the caps LED without it).
        KeyboardBrightnessClient *client = nil;
        unsigned long long kb = 0;
        float original = 0;
        BOOL autoOn = NO;
        Class cls = NSClassFromString(@"KeyboardBrightnessClient");
        if (cls) {
            client = [[cls alloc] init];
            NSArray *ids = [client copyKeyboardBacklightIDs];
            if (ids.count > 0) {
                kb = [ids[0] unsignedLongLongValue];
                original = [client brightnessForKeyboard:kb];
                autoOn = [client isAutoBrightnessEnabledForKeyboard:kb];
            } else {
                client = nil;
            }
        }
        if (!client && verbose) fprintf(stderr, "kbflash: no keyboard backlight found\n");

        IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        NSArray<CapsLED *> *leds = findCapsLEDs(manager);

        if (!client && leds.count == 0) {
            fprintf(stderr, "kbflash: nothing to flash\n");
            return 1;
        }

        // Auto-brightness would fight the flash, so pause it while we blink.
        if (client && autoOn) [client enableAutoBrightness:NO forKeyboard:kb];
        if (verbose && client) fprintf(stderr, "kbflash: keyboard %llu, brightness %.3f, auto %d\n", kb, original, autoOn);

        // fadeSpeed 0 = instant change; commit NO = don't save as the user's preference.
        // Both lights blink in step; whichever has fewer flashes drops out early.
        for (int i = 0; i < flashes; i++) {
            BOOL backlight = client && i < backlightFlashes;
            BOOL caps = i < capsFlashes;
            if (backlight) [client setBrightness:1.0f fadeSpeed:0 commit:NO forKeyboard:kb];
            if (caps) setCapsLEDs(leds, 1);
            usleep(onMs * 1000);
            if (backlight) {
                // After its last flash, go straight back to normal instead of staying dark.
                float level = i == backlightFlashes - 1 ? original : 0.0f;
                [client setBrightness:level fadeSpeed:0 commit:NO forKeyboard:kb];
            }
            if (caps) setCapsLEDs(leds, 0);
            usleep(offMs * 1000);
            if (verbose) fprintf(stderr, "kbflash: flash %d\n", i + 1);
        }

        // Put the caps LED back to match the real caps lock state.
        for (CapsLED *led in leds) setCapsLEDs(@[led], led.original);
        if (client) {
            [client setBrightness:original fadeSpeed:0 commit:YES forKeyboard:kb];
            if (autoOn) [client enableAutoBrightness:YES forKeyboard:kb];
        }

        IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
        CFRelease(manager);
    }
    return 0;
}
