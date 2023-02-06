#define KEYS 66
static Key keys_sh[] = {
	{ "`","~", XK_quoteleft, 1},
	{ "1","!~", XK_1, 1 },
	{ "2","\"ˇ", XK_2, 1 },
	{ "3","#^", XK_3, 1 },
	{ "4","$˘", XK_4, 1 },
	{ "5","%°", XK_5, 1 },
	{ "6","&˛", XK_6, 1 },
	{ "7","/`", XK_7, 1 },
	{ "8","(˙", XK_8, 1 },
	{ "9",")'", XK_9, 1 },
	{ "0","=˝", XK_0, 1 },
	{ "'","?¨", XK_apostrophe, 1 },
	{ "+","*¸", XK_plus, 1 },
	{ "<","-", XK_BackSpace, 2 },
	{ "Del",0, XK_Delete, 1},
	{ 0 }, /* New row */
	{ "->|", 0, XK_Tab, 1 },
	{ "q","Q\\", XK_q, 1 },
	{ "w","W|", XK_w, 1 },
	{ "e","E", XK_e, 1 },
	{ "r","R", XK_r, 1 },
	{ "t","T", XK_t, 1 },
	{ "z","Z", XK_z, 1 },
	{ "u","U", XK_u, 1 },
	{ "i","I", XK_i, 1 },
	{ "o","O", XK_o, 1 },
	{ "p","P", XK_p, 1 },
	{ "š","Š÷", XK_scaron, 1 },
	{ "đ","Đ×", XK_dstroke, 1 },
	{ "Enter",0, XK_Return, 3 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Caps_Lock, 2 },
	{ "a","A", XK_a, 1 },
	{ "s","S", XK_s, 1 },
	{ "d","D", XK_d, 1 },
	{ "f","F[", XK_f, 1 },
	{ "g","G]", XK_g, 1 },
	{ "h","H", XK_h, 1 },
	{ "j","J̣̣", XK_j, 1 },
	{ "k","Kł", XK_k, 1 },
	{ "l","LŁ", XK_l, 1 },
	{ "č","Č", XK_ccaron, 1 },
	{ "ć","Ćß", XK_cacute, 1 },
	{ "ž","Ž¤", XK_zcaron, 1 },
	{ 0 }, /* New row */
	{ 0, 0, XK_Shift_L, 2 },
	{ "<",">«»", XK_less, 1 },
	{ "y","Y", XK_y, 1 },
	{ "x","X", XK_x, 1 },
	{ "c","C", XK_c, 1 },
	{ "v","V@", XK_v, 1 },
	{ "b","B{", XK_b, 1 },
	{ "n","N}", XK_n, 1 },
	{ "m","M§", XK_m, 1 }, /* XXX no symbol */
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
	"sh",
};

static Key* available_layers[LAYERS] = {
	keys_sh,
};
