package com.sirolf2009.serenity.collector

import java.io.Serializable
import java.util.Date
import org.eclipse.xtend.lib.annotations.Data

@Data class RequestData implements Serializable {
	Date from
	Date to
}