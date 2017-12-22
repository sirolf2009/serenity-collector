package com.sirolf2009.serenity.collector.message

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import java.util.List
import java.io.Serializable

@Accessors @ToString class Orderbooks implements Serializable {
	var List<IOrderbook> orderbooks
}