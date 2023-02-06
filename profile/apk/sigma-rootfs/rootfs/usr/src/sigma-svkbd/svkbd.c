/* See LICENSE file for copyright and license details. */
#include <sys/select.h>
#include <sys/time.h>

#include <ctype.h>
#include <locale.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <X11/keysym.h>
#include <X11/keysymdef.h>
#include <X11/XF86keysym.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>
#include <X11/extensions/XTest.h>
#include <X11/Xft/Xft.h>
#include <X11/Xresource.h>
#ifdef XINERAMA
#include <X11/extensions/Xinerama.h>
#endif

#include "drw.h"
#include "util.h"

/* macros */
#define LENGTH(x)         (sizeof x / sizeof x[0])
#define STRINGTOKEYSYM(X) (XStringToKeySym(X))
#define TEXTW(X)          (drw_fontset_getwidth(drw, (X)))

/* enums */
enum {
	SchemeNorm, SchemeNormABC, SchemeNormABCShift, SchemeNormShift, SchemePress,
	SchemePressShift, SchemeHighlight, SchemeHighlightShift, SchemeOverlay,
	SchemeOverlayShift, SchemeWindow, SchemeLast
};
enum { NetWMWindowType, NetLast };

/* typedefs */
typedef struct {
	char *label;
	char *label2;
	KeySym keysym;
	double width;
	KeySym modifier;
	int x, y, w, h;
	Bool pressed;
	Bool highlighted;
	Bool isoverlay;
} Key;

typedef struct {
	KeySym mod;
	unsigned int button;
} Buttonmod;

/* function declarations */
static void printdbg(const char *fmt, ...);
static void motionnotify(XEvent *e);
static void buttonpress(XEvent *e);
static void buttonrelease(XEvent *e);
static void cleanup(void);
static void configurenotify(XEvent *e);
static void countrows();
static int countkeys(Key *layer);
static void drawkeyboard(void);
static void drawkey(Key *k, Bool map);
static void expose(XEvent *e);
static Key *findkey(int x, int y);
static void leavenotify(XEvent *e);
static void press(Key *k, KeySym buttonmod);
static double get_press_duration();
static void run(void);
static void setup(void);
static void simulate_keypress(KeySym keysym);
static void simulate_keyrelease(KeySym keysym);
static void showoverlay(int idx);
static void hideoverlay();
static void cyclelayer();
static void setlayer();
static void togglelayer();
static void unpress(Key *k, KeySym buttonmod);
static void updatekeys();
static void printkey(Key *k, KeySym mod);

/* variables */
static int screen;
static void (*handler[LASTEvent]) (XEvent *) = {
	[ButtonPress] = buttonpress,
	[ButtonRelease] = buttonrelease,
	[ConfigureNotify] = configurenotify,
	[Expose] = expose,
	[LeaveNotify] = leavenotify,
	[MotionNotify] = motionnotify
};
static Atom netatom[NetLast];
static Display *dpy;
static Drw *drw;
static Window root, win;
static Clr* scheme[SchemeLast];
static Bool running = True, isdock = False;
static struct timeval pressbegin;
static int currentlayer = 0;
static int enableoverlays = 1;
static int currentoverlay = -1; /* -1 = no overlay */
static int pressonrelease = 1;
static KeySym overlaykeysym = 0; /* keysym for which the overlay is presented */
static int releaseprotect = 0; /* set to 1 after overlay is shown, protecting against immediate release */
static int tmp_keycode = 1;
static int rows = 0, ww = 0, wh = 0, wx = 0, wy = 0;
static int simulateoutput = 1; /* simulate key presses for X */
static int printoutput = 0; /* print key pressed to stdout */
static char *name = "svkbd";
static int debug = 0;
static int numlayers = 0;
static int numkeys = 0;

static char *colors[11][2]; /* 11 schemes, 2 colors each */
static char *fonts[] = { 0 };

static KeySym ispressingkeysym;

Bool ispressing = False;
Bool sigtermd = False;

/* configuration, allows nested code to access above variables */
#include "config.h"
#ifndef LAYOUT
#error "make sure to define LAYOUT"
#endif
#include LAYOUT

static Key keys[KEYS];
static Key *layers[LAYERS];

