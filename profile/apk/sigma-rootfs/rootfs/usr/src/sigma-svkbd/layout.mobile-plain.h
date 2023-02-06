#define KEYS 44
static Key keys_en[KEYS] = {
	{ 0, 0, XK_q, 1 },
	{ 0, 0, XK_w, 1 },
	{ 0, 0, XK_e, 1 },
	{ 0, 0, XK_r, 1 },
	{ 0, 0, XK_t, 1 },
	{ 0, 0, XK_y, 1 },
	{ 0, 0, XK_u, 1 },
	{ 0, 0, XK_i, 1 },
	{ 0, 0, XK_o, 1 },
	{ 0, 0, XK_p, 1 },

	{ 0 }, /* New row */

	{ 0, 0, XK_a, 1 },
	{ 0, 0, XK_s, 1 },
	{ 0, 0, XK_d, 1 },
	{ 0, 0, XK_f, 1 },
	{ 0, 0, XK_g, 1 },
	{ 0, 0, XK_h, 1 },
	{ 0, 0, XK_j, 1 },
	{ 0, 0, XK_k, 1 },
	{ 0, 0, XK_l, 1 },
	{ ";",":", XK_colon, 1 },
	/*{ "'", XK_apostrophe, 2 },*/

	{ 0 }, /* New row */

	{ 0, 0, XK_z, 1 },
	{ 0, 0, XK_x, 1 },
	{ 0, 0, XK_c, 1 },
	{ 0, 0, XK_v, 1 },
	{ 0, 0, XK_b, 1 },
	{ 0, 0, XK_n, 1 },
	{ 0, 0, XK_m, 1 },
	/*{ "/?", XK_slash, 1 },*/
	{ "Tab", 0, XK_Tab, 1 },
	{ "⇍ Bksp", 0, XK_BackSpace, 2 },

	{ 0 }, /* New row */
	{ "↺", 0, XK_Cancel, 1},
	{ "Shft", 0, XK_Shift_L, 1 },
	/*{ "L", XK_Left, 1 },*/
	{ "↓", 0, XK_Down, 1 },
	{ "↑", 0, XK_Up, 1 },
	/*{ "R", XK_Right, 1 },*/
	{ "", 0, XK_space, 2 },
	{ "Esc", 0, XK_Escape, 1 },
	{ "Ctrl", 0, XK_Control_L, 1 },
	/*{ "Alt", XK_Alt_L, 1 },*/
	{ "↲ Enter", 0, XK_Return, 2 },
};

static Key keys_symbols[KEYS] = {
	{ "1", "!", XK_1, 1 },
	{ "2", "@", XK_2, 1 },
	{ "3", "#", XK_3, 1 },
	{ "4", "$", XK_4, 1 },
	{ "5", "%", XK_5, 1 },
	{ "6", "^", XK_6, 1 },
	{ "7", "&", XK_7, 1 },
	{ "8", "*", XK_8, 1 },
	{ "9", "(", XK_9, 1 },
	{ "0", ")", XK_0, 1 },

	{ 0 }, /* New row */

	{ "'", "\"", XK_apostrophe, 1 },
	{ "`", "~", XK_grave, 1 },
	{ "-", "_", XK_minus, 1 },
	{ "=", "+", XK_plus, 1 },
	{ "[", "{", XK_bracketleft, 1 },
	{ "]", "}", XK_bracketright, 1 },
	{ ",", "<", XK_comma, 1 },
	{ ".", ">", XK_period, 1 },
	{ "/", "?", XK_slash, 1 },
	{ "\\", "|", XK_backslash, 1 },

	{ 0 }, /* New row */

	{ "", 0, XK_Shift_L|XK_bar, 1 },
	{ "⇤", 0, XK_Home, 1 },
	{ "←", 0, XK_Left, 1 },
	{ "→", 0, XK_Right, 1 },
	{ "⇥", 0, XK_End, 1 },
	{ "⇊", 0, XK_Next, 1 },
	{ "⇈", 0, XK_Prior, 1 },
	{ "Tab", 0, XK_Tab, 1 },
	{ "⇍ Bksp", 0, XK_BackSpace, 2 },

	{ 0 }, /* New row */
	{ "↺", 0, XK_Cancel, 1},
	{ "Shft", 0, XK_Shift_L, 1 },
	{ "↓", 0, XK_Down, 1 },
	{ "↑", 0, XK_Up, 1 },
	{ "", 0, XK_space, 2 },
	{ "Esc", 0, XK_Escape, 1 },
	{ "Ctrl", 0, XK_Control_L, 1 },
	{ "↲ Enter", 0, XK_Return, 2 },
};

Buttonmod buttonmods[] = {
	{ XK_Shift_L, Button2 },
	{ XK_Alt_L, Button3 },
};

#define OVERLAYS 1
static Key overlay[OVERLAYS] = {
	{ 0, 0, XK_Cancel },
};

#define LAYERS 2
static char* layer_names[LAYERS] = {
	"en",
	"symbols",
};

static Key* available_layers[LAYERS] = {
	keys_en,
	keys_symbols,
};
