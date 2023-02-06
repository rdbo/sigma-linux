#define KEYS 63
static Key keys_ru[] = {
	{ "ё","Ё", XK_Cyrillic_io, 1 },
	{ "1","!", XK_1, 1 },
	{ "2","\"", XK_2, 1 },
	{ "3","№", XK_3, 1 },
	{ "4",";", XK_4, 1 },
	{ "5","%", XK_5, 1 },
	{ "6",":", XK_6, 1 },
	{ "7","?", XK_7, 1 },
	{ "8","*", XK_8, 1 },
	{ "9","(", XK_9, 1 },
	{ "0",")", XK_0, 1 },
	{ "-","_", XK_minus, 1 },
	{ "=","+", XK_plus, 1 },
	{ "<-", 0, XK_BackSpace, 2 },
	{ "Del", 0, XK_Delete, 1},
	{ 0 }, /* New row */
	{ "->|", 0, XK_Tab, 1 },
	{ "й", 0, XK_Cyrillic_shorti, 1 },
	{ "ц", 0, XK_Cyrillic_tse, 1 },
	{ "у", 0, XK_Cyrillic_u, 1 },
	{ "к", 0, XK_Cyrillic_ka, 1 },
	{ "е", 0, XK_Cyrillic_ie, 1 },
	{ "н", 0, XK_Cyrillic_en, 1 },
	{ "г", 0, XK_Cyrillic_ghe, 1 },
	{ "ш", 0, XK_Cyrillic_sha, 1 },
	{ "щ", 0, XK_Cyrillic_shcha, 1 },
	{ "з", 0, XK_Cyrillic_ze, 1 },
	{ "х", 0, XK_Cyrillic_ha, 1 },
	{ "ъ", 0, XK_Cyrillic_hardsign, 1 },
	{ "Return", 0, XK_Return, 3 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Caps_Lock, 2 },
	{ "ф", 0, XK_Cyrillic_ef, 1 },
	{ "ы", 0, XK_Cyrillic_yeru, 1 },
	{ "в", 0, XK_Cyrillic_ve, 1 },
	{ "а", 0, XK_Cyrillic_a, 1 },
	{ "п", 0, XK_Cyrillic_pe, 1 },
	{ "р", 0, XK_Cyrillic_er, 1 },
	{ "о", 0, XK_Cyrillic_o, 1 },
	{ "л", 0, XK_Cyrillic_el, 1 },
	{ "д", 0, XK_Cyrillic_de, 1 },
	{ "ж", 0, XK_Cyrillic_zhe, 1 },
	{ "э", 0, XK_Cyrillic_e, 1 },
	{ "\\","/", XK_backslash, 1 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Shift_L, 3 },
	{ "я", 0, XK_Cyrillic_ya, 1 },
	{ "ч", 0, XK_Cyrillic_che, 1 },
	{ "с", 0, XK_Cyrillic_es, 1 },
	{ "м", 0, XK_Cyrillic_em, 1 },
	{ "и", 0, XK_Cyrillic_i, 1 },
	{ "т", 0, XK_Cyrillic_te, 1 },
	{ "ь", 0, XK_Cyrillic_softsign, 1 },
	{ "б", 0, XK_Cyrillic_be, 1 },
	{ "ю", 0, XK_Cyrillic_yu, 1 },
	{ ".", ",", XK_period, 1 },
	{ 0, 0, XK_Shift_R, 2 },
	{ 0 }, /* New row */
	{ "Ctrl", 0, XK_Control_L, 2 },
	{ "Alt",  0,XK_Alt_L, 2 },
	{ "",  0,XK_space, 5 },
	{ "Alt",  0,XK_Alt_R, 2 },
	{ "Ctrl",  0,XK_Control_R, 2 },
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
	"ru",
};

static Key* available_layers[LAYERS] = {
	keys_ru,
};
