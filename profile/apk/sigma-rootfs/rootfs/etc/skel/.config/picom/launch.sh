#!/bin/sh

pkill -9 picom
picom --experimental-backends --blur-method dual_kawase