void
motionnotify(XEvent *e)
{
	XPointerMovedEvent *ev = &e->xmotion;
	int i;
	int lostfocus = -1;
	int gainedfocus = -1;

	for (i = 0; i < numkeys; i++) {
		if (keys[i].keysym && ev->x > keys[i].x
				&& ev->x < keys[i].x + keys[i].w
				&& ev->y > keys[i].y
				&& ev->y < keys[i].y + keys[i].h) {
			if (keys[i].highlighted != True) {
				if (ispressing) {
					gainedfocus = i;
				} else {
					keys[i].highlighted = True;
				}
				drawkey(&keys[i], True);
			}
			continue;
		} else if (keys[i].highlighted == True) {
			keys[i].highlighted = False;
			drawkey(&keys[i], True);
		}
	}

	for (i = 0; i < numkeys; i++) {
		if (!IsModifierKey(keys[i].keysym) && keys[i].pressed == True &&
		    lostfocus != gainedfocus) {
			printdbg("Pressed key lost focus: %ld\n", keys[i].keysym);
			lostfocus = i;
			ispressingkeysym = 0;
			keys[i].pressed = 0;
			drawkey(&keys[i], True);
		}
	}

	if ((lostfocus != -1) && (gainedfocus != -1) && (lostfocus != gainedfocus)) {
		printdbg("Clicking new key that gained focus\n");
		press(&keys[gainedfocus], 0);
		keys[gainedfocus].pressed = True;
		keys[gainedfocus].highlighted = True;
	}
}

void
buttonpress(XEvent *e)
{
	XButtonPressedEvent *ev = &e->xbutton;
	Key *k;
	KeySym mod = 0;
	int i;

	ispressing = True;

	if (!(k = findkey(ev->x, ev->y)))
		return;

	for (i = 0; i < LENGTH(buttonmods); i++) {
		if (ev->button == buttonmods[i].button) {
			mod = buttonmods[i].mod;
			break;
		}
	}

	if (k->modifier) {
		if (mod == k->modifier)
			mod = 0;
		else
			mod = k->modifier;
	}
	press(k, mod);
}

void
buttonrelease(XEvent *e)
{
	XButtonPressedEvent *ev = &e->xbutton;
	Key *k;
	KeySym mod = 0;
	int i;

	ispressing = False;

	for (i = 0; i < LENGTH(buttonmods); i++) {
		if (ev->button == buttonmods[i].button) {
			mod = buttonmods[i].mod;
			break;
		}
	}

	if (ev->x < 0 || ev->y < 0) {
		unpress(NULL, mod);
	} else if ((k = findkey(ev->x, ev->y))) {
		if (k->modifier == mod)
			unpress(k, 0);
		else if (k->modifier)
			unpress(k, k->modifier);
		else
			unpress(k, mod);
	}
}

void
cleanup(void)
{
	int i;

	for (i = 0; i < SchemeLast; i++)
		free(scheme[i]);
	drw_sync(drw);
	drw_free(drw);
	XSync(dpy, False);
	XDestroyWindow(dpy, win);
	XSync(dpy, False);
	XSetInputFocus(dpy, PointerRoot, RevertToPointerRoot, CurrentTime);
}

void
configurenotify(XEvent *e)
{
	XConfigureEvent *ev = &e->xconfigure;

	if (ev->window == win && (ev->width != ww || ev->height != wh)) {
		ww = ev->width;
		wh = ev->height;
		drw_resize(drw, ww, wh);
		updatekeys();
	}
}

void
countrows(void)
{
	int i;

	for (i = 0, rows = 1; i < numkeys; i++) {
		if (keys[i].keysym == 0) {
			rows++;
			if ((i > 0) && (keys[i-1].keysym == 0)) {
				rows--;
				break;
			}
		}
	}
}

int
countkeys(Key *layer)
{
	int i, nkeys = 0;

	for (i = 0; i < KEYS; i++) {
		if (i > 0 && layer[i].keysym == 0 && layer[i - 1].keysym == 0) {
			nkeys--;
			break;
		}
		nkeys++;
	}

	return nkeys;
}

void
drawkeyboard(void)
{
	int i;

	drw_setscheme(drw, scheme[SchemeWindow]);
	drw_rect(drw, 0, 0, ww, wh, 1, 1);
	for (i = 0; i < numkeys; i++) {
		if (keys[i].keysym != 0)
			drawkey(&keys[i], False);
	}
	drw_map(drw, win, 0, 0, ww, wh);
}

void
drawkey(Key *k, Bool map)
{
	int x, y, w, h;
	const char *l;

	int use_scheme = SchemeNorm;

	if (k->pressed)
		use_scheme = SchemePress;
	else if (k->highlighted)
		use_scheme = SchemeHighlight;
	else if (k->isoverlay)
		use_scheme = SchemeOverlay;
	else if ((k->keysym == XK_Return) ||
			((k->keysym >= XK_a) && (k->keysym <= XK_z)) ||
			((k->keysym >= XK_Cyrillic_io) && (k->keysym <= XK_Cyrillic_hardsign)))
		use_scheme = SchemeNormABC;
	else
		use_scheme = SchemeNorm;

	drw_setscheme(drw, scheme[use_scheme]);
	drw_rect(drw, k->x, k->y, k->w, k->h, 1, 1);

	if (k->keysym == XK_KP_Insert) {
		if (enableoverlays) {
			l = "≅";
		} else {
			l = "≇";
		}
	} else if (k->label) {
		l = k->label;
	} else {
		l = XKeysymToString(k->keysym);
	}
	h = fontsize * 2;
	y = k->y + (k->h / 2) - (h / 2);
	w = TEXTW(l);
	x = k->x + (k->w / 2) - (w / 2);
	drw_text(drw, x, y, w, h, 0, l, 0);
	if (k->label2) {
		if (use_scheme == SchemeNorm)
			use_scheme = SchemeNormShift;
		else if (use_scheme == SchemeNormABC)
			use_scheme = SchemeNormABCShift;
		else if (use_scheme == SchemePress)
			use_scheme = SchemePressShift;
		else if (use_scheme == SchemeHighlight)
			use_scheme = SchemeHighlightShift;
		else if (use_scheme == SchemeOverlay)
			use_scheme = SchemeOverlayShift;
		drw_setscheme(drw, scheme[use_scheme]);
		x += w;
		y -= 15;
		l = k->label2;
		w = TEXTW(l);
		drw_text(drw, x, y, w, h, 0, l, 0);
	}
	if (map)
		drw_map(drw, win, k->x, k->y, k->w, k->h);
}

