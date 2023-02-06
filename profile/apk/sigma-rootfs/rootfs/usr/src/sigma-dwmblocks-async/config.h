#define CMDLENGTH 45
#define DELIMITER " | "
#define CLICKABLE_BLOCKS

const Block blocks[] = {
        BLOCK("sbnetwork",        1,  17),
	BLOCK("sbtime",           1,  18),
        BLOCK("sbnwif eth0",      5,  19),
        BLOCK("sbnwif -w wlan0",  5,  20),
        BLOCK("sbcpu",            1,  21),
        BLOCK("sbmemory",         5,  22),
        BLOCK("sbbattery BAT1",   10, 23),
        BLOCK("sbaudio sink",     1,  24),
        BLOCK("sbaudio source",   1,  25),
        BLOCK("sbbluetooth",      0,  26),
        BLOCK("sbscrsht",         0,  27),
        BLOCK("sbvirtkbd",        0,  28),
        BLOCK("sbkbdlayout",      0,  29),
        BLOCK("sbpower",          0,  30),
};
