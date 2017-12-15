package com.sirolf2009.serenity.collector

import akka.actor.ActorSystem
import com.sirolf2009.bitfinex.wss.model.SubscribeOrderbook

class Collector {
	
	def static main(String[] args) {
		val system = ActorSystem.create("Collector")
		val orderbookCollector = system.actorOf(CollectorOrderbook.props("BTCUSD", SubscribeOrderbook.PREC_PRECISE, SubscribeOrderbook.FREQ_REALTIME), "OrderbookCollector")
		val tradeCollector = system.actorOf(CollectorTrades.props("BTCUSD"), "TradeCollector")
		val bufferCollector = system.actorOf(CollectorBuffer.props(5000, 5000), "BufferCollector")
		orderbookCollector.tell(new SubscribeMe(), bufferCollector)
		tradeCollector.tell(new SubscribeMe(), bufferCollector)
	}
	
}