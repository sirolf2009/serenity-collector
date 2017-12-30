package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import com.sirolf2009.commonwealth.trading.ITrade
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import com.sirolf2009.util.TimeUtil
import com.sirolf2009.util.akka.ActorHelper
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.util.Calendar
import java.util.TimeZone
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

class Collector15MinFile extends AbstractActor {

	extension val ActorHelper helper = new ActorHelper(this)
	val File dataFolder
	val AtomicReference<PrintWriter> currentFile
	val AtomicInteger currentQuarter
	
	new(File dataFolder) {
		this.dataFolder = dataFolder
		val cal = getCalendar()
		currentFile = new AtomicReference(getNewWriter(cal))
		currentQuarter = new AtomicInteger(getMinute(cal))
	}

	override createReceive() {
		return receiveBuilder -> [
			match(IOrderbook)[
				switchWriter
				writeOrderbook
			]
			match(ITrade) [
				switchWriter
				writeTrade
			]
		]
	}
	
	def switchWriter() {
		if(getCalendar().minute != currentQuarter.get()) {
			currentFile.getAndSet(getCalendar().newWriter).close()
		}
	}
	
	def writeOrderbook(IOrderbook orderbook) {
		currentFile.get().println('''o,«orderbook.timestamp.time»,«orderbook.bids.map['''«price»:«amount»'''].join(", ")»,«orderbook.asks.map['''«price»:«amount»'''].join(", ")»''')
	}
	
	def writeTrade(ITrade trade) {
		currentFile.get().println('''t,«trade.point.x»,«trade.point.y»,«trade.amount»''')
	}
	
	def getNewWriter(Calendar cal) {
		val year = new File(dataFolder, cal.get(Calendar.YEAR).toString())
		val month = new File(year, cal.get(Calendar.MONTH).toString())
		val day = new File(month, cal.get(Calendar.DAY_OF_MONTH).toString())
		val hour = new File(day, cal.get(Calendar.HOUR_OF_DAY).toString())
		hour.mkdirs()
		val file = new File(hour, TimeUtil.format(cal.time))
		return new PrintWriter(new FileWriter(file))
	}
	
	def getMinute(Calendar cal) {
		return cal.get(Calendar.MINUTE)
	}
	
	def getCalendar() {
		val cal = Calendar.getInstance(TimeZone.getTimeZone("Europe/Amsterdam"))
		cal.set(Calendar.MILLISECOND, 0)
		cal.set(Calendar.SECOND, 0)
		val minute = cal.minute
		cal.set(Calendar.MINUTE, minute-(minute%15))
		return cal
	}

}
