#!/bin/sh


curl -s 'wttr.in/Moscow?format=1' | sed 's/+//g'

