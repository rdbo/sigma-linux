#define KEYS 66
static Key keys_de[KEYS] = {
	{ "^","°′", XK_dead_circumflex, 1},
	{ "1", "!¹", XK_1, 1 },
	{ "2","\"²", XK_2, 1 },
	{ "3","§³", XK_3, 1 },
	{ "4","$¼", XK_4, 1 },
	{ "5","%½", XK_5, 1 },
	{ "6","&¬", XK_6, 1 },
	{ "7","/{", XK_7, 1 },
	{ "8","([", XK_8, 1 },
	{ "9",")]", XK_9, 1 },
	{ "0","=}", XK_0, 1 },
	{ "ß","?\\", XK_ssharp, 1 },
	{ "´","`¸", XK_dead_acute, 1 },
	{ "<-", 0, XK_BackSpace, 2 },
	{ "Entf", 0, XK_Delete, 1},
	{ 0 }, /* New row */
	{ "->|", 0, XK_Tab, 1 },
	{ "q","Q@", XK_q, 1 },
	{ "w","Wł", XK_w, 1 },
	{ "e","E€", XK_e, 1 },
	{ "r","R¶", XK_r, 1 },
	{ "t","Tŧ", XK_t, 1 },
	{ "z","Z←", XK_z, 1 },
	{ "u","U↓", XK_u, 1 },
	{ "i","I→", XK_i, 1 },
	{ "o","Oø", XK_o, 1 },
	{ "p","Pþ", XK_p, 1 },
	{ "ü","Ü¨", 0xfc, 1 },
	{ "+","*~", XK_plus, 1 },
	{ "Enter", 0, XK_Return, 3 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Caps_Lock, 2 },
	{ "a","Aæ", XK_a, 1 },
	{ "s","Sſ", XK_s, 1 },
	{ "d","Dð", XK_d, 1 },
	{ "f","Fđ", XK_f, 1 },
	{ "g","Gŋ", XK_g, 1 },
	{ "h","Hħ", XK_h, 1 },
	{ "j","J̣̣", XK_j, 1 },
	{ "k","Kĸ", XK_k, 1 },
	{ "l","Lł", XK_l, 1 },
	{ "ö","Ö˝", 0xf6, 1 },
	{ "ä","Ä^", 0xe4, 1 },
	{ "#","'’", XK_numbersign, 1 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Shift_L, 2 },
	{ "<",">|", XK_less, 1 },
	{ "y","Y»", XK_y, 1 },
	{ "x","X«", XK_x, 1 },
	{ "c","C¢", XK_c, 1 },
	{ "v","V„", XK_v, 1 },
	{ "b","B“", XK_b, 1 },
	{ "n","N”", XK_n, 1 },
	{ "m","Mµ", XK_m, 1 },
	{ ",",";·", XK_comma, 1 },
	{ ".",":…", XK_period, 1 },
	{ "-","_–", XK_minus, 1 },
	{ 0, 0, XK_Shift_R, 2 },
	{ 0 }, /* New row */
	{ "Ctrl", 0, XK_Control_L, 2 },
	{ "Win",  0, XK_Super_L, 2 },
	{ "Alt", 0, XK_Alt_L, 2 },
	{ "", 0, XK_space, 5 },
	{ "Alt Gr", 0, XK_ISO_Level3_Shift, 2 },
	{ "Menu", 0, XK_Menu, 2 },
	{ "Ctrl", 0, XK_Control_R, 2 },
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
	"de",
};

static Key* available_layers[LAYERS] = {
	keys_de,
};

