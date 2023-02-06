#define KEYS 6
static Key keys_arrows[] = {
	{ 0, 0, XK_Shift_L, 2 },
	{ "←", 0, XK_Left, 1 },
	{ "↓", 0, XK_Down, 1 },
	{ "↑", 0, XK_Up, 1 },
	{ "→", 0, XK_Right, 1},
	{ "Alt", 0, XK_Alt_L, 2 },
};

Buttonmod buttonmods[] = {
	{ XK_Shift_L, Button2 },
	{ XK_Alt_L, Button3 },
};

#define OVERLAYS 1
static Key overlay[OVERLAYS] = {
	{ 0, 0, XK_Cancel },
};

#define LAYERS 1
static char* layer_names[LAYERS] = {
	"arrows",
};

static Key* available_layers[LAYERS] = {
	keys_arrows,
};

