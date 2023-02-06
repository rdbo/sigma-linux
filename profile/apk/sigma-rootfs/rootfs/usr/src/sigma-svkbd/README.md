SVKBD: Simple Virtual Keyboard
=================================

This is a simple virtual keyboard, intended to be used in environments,
where no keyboard is available.

Installation
------------

	$ make
	$ make install

This will create by default `svkbd-mobile-intl`, which is svkbd using an international
layout with multiple layers and overlays, and optimised for mobile devices.

You can create svkbd for additional layouts by doing:

	$ make LAYOUT=$layout

This will take the file `layout.$layout.h` and create `svkbd-$layout`.
`make install` will then pick up the new file and install it accordingly.

Layouts
---------

The following layouts are available:

* **Mobile Layouts:**
    * ``mobile-intl`` - A small international layout optimised for mobile devices. This layout consists of multiple layers which
        can be switched on the fly, and overlays that appear on long-press of certain keys, adding input ability for
        diacritics and other variants, as well as some emoji. The layers are:
        * a basic qwerty layer
        * a layer for numeric input, arrows, and punctuation
        * a cyrillic layer (ЙЦУКЕН based); the э key is moved to an overlay on е
        * a dialer/numeric layer
        * an arrow layer
        * a more minimal qwerty layer (bigger keys) for smaller screens/larger fingers.
    * ``mobile-plain`` - This is a plain layout with only a qwerty layer and numeric/punctuation layer. It was
        originally made for [sxmo](https://sr.ht/~mil/Sxmo/).
    * ``mobile-simple`` - This is a more minimalistic layout that is more similar to what Android and iOS offer.
* **Traditional layouts**:
    * ``en`` - An english layout without layers (QWERTY)
    * ``de`` - A german layout (QWERTZ)
    * ``ru`` - A russian layout (ЙЦУКЕН)
    * ``sh`` - A serbo-croatian layout using latin script (QWERTZ)

Usage
-----

	$ svkbd-mobile-intl

This will open svkbd at the bottom of the screen, showing the default
international layout.

	$ svkbd-mobile-intl -d

This tells svkbd to announce itself being a dock window, which then
is managed differently between different window managers. If using dwm
and the dock patch, then this will make svkbd being managed by dwm and
some space of the screen being reserved for it.

	$ svkbd-mobile-intl -g 400x200+1+1

This will start svkbd-mobile-intl with a size of 400x200 and at the upper left
window corner.

For layouts that consist of multiple layers, you can enable layers on program start through either the ``-l`` flag or
through the ``SVKBD_LAYERS`` environment variable.  They both take a comma separated list of layer names (as defined in
your ``layout.*.h``). Use the ``↺`` button in the bottom-left to cycle through all the layers in the exact order they
were specified.

Some layouts come with overlays that will show when certain keys are hold pressed for a longer time. For example, a long
press on the ``a`` key will enable an overview showing all kinds of diacritic combinations for ``a``. In the
``mobile-intl`` layout, a long press on a punctuation key will show an overlay with all further punctuation options (the
same for all punctuation keys). Moreover, a long press on the ``q`` key doubles as a trigger for the emoji overlay in
this layout.

Overlay functionality interferes with the ability to hold a key and have it outputted repeatedly.  You can disable
overlay functionality with the ``-O`` flag or by setting the environment variable ``SVKBD_ENABLEOVERLAYS=0``. There is
also a key on the function layer of the keyboard itself to enable/disable this behaviour on the fly. Its label shows
``≅`` when the overlay functionality is enabled and ``≇`` when not.

Svkbd has been optimised for use on mobile devices with a touchscreen and implements press-on-release
behaviour (which can be disabled), it also works fine on normal desktop systems with a regular mouse.

Advanced Usage
---------------

Svkbd has an extra output mode where all keypresses are printed to standard output. Optionally, you can also disable the
default X11 keypress emulation. This gives you the freedom to use svkbd in other contexts and use simple pipes to
connect it to other tools:


	$ svkbd-mobile-intl -n -o | cowsay

This becomes especially useful if you want things like haptic feedback or audio feedback upon keypress. This is
deliberately not implemented in svkbd itself (we want to keep things simple after all), but can be accomplished using
the external tool [clickclack](https://git.sr.ht/~proycon/clickclack):

	$ svkbd-mobile-intl -o | clickclack -V -f keypress.wav

Notes
---------

This virtual keyboard does not actually modify the X keyboard layout, the ``mobile-intl``, ``mobile-plain``,
``mobile-simple`` and ``en`` layouts simply rely on a standard US QWERTY layout (setxkbmap us) being activated, the
other layouts (``de``, ``ru``, ``sh``) require their respective XKB keymaps to be active.

If you use another XKB layout you will get unpredictable output that does not match the labels on the virtual keycaps!

Repository
----------

	git clone https://git.suckless.org/svkbd
