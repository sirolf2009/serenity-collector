package com.sirolf2009.serenity.collector.model

import com.sirolf2009.commonwealth.timeseries.IPoint
import javax.persistence.Embeddable
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors @Embeddable class PersistablePoint implements IPoint {

	var Long x
	var Double y
	
	override toString() {
		return '''(«x», «y»)'''
	}

}
