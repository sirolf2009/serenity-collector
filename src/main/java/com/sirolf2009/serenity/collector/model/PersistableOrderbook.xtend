package com.sirolf2009.serenity.collector.model

import com.sirolf2009.commonwealth.trading.orderbook.ILimitOrder
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import java.util.Date
import java.util.List
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id
import javax.persistence.Temporal
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString
import javax.jdo.annotations.Index

@Entity @Accessors @ToString class PersistableOrderbook implements IOrderbook {
	
	@Id @GeneratedValue 
	var long ID
	@Temporal(TIMESTAMP) @Index 
	var Date timestamp
	var List<ILimitOrder> asks
	var List<ILimitOrder> bids
	
}
