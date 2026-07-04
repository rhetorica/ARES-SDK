
	timer() {
		key tag = getk(finishing, 0);
		finishing = delitem(finishing, 0);
		finish(tag);
		if(!count(finishing))
			llSetTimerEvent(0);
	}