void
expose(XEvent *e)
{
	XExposeEvent *ev = &e->xexpose;

	if (ev->count == 0 && (ev->window == win))
		drawkeyboard();
}

Key *
findkey(int x, int y) {
	int i;

	for (i = 0; i < numkeys; i++) {
		if (keys[i].keysym && x > keys[i].x &&
				x < keys[i].x + keys[i].w &&
				y > keys[i].y && y < keys[i].y + keys[i].h) {
			return &keys[i];
		}
	}
	return NULL;
}

int
hasoverlay(KeySym keysym)
{
	int begin, i;

	begin = 0;
	for (i = 0; i < OVERLAYS; i++) {
		if (overlay[i].keysym == XK_Cancel) {
			begin = i + 1;
		} else if (overlay[i].keysym == keysym) {
			return begin + 1;
		}
	}
	return -1;
}

void
leavenotify(XEvent *e)
{
	if (currentoverlay != -1)
		hideoverlay();
	ispressingkeysym = 0;
	unpress(NULL, 0);
}

void
record_press_begin(KeySym ks)
{
	/* record the begin of the press, don't simulate the actual keypress yet */
	gettimeofday(&pressbegin, NULL);
	ispressingkeysym = ks;
}

void
press(Key *k, KeySym buttonmod)
{
	int i;
	int overlayidx = -1;

	k->pressed = !k->pressed;

	printdbg("Begin click: %ld\n", k->keysym);
	pressbegin.tv_sec = 0;
	pressbegin.tv_usec = 0;
	ispressingkeysym = 0;

	if (!IsModifierKey(k->keysym)) {
		if (enableoverlays && currentoverlay == -1)
			overlayidx = hasoverlay(k->keysym);
		if ((pressonrelease) || (enableoverlays && overlayidx != -1)) {
			/*record the begin of the press, don't simulate the actual keypress yet */
			record_press_begin(k->keysym);
		} else {
			printdbg("Simulating press: %ld (mod %ld)\n", k->keysym, buttonmod);
			for (i = 0; i < numkeys; i++) {
				if (keys[i].pressed && IsModifierKey(keys[i].keysym)) {
					simulate_keypress(keys[i].keysym);
				}
			}
			if (buttonmod)
				simulate_keypress(buttonmod);
			simulate_keypress(k->keysym);
			if (printoutput)
				printkey(k, buttonmod);

			for (i = 0; i < numkeys; i++) {
				if (keys[i].pressed && IsModifierKey(keys[i].keysym)) {
					simulate_keyrelease(keys[i].keysym);
				}
			}
		}
	}
	drawkey(k, True);
}

int
tmp_remap(KeySym keysym)
{
	XChangeKeyboardMapping(dpy, tmp_keycode, 1, &keysym, 1);
	XSync(dpy, False);

	return tmp_keycode;
}

void
printkey(Key *k, KeySym mod)
{
	int i, shift;

	shift = (mod == XK_Shift_L) || (mod == XK_Shift_R) || (mod == XK_Shift_Lock);
	if (!shift) {
		for (i = 0; i < numkeys; i++) {
			if ((keys[i].pressed) && ((keys[i].keysym == XK_Shift_L) ||
			    (keys[i].keysym == XK_Shift_R) || (keys[i].keysym == XK_Shift_Lock))) {
				shift = True;
				break;
			}
		}
	}
	printdbg("Printing key %ld (shift=%d)\n", k->keysym, shift);
	if (k->keysym == XK_Cancel)
		return;

	KeySym *keysym = &(k->keysym);
	XIM xim = XOpenIM(dpy, 0, 0, 0);
	XIC xic = XCreateIC(xim, XNInputStyle, XIMPreeditNothing | XIMStatusNothing, NULL);

	XKeyPressedEvent event;
	event.type = KeyPress;
	event.display = dpy;
	event.state = shift ? ShiftMask : 0;
	event.keycode = XKeysymToKeycode(dpy, *keysym);
	if (event.keycode == 0)
		event.keycode = tmp_remap(*keysym);

	char buffer[32];
	KeySym ignore;
	Status return_status;
	int l = Xutf8LookupString(xic, &event, buffer, sizeof(buffer), &ignore, &return_status);
	buffer[l] = '\0';
	printdbg("Print buffer: [%s] (length=%d)\n", &buffer, l);
	printf("%s", buffer);

	XDestroyIC(xic);
	XCloseIM(xim);
}

