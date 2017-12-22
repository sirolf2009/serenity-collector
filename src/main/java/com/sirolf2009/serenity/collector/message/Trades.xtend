package com.sirolf2009.serenity.collector.message

import com.sirolf2009.commonwealth.trading.ITrade
import java.io.Serializable
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

@Accessors @ToString class Trades implements Serializable {
	var List<ITrade> trades
}