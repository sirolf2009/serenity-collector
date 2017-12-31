package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import com.sirolf2009.commonwealth.ITick
import com.sirolf2009.commonwealth.Tick
import com.sirolf2009.commonwealth.timeseries.Point
import com.sirolf2009.commonwealth.trading.ITrade
import com.sirolf2009.commonwealth.trading.Trade
import com.sirolf2009.commonwealth.trading.orderbook.ILimitOrder
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import com.sirolf2009.commonwealth.trading.orderbook.LimitOrder
import com.sirolf2009.commonwealth.trading.orderbook.Orderbook
import com.sirolf2009.util.TimeUtil
import com.sirolf2009.util.akka.ActorHelper
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.nio.file.Files
import java.util.ArrayList
import java.util.Calendar
import java.util.Date
import java.util.List
import java.util.TimeZone
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import java.util.stream.Collectors
import org.eclipse.xtend.lib.annotations.Data

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
			match(RequestData) [
				sender() => new DataResponse(getData(from, to))
			]
		]
	}
	
	def switchWriter() {
		if(getCalendar().minute != currentQuarter.get()) {
			currentFile.getAndSet(getCalendar().newWriter).close()
			currentQuarter.set(getCalendar().minute)
		}
	}
	
	def writeOrderbook(IOrderbook orderbook) {
		currentFile.get().println('''o,«orderbook.timestamp.time»,«orderbook.asks.map['''«price»:«amount»'''].join(";")»,«orderbook.bids.map['''«price»:«amount»'''].join(";")»''')
	}
	
	def writeTrade(ITrade trade) {
		currentFile.get().println('''t,«trade.point.x»,«trade.point.y»,«trade.amount»''')
	}
	
	def getNewWriter(Calendar cal) {
		val file = cal.file
		file.parentFile.mkdirs()
		return new PrintWriter(new FileWriter(file))
	}
	
	def getData(Date from, Date to) {
		return TimeUtil.getPointsToDate(from.roundTo15Min, to.roundTo15Min, 15).map[getData].flatten.toList()
	}
	
	def getData(Date timestamp) {
		val ticks = new ArrayList<ITick>()
		val trades = new ArrayList<ITrade>()
		Files.readAllLines(timestamp.file.toPath).forEach[
			if(startsWith("t")) {
				val orderbook = parseOrderbook
				ticks += new Tick(orderbook.timestamp, orderbook, trades.stream.collect(Collectors.toList()))
				trades.clear()
			} else {
				trades += parseTrade
			}
		]
		return ticks
	}
	
	def parseOrderbook(String line) {
		val it = line.split(",")
		val timestamp = new Date(Long.parseLong(get(1)))
		val asks = get(2).split(";").map[
			val it = split(":")
			return new LimitOrder(Double.parseDouble(get(0)), Double.parseDouble(get(1))) as ILimitOrder
		]
		val bids = get(3).split(";").map[
			val it = split(":")
			return new LimitOrder(Double.parseDouble(get(0)), Double.parseDouble(get(1))) as ILimitOrder
		]
		return new Orderbook(timestamp, asks, bids) as IOrderbook
	}
	
	def parseTrade(String line) {
		val it = line.split(",")
		return new Trade(new Point(Long.parseLong(get(1)), Double.parseDouble(get(2))), Double.parseDouble(get(3))) as ITrade
	}
	
	def getFile(Date timestamp) {
		return timestamp.calendar.file
	}
	
	def getFile(Calendar cal) {
		val year = new File(dataFolder, cal.get(Calendar.YEAR).toString())
		val month = new File(year, cal.get(Calendar.MONTH).toString())
		val day = new File(month, cal.get(Calendar.DAY_OF_MONTH).toString())
		val hour = new File(day, cal.get(Calendar.HOUR_OF_DAY).toString())
		return new File(hour, TimeUtil.format(cal.time))
	}
	
	def getCalendar() {
		return Calendar.getInstance(TimeZone.getTimeZone("Europe/Amsterdam")).roundTo15Min
	}
	
	def roundTo15Min(Date date) {
		return date.calendar.roundTo15Min.time
	}
	
	def getCalendar(Date date) {
		val cal = Calendar.getInstance(TimeZone.getTimeZone("Europe/Amsterdam"))
		cal.time = date
		return cal
	}
	
	def roundTo15Min(Calendar cal) {
		cal.set(Calendar.MILLISECOND, 0)
		cal.set(Calendar.SECOND, 0)
		val minute = cal.minute
		cal.set(Calendar.MINUTE, minute-(minute%15))
		return cal
	}
	
	def getMinute(Calendar cal) {
		return cal.get(Calendar.MINUTE)
	}
	
	@Data static class RequestData {
		Date from
		Date to
	}
	@Data static class DataResponse {
		List<ITick> data
	}

}