void
simulate_keypress(KeySym keysym)
{
	KeyCode code;

	if (!simulateoutput)
		return;

	code = XKeysymToKeycode(dpy, keysym);
	if (code == 0)
		code = tmp_remap(keysym);
	XTestFakeKeyEvent(dpy, code, True, 0);
}

void
simulate_keyrelease(KeySym keysym)
{
	KeyCode code;

	if (!simulateoutput)
		return;

	code = XKeysymToKeycode(dpy, keysym);
	if (code == 0)
		code = tmp_remap(keysym);
	XTestFakeKeyEvent(dpy, code, False, 0);
}

double
get_press_duration(void)
{
	struct timeval now;

	gettimeofday(&now, NULL);

	return (double) ((now.tv_sec * 1000000L + now.tv_usec) -
		   (pressbegin.tv_sec * 1000000L + pressbegin.tv_usec)) /
		   (double) 1000000L;
}

void
unpress(Key *k, KeySym buttonmod)
{
	int i;
	Bool neutralizebuttonmod = False;

	if (k) {
		switch(k->keysym) {
		case XK_Cancel:
			cyclelayer();
			break;
		case XK_script_switch:
			togglelayer();
			break;
		case XK_KP_Insert:
			enableoverlays = !enableoverlays;
			break;
		case XK_Break:
			running = False;
			break;
		default:
			break;
		}
	}

	if ((pressbegin.tv_sec || pressbegin.tv_usec) && (enableoverlays || pressonrelease) && k && k->keysym == ispressingkeysym) {
		printdbg("Delayed simulation of press after release: %ld\n", k->keysym);
		/* simulate the press event, as we postponed it earlier in press() */
		for (i = 0; i < numkeys; i++) {
			if (keys[i].pressed && IsModifierKey(keys[i].keysym)) {
				if (keys[i].keysym == buttonmod)
					neutralizebuttonmod = True;
				else
					simulate_keypress(keys[i].keysym);
			}
		}
		if (buttonmod && !neutralizebuttonmod) {
			simulate_keypress(buttonmod);
		}
		simulate_keypress(k->keysym);
		pressbegin.tv_sec = 0;
		pressbegin.tv_usec = 0;
	}

	if (k)
		printdbg("Simulation of release: %ld\n", k->keysym);
	else
		printdbg("Simulation of release (all keys)\n");

	for (i = 0; i < numkeys; i++) {
		if (keys[i].pressed && !IsModifierKey(keys[i].keysym)) {
			simulate_keyrelease(keys[i].keysym);
			if (printoutput)
				printkey(&keys[i], buttonmod);
			keys[i].pressed = 0;
			drawkey(&keys[i], True);
		}
	}

	if (buttonmod && !neutralizebuttonmod) {
		simulate_keyrelease(buttonmod);
	}

	if (k == NULL || !IsModifierKey(k->keysym)) {
		for (i = 0; i < numkeys; i++) {
			if (keys[i].pressed && IsModifierKey(keys[i].keysym)) {
				if (!(keys[i].keysym == buttonmod && neutralizebuttonmod))
					simulate_keyrelease(keys[i].keysym);
				keys[i].pressed = 0;
				drawkey(&keys[i], True);
			}
		}
	}

	if (enableoverlays && currentoverlay != -1 &&
	    (k == NULL || !IsModifierKey(k->keysym))) {
		if (releaseprotect) {
			releaseprotect = 0;
		} else {
			hideoverlay();
		}
	}
}

