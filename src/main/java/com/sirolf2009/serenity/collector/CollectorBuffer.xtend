package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import akka.actor.Props
import com.sirolf2009.commonwealth.trading.ITrade
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import org.apache.commons.collections4.queue.CircularFifoQueue
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class CollectorBuffer extends AbstractActor {
	
	val CircularFifoQueue<IOrderbook> orderbookBuffer
	val CircularFifoQueue<ITrade> tradeBuffer
	
	override createReceive() {
		return receiveBuilder().match(IOrderbook, [
			orderbookBuffer.add(it)
		]).match(ITrade, [
			tradeBuffer.add(it)
		]).build()
	}
	
	def static Props props(int orderbookSize, int tradeSize) {
		return Props.create(CollectorBuffer, [new CollectorBuffer(new CircularFifoQueue<IOrderbook>(orderbookSize), new CircularFifoQueue<ITrade>(tradeSize))])
	}
	
}