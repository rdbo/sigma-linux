static const Bool wmborder = True;
static int fontsize = 22;
static double overlay_delay = 1.0; //in seconds
static double repeat_delay = 0.75; //in seconds, will not work on keys with overlays
static int scan_rate = 50; //scan rate in microseconds, affects key repetition rate
static int heightfactor = 14; //one row of keys takes up 1/x of the screen height
static int xspacing = 5;
static int yspacing = 5;
static const char *defaultfonts[] = {
	"FiraCode Nerd Font:bold:size=18",
        "DejaVu Sans:size=18"
};
static const char *defaultcolors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#00ffc8", "#101a20" },
	[SchemeNormShift] = { "#00ffc8", "#101a20" },
	[SchemeNormABC] = { "#00ffc8", "#101a20" },
	[SchemeNormABCShift] = { "#00ffc8", "#101a20" },
	[SchemePress] = { "#101a20", "#00ffc8" },
	[SchemePressShift] = { "#101a20", "#00ffc8" },
	[SchemeHighlight] = { "#101a20", "#00ae88" },
	[SchemeHighlightShift] = { "#101a20", "#00ae88" },
	[SchemeOverlay] = { "#ffffff", "#2b3313" },
	[SchemeOverlayShift] = { "#008ac0", "#2b3313" },
	[SchemeWindow] = { "#bbbbbb", "#132a33" },
};

