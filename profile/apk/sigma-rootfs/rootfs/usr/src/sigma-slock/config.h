/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nogroup";

static const char *colorname[NUMCOLS] = {
	[INIT] =   "#101a20",     /* after initialization */
	[INPUT] =  "#00ffc8",     /* during input */
	[FAILED] = "#ff0000",     /* wrong password */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;

/* Background image path, should be available to the user above */
static const char* background_image = "/usr/share/backgrounds/wallpaper-blur.png";