void
run(void)
{
	XEvent ev;
	int xfd;
	fd_set fds;
	struct timeval tv;
	double duration;
	int overlayidx;
	int i, r;

	xfd = ConnectionNumber(dpy);
	tv.tv_sec = 0;
	tv.tv_usec = scan_rate;

	XFlush(dpy);

	while (running) {
		usleep(100000L); /* 100ms */
		FD_ZERO(&fds);
		FD_SET(xfd, &fds);
		r = select(xfd + 1, &fds, NULL, NULL, &tv);
		if (r) {
			while (XPending(dpy)) {
				XNextEvent(dpy, &ev);
				if (handler[ev.type]) {
					(handler[ev.type])(&ev); /* call handler */
				}
			}
		} else {
			/* time-out expired without anything interesting happening, check for long-presses */
			if (ispressing && ispressingkeysym) {
				duration = get_press_duration();
				if (debug >= 2)
					printdbg("%f\n", duration);
				overlayidx = hasoverlay(ispressingkeysym);
				duration = get_press_duration();
				if (overlayidx != -1 && duration >= overlay_delay) {
					printdbg("press duration %f, activating overlay\n", duration);
					showoverlay(overlayidx);
					pressbegin.tv_sec = 0;
					pressbegin.tv_usec = 0;
					ispressingkeysym = 0;
				} else if ((overlayidx == -1) && (duration >= repeat_delay)) {
					printdbg("press duration %f, activating repeat\n", duration);
					simulate_keyrelease(ispressingkeysym);
					simulate_keypress(ispressingkeysym);
					XSync(dpy, False);
				}
			}
		}
		if (r == -1 || sigtermd) {
			/* an error occurred or we received a signal */
			/* E.g. Generally in scripts we want to call SIGTERM on svkbd in which case
					if the user is holding for example the enter key (to execute
					the kill or script that does the kill), that causes an issue
					since then X doesn't know the keyup is never coming.. (since
					process will be dead before finger lifts - in that case we
					just trigger out fake up presses for all keys */
			printdbg("signal received, releasing all keys");
			for (i = 0; i < numkeys; i++) {
				XTestFakeKeyEvent(dpy, XKeysymToKeycode(dpy, keys[i].keysym), False, 0);
			}
			running = False;
		}
	}
}

