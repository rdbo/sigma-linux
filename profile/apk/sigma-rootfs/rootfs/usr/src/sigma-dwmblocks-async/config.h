#define CMDLENGTH 45
#define DELIMITER " | "
#define CLICKABLE_BLOCKS

const Block blocks[] = {
	BLOCK("sbnetwork",        1,  1),
	BLOCK("sbtime",           1,  2),
	BLOCK("sbnwif",           1,  3),
	BLOCK("sbcpu",            1,  5),
	BLOCK("sbmemory",         5,  6),
	BLOCK("sbbattery",        10, 7),
	BLOCK("sbaudio sink",     1,  8),
	BLOCK("sbaudio source",   1,  9),
	BLOCK("sbbluetooth",      0,  10),
	BLOCK("sbscrsht",         0,  11),
	BLOCK("sbvirtkbd",        0,  12),
	BLOCK("sbkbdlayout",      0,  13),
	BLOCK("sbmonitor",        0,  14),
	BLOCK("sbpower",          0,  15),
	BLOCK("sbgap",            0,  16)
};
