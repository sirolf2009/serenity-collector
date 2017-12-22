package com.sirolf2009.serenity.collector.message

import java.io.Serializable
import java.util.Date
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

@Accessors @ToString class GetTrades implements Serializable {
	var Date since
}