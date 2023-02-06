#define KEYS 66
static Key keys_sr[] = {
	{ "`","~", XK_quoteleft, 1},
	{ "1","!", XK_1, 1 },
	{ "2","\"", XK_2, 1 },
	{ "3","#", XK_3, 1 },
	{ "4","$", XK_4, 1 },
	{ "5","%", XK_5, 1 },
	{ "6","&", XK_6, 1 },
	{ "7","/", XK_7, 1 },
	{ "8","(", XK_8, 1 },
	{ "9",")", XK_9, 1 },
	{ "0","=", XK_0, 1 },
	{ "'","?", XK_apostrophe, 1 },
	{ "+","*", XK_plus, 1 },
	{ "<-",0, XK_BackSpace, 2 },
	{ "Del",0, XK_Delete, 1},
	{ 0 }, /* New row */
	{ "->|", 0, XK_Tab, 1 },
	{ "љ","Љ", XK_Cyrillic_lje, 1 },
	{ "њ","Њ", XK_Cyrillic_nje, 1 },
	{ "е","Е", XK_Cyrillic_ie, 1 },
	{ "р","Р", XK_Cyrillic_er, 1 },
	{ "т","Т", XK_Cyrillic_te, 1 },
	{ "з","З", XK_Cyrillic_ze, 1 },
	{ "у","У", XK_Cyrillic_u, 1 },
	{ "и","И", XK_Cyrillic_i, 1 },
	{ "о","О", XK_Cyrillic_o, 1 },
	{ "п","П", XK_Cyrillic_pe, 1 },
	{ "ш","Ш", XK_Cyrillic_sha, 1 },
	{ "ђ","Ђ", XK_Serbian_dje, 1 },
	{ "Enter",0, XK_Return, 3 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Caps_Lock, 2 },
	{ "а","А", XK_Cyrillic_a, 1 },
	{ "с","С", XK_Cyrillic_es, 1 },
	{ "д","Д", XK_Cyrillic_de, 1 },
	{ "ф","Ф", XK_Cyrillic_ef, 1 },
	{ "г","Г", XK_Cyrillic_ghe, 1 },
	{ "х","Х", XK_Cyrillic_ha, 1 },
	{ "j","J̣̣", XK_Cyrillic_je, 1 },
	{ "к","К", XK_Cyrillic_ka, 1 },
	{ "л","Л", XK_Cyrillic_el, 1 },
	{ "ч","Ч", XK_Cyrillic_che, 1 },
	{ "ћ","Ћ", XK_Serbian_tshe, 1 },
	{ "ж","Ж", XK_Cyrillic_zhe, 1 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Shift_L, 2 },
	{ "<",">", XK_less, 1 },
	{ "ѕ","Ѕ", XK_Serbian_dze, 1 },
	{ "џ","Џ", XK_Cyrillic_dzhe, 1 },
	{ "ц","Ц", XK_Cyrillic_tse, 1 },
	{ "в","В", XK_Cyrillic_ve, 1 },
	{ "б","Б", XK_Cyrillic_be, 1 },
	{ "н","Н", XK_Cyrillic_en, 1 },
	{ "м","М", XK_Cyrillic_em, 1 },
	{ ",",";", XK_comma, 1 },
	{ ".",":", XK_period, 1 },
	{ "-","_", XK_minus, 1 },
	{ 0, 0, XK_Shift_R, 2 },
	{ 0 }, /* New row */
	{ "Ctrl", 0, XK_Control_L, 2 },
	{ "Win", 0, XK_Super_L, 2 },
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
	"sr",
};

static Key* available_layers[LAYERS] = {
	keys_sr,
};
