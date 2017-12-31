package com.sirolf2009.serenity.collector

import com.sirolf2009.commonwealth.ITick
import java.io.Serializable
import org.eclipse.xtend.lib.annotations.Data

@Data class TickResponse implements Serializable {
	ITick data
}