void
readxresources(void)
{
	XrmDatabase xdb;
	XrmValue xval;
	char *type, *xrm;

	XrmInitialize();

	if ((xrm = XResourceManagerString(drw->dpy))) {
		xdb = XrmGetStringDatabase(xrm);

		if (XrmGetResource(xdb, "svkbd.font", "*", &type, &xval) && !fonts[0])
			fonts[0] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.background", "*", &type, &xval) && !colors[SchemeNorm][ColBg])
			colors[SchemeNorm][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.foreground", "*", &type, &xval) && !colors[SchemeNorm][ColFg])
			colors[SchemeNorm][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.shiftforeground", "*", &type, &xval) && !colors[SchemeNormShift][ColFg])
			colors[SchemeNormShift][ColFg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.shiftbackground", "*", &type, &xval) && !colors[SchemeNormShift][ColBg])
			colors[SchemeNormShift][ColBg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.ABCforeground", "*", &type, &xval) && !colors[SchemeNormABC][ColFg])
			colors[SchemeNormABC][ColFg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.ABCbackground", "*", &type, &xval) && !colors[SchemeNormABC][ColBg])
			colors[SchemeNormABC][ColBg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.ABCshiftforeground", "*", &type, &xval) && !colors[SchemeNormABCShift][ColFg])
			colors[SchemeNormABCShift][ColFg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.ABCshiftbackground", "*", &type, &xval) && !colors[SchemeNormABCShift][ColBg])
			colors[SchemeNormABCShift][ColBg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.pressbackground", "*", &type, &xval) && !colors[SchemePress][ColBg])
			colors[SchemePress][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.pressforeground", "*", &type, &xval) && !colors[SchemePress][ColFg])
			colors[SchemePress][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.pressshiftbackground", "*", &type, &xval) && !colors[SchemePressShift][ColBg])
			colors[SchemePressShift][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.pressshiftforeground", "*", &type, &xval) && !colors[SchemePressShift][ColFg])
			colors[SchemePressShift][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.highlightbackground", "*", &type, &xval) && !colors[SchemeHighlight][ColBg])
			colors[SchemeHighlight][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.highlightforeground", "*", &type, &xval) && !colors[SchemeHighlight][ColFg])
			colors[SchemeHighlight][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.highlightshiftbackground", "*", &type, &xval) && !colors[SchemeHighlightShift][ColBg])
			colors[SchemeHighlightShift][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.highlightshiftforeground", "*", &type, &xval) && !colors[SchemeHighlightShift][ColFg])
			colors[SchemeHighlightShift][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.overlaybackground", "*", &type, &xval) && !colors[SchemeOverlay][ColBg])
			colors[SchemeOverlay][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.overlayforeground", "*", &type, &xval) && !colors[SchemeOverlay][ColFg])
			colors[SchemeOverlay][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.overlayshiftbackground", "*", &type, &xval) && !colors[SchemeOverlayShift][ColBg])
			colors[SchemeOverlayShift][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.overlayshiftforeground", "*", &type, &xval) && !colors[SchemeOverlayShift][ColFg])
			colors[SchemeOverlayShift][ColFg] = estrdup(xval.addr);

		if (XrmGetResource(xdb, "svkbd.windowbackground", "*", &type, &xval) && !colors[SchemeWindow][ColBg])
			colors[SchemeWindow][ColBg] = estrdup(xval.addr);
		if (XrmGetResource(xdb, "svkbd.windowforeground", "*", &type, &xval) && !colors[SchemeWindow][ColFg])
			colors[SchemeWindow][ColFg] = estrdup(xval.addr);

		XrmDestroyDatabase(xdb);
	}
}

void
setup(void)
{
	XSetWindowAttributes wa;
	XTextProperty str;
	XSizeHints *sizeh = NULL;
	XClassHint *ch;
	XWMHints *wmh;
	Atom atype = -1;
	int i, j, sh, sw;

#ifdef XINERAMA
	XineramaScreenInfo *info = NULL;
#endif

	/* init screen */
	screen = DefaultScreen(dpy);
	root = RootWindow(dpy, screen);
#ifdef XINERAMA
	if (XineramaIsActive(dpy)) {
		info = XineramaQueryScreens(dpy, &i);
		sw = info[0].width;
		sh = info[0].height;
		XFree(info);
	} else
#endif
	{
		sw = DisplayWidth(dpy, screen);
		sh = DisplayHeight(dpy, screen);
	}
	drw = drw_create(dpy, screen, root, sw, sh);

	readxresources();

	/* Apply defaults to font and colors*/
	if (!fonts[0])
		fonts[0] = estrdup(defaultfonts[0]);
	for (i = 0; i < SchemeLast; ++i) {
		for (j = 0; j < 2; ++j) {
			if (!colors[i][j])
				colors[i][j] = estrdup(defaultcolors[i][j]);
		}
	}

	if (!drw_fontset_create(drw, (const char **) fonts, LENGTH(fonts)))
		die("no fonts could be loaded");
	free(fonts[0]);

	drw_setscheme(drw, scheme[SchemeNorm]);

	/* find an unused keycode to use as a temporary keycode (derived from source:
	   https://stackoverflow.com/questions/44313966/c-xtest-emitting-key-presses-for-every-unicode-character) */
	KeySym *keysyms;
	int keysyms_per_keycode = 0;
	int keycode_low, keycode_high;
	Bool key_is_empty;
	int symindex;

	XDisplayKeycodes(dpy, &keycode_low, &keycode_high);
	keysyms = XGetKeyboardMapping(dpy, keycode_low, keycode_high - keycode_low, &keysyms_per_keycode);
	for (i = keycode_low; i <= keycode_high; i++) {
		key_is_empty = True;
		for (j = 0; j < keysyms_per_keycode; j++) {
			symindex = (i - keycode_low) * keysyms_per_keycode + j;
			if (keysyms[symindex] != 0) {
				key_is_empty = False;
			} else {
				break;
			}
		}
		if (key_is_empty) {
			tmp_keycode = i;
			break;
		}
	}

	/* init appearance */
	for (j = 0; j < SchemeLast; j++)
		scheme[j] = drw_scm_create(drw, (const char **) colors[j], 2);

	for (j = 0; j < SchemeLast; ++j) {
		free(colors[j][ColFg]);
		free(colors[j][ColBg]);
	}

	/* init atoms */
	if (isdock) {
		netatom[NetWMWindowType] = XInternAtom(dpy,
				"_NET_WM_WINDOW_TYPE", False);
		atype = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DOCK", False);
	}

	/* init appearance */
	countrows();
	if (!ww)
		ww = sw;
	if (!wh)
		wh = sh * rows / heightfactor;

	if (!wx)
		wx = 0;
	if (wx < 0)
		wx = sw + wx - ww;
	if (!wy)
		wy = sh - wh;
	if (wy < 0)
		wy = sh + wy - wh;

	for (i = 0; i < numkeys; i++)
		keys[i].pressed = 0;

	wa.override_redirect = !wmborder;
	wa.border_pixel = scheme[SchemeNorm][ColFg].pixel;
	wa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
	win = XCreateWindow(dpy, root, wx, wy, ww, wh, 0,
			CopyFromParent, CopyFromParent, CopyFromParent,
			CWOverrideRedirect | CWBorderPixel |
			CWBackingPixel, &wa);
	XSelectInput(dpy, win, StructureNotifyMask|ButtonReleaseMask|
			ButtonPressMask|ExposureMask|LeaveWindowMask|
			PointerMotionMask);

	wmh = XAllocWMHints();
	wmh->input = False;
	wmh->flags = InputHint;
	if (!isdock) {
		sizeh = XAllocSizeHints();
		sizeh->flags = PMaxSize | PMinSize;
		sizeh->min_width = sizeh->max_width = ww;
		sizeh->min_height = sizeh->max_height = wh;
	}
	XStringListToTextProperty(&name, 1, &str);
	ch = XAllocClassHint();
	ch->res_class = name;
	ch->res_name = name;

	XSetWMProperties(dpy, win, &str, &str, NULL, 0, sizeh, wmh, ch);

	XFree(keysyms);
	XFree(ch);
	XFree(wmh);
	XFree(str.value);
	if (sizeh != NULL)
		XFree(sizeh);

	if (isdock) {
		XChangeProperty(dpy, win, netatom[NetWMWindowType], XA_ATOM,
				32, PropModeReplace,
				(unsigned char *)&atype, 1);
	}

	XMapRaised(dpy, win);
	drw_resize(drw, ww, wh);
	updatekeys();
	drawkeyboard();
}

void
updatekeys(void)
{
	int i, j;
	double base;
	int x, y = 0, h, r = rows;

	h = (wh - 1) / rows;
	for (i = 0; i < numkeys; i++, r--) {
		for (j = i, base = 0; j < numkeys && keys[j].keysym != 0; j++)
			base += keys[j].width;
		for (x = 0; i < numkeys && keys[i].keysym != 0; i++) {
			keys[i].x = x + xspacing;
			keys[i].y = y + yspacing;
			keys[i].w = keys[i].width * ww / base;
			keys[i].h = r == 1 ? wh - y - 1 : h;
			x += keys[i].w;
			keys[i].w = keys[i].w - (xspacing * 2);
			keys[i].h = keys[i].h - (yspacing * 2);
		}
		if (base != 0)
			keys[i - 1].w = ww - 1 - keys[i - 1].x;
		y += h;
	}
}

void
usage(char *argv0)
{
	fprintf(stderr, "usage: %s [-hdnovDOR] [-g geometry] [-fn font] [-l layers] [-s initial_layer]\n", argv0);
	fprintf(stderr, "Options:\n");
	fprintf(stderr, "  -d         - Set Dock Window Type\n");
	fprintf(stderr, "  -D         - Enable debug\n");
	fprintf(stderr, "  -O         - Disable overlays\n");
	fprintf(stderr, "  -R         - Disable press-on-release\n");
	fprintf(stderr, "  -n         - Do not simulate key presses for X\n");
	fprintf(stderr, "  -o         - Print to standard output\n");
	fprintf(stderr, "  -l         - Comma separated list of layers to enable\n");
	fprintf(stderr, "  -s         - Layer to select on program start\n");
	fprintf(stderr, "  -H [int]   - Height fraction, one key row takes 1/x of the screen height\n");
	fprintf(stderr, "  -fn [font] - Set font (Xft, e.g: DejaVu Sans:bold:size=20)\n");
	fprintf(stderr, "  -g         - Set the window position or size using the X geometry format\n");
	exit(1);
}

void
setlayer(void)
{
	numkeys = countkeys(layers[currentlayer]);
	memcpy(&keys, layers[currentlayer], sizeof(Key) * numkeys);
	countrows();
}

void
cyclelayer(void)
{
	currentlayer++;
	if (currentlayer >= numlayers)
		currentlayer = 0;
	printdbg("Cycling to layer %d\n", currentlayer);
	setlayer();
	updatekeys();
	drawkeyboard();
}

void
togglelayer(void)
{
	if (currentlayer > 0) {
		currentlayer = 0;
	} else if (numlayers > 1) {
		currentlayer = 1;
	}
	printdbg("Toggling layer %d\n", currentlayer);
	setlayer();
	updatekeys();
	drawkeyboard();
}

void
showoverlay(int idx)
{
	int i, j;

	printdbg("Showing overlay %d\n", idx);

	/* unpress existing key (visually only) */
	for (i = 0; i < numkeys; i++) {
		if (keys[i].pressed && !IsModifierKey(keys[i].keysym)) {
			keys[i].pressed = 0;
			drawkey(&keys[i], True);
			break;
		}
	}

	for (i = idx, j = 0; i < OVERLAYS; i++, j++) {
		if (overlay[i].keysym == XK_Cancel) {
			break;
		}
		/* certain modifier keys and basic keys are excluded from being overlayed: */
		while (keys[j].keysym == 0 || keys[j].keysym == XK_Shift_L ||
				keys[j].keysym == XK_Shift_R || keys[j].keysym == XK_Control_L ||
				keys[j].keysym == XK_Control_R || keys[j].keysym == XK_Alt_L ||
				keys[j].keysym == XK_Alt_R || keys[j].keysym == XK_BackSpace ||
				keys[j].keysym == XK_Return || keys[j].keysym == XK_space ||
				keys[j].keysym == XK_Cancel)
			j++;
		if (overlay[i].width > 1)
			j += overlay[i].width - 1;
		if (j >= numkeys)
			break;
		keys[j].label = overlay[i].label;
		keys[j].label2 = overlay[i].label2;
		keys[j].keysym = overlay[i].keysym;
		keys[j].modifier = overlay[i].modifier;
		keys[j].isoverlay = True;
	}
	currentoverlay = idx;
	overlaykeysym = ispressingkeysym;
	releaseprotect = 1;
	updatekeys();
	drawkeyboard();
	XSync(dpy, False);
}

void
hideoverlay(void)
{
	printdbg("Hiding overlay, overlay was #%d\n", currentoverlay);
	currentoverlay = -1;
	overlaykeysym = 0;
	currentlayer--;
	cyclelayer();
}

void
sigterm(int signo)
{
	running = False;
	sigtermd = True;
	printdbg("SIGTERM received\n");
}

void
init_layers(char *layer_names_list, const char *initial_layer_name)
{
	char *s;
	int j, found;

	if (layer_names_list == NULL) {
		numlayers = LAYERS;
		memcpy(&layers, &available_layers, sizeof(available_layers));
		if (initial_layer_name != NULL) {
			for (j = 0; j < LAYERS; j++) {
				if (strcmp(layer_names[j], initial_layer_name) == 0) {
					currentlayer = j;
					break;
				}
			}
		}
	} else {
		s = strtok(layer_names_list, ",");
		while (s != NULL) {
			if (numlayers + 1 > LAYERS)
				die("too many layers specified");
			found = 0;
			for (j = 0; j < LAYERS; j++) {
				if (strcmp(layer_names[j], s) == 0) {
					fprintf(stderr, "Adding layer %s\n", s);
					layers[numlayers] = available_layers[j];
					if (initial_layer_name != NULL && strcmp(layer_names[j], initial_layer_name) == 0) {
						currentlayer = numlayers;
					}
					found = 1;
					break;
				}
			}
			if (!found) {
				fprintf(stderr, "Undefined layer: %s\n", s);
				exit(3);
			}
			numlayers++;
			s = strtok(NULL,",");
		}
	}
	setlayer();
}

void
printdbg(const char *fmt, ...)
{
	if (!debug)
		return;

	va_list ap;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	fflush(stderr);
}

int
main(int argc, char *argv[])
{
	char *initial_layer_name = NULL;
	char *layer_names_list = NULL;
	char *tmp;
	int i, xr, yr, bitm;
	unsigned int wr, hr;

	signal(SIGTERM, sigterm);

	if (OVERLAYS <= 1) {
		enableoverlays = 0;
	} else {
		if ((tmp = getenv("SVKBD_ENABLEOVERLAYS")))
			enableoverlays = atoi(tmp);
	}
	if ((tmp = getenv("SVKBD_LAYERS")))
		layer_names_list = estrdup(tmp);

	if ((tmp = getenv("SVKBD_HEIGHTFACTOR")))
		heightfactor = atoi(tmp);

	if ((tmp = getenv("SVKBD_PRESSONRELEASE"))) /* defaults to 1 */
		pressonrelease = atoi(tmp);

	/* parse command line arguments */
	for (i = 1; argv[i]; i++) {
		if (!strcmp(argv[i], "-v")) {
			die("svkbd-"VERSION);
		} else if (!strcmp(argv[i], "-d")) {
			isdock = True;
		} else if (!strncmp(argv[i], "-g", 2)) {
			if (i >= argc - 1)
				usage(argv[0]);

			bitm = XParseGeometry(argv[++i], &xr, &yr, &wr, &hr);
			if (bitm & XValue)
				wx = xr;
			if (bitm & YValue)
				wy = yr;
			if (bitm & WidthValue)
				ww = (int)wr;
			if (bitm & HeightValue)
				wh = (int)hr;
			if (bitm & XNegative && wx == 0)
				wx = -1;
			if (bitm & YNegative && wy == 0)
				wy = -1;
		} else if (!strcmp(argv[i], "-fn")) { /* font or font set */
			if (i >= argc - 1)
				usage(argv[0]);
			fonts[0] = estrdup(argv[++i]);
		} else if (!strcmp(argv[i], "-D")) {
			debug = 1;
		} else if (!strcmp(argv[i], "-h")) {
			usage(argv[0]);
		} else if (!strcmp(argv[i], "-O")) {
			enableoverlays = 0;
		} else if (!strcmp(argv[i], "-o")) {
			printoutput = 1;
		} else if (!strcmp(argv[i], "-n")) {
			simulateoutput = 0;
		} else if (!strcmp(argv[i], "-R")) {
			pressonrelease = 0;
		} else if (!strcmp(argv[i], "-l")) {
			if (i >= argc - 1)
				usage(argv[0]);
			free(layer_names_list);
			layer_names_list = estrdup(argv[++i]);
		} else if (!strcmp(argv[i], "-s")) {
			if (i >= argc - 1)
				usage(argv[0]);
			initial_layer_name = argv[++i];
		} else if (!strcmp(argv[i], "-H")) {
			if (i >= argc - 1)
				usage(argv[0]);
			heightfactor = atoi(argv[++i]);
		} else {
			fprintf(stderr, "Invalid argument: %s\n", argv[i]);
			usage(argv[0]);
		}
	}

	if (printoutput)
		setbuf(stdout, NULL); /* unbuffered output */

	if (heightfactor <= 0)
		die("height factor must be a positive integer");

	init_layers(layer_names_list, initial_layer_name);

	if (!setlocale(LC_CTYPE, "") || !XSupportsLocale())
		fprintf(stderr, "warning: no locale support");
	if (!(dpy = XOpenDisplay(0)))
		die("cannot open display");
	setup();
	run();
	cleanup();
	XCloseDisplay(dpy);
	free(layer_names_list);

	return 0;
}
