package com.sirolf2009.serenity.collector.model

import com.sirolf2009.commonwealth.trading.ITrade
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

@Entity @Accessors @ToString class PersistableTrade implements ITrade {
	
	@Id @GeneratedValue
	var long ID
	var PersistablePoint point
	var Number amount
	
}
