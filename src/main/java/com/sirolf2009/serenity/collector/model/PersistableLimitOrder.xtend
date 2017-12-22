package com.sirolf2009.serenity.collector.model

import com.sirolf2009.commonwealth.trading.orderbook.ILimitOrder
import javax.persistence.Embeddable
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors @Embeddable class PersistableLimitOrder implements ILimitOrder {
	
	var Number price
	var Number amount

	override toString() {
		return '''«amount» for «price»$'''
	}
	
}
