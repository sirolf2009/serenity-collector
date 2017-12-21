package com.sirolf2009.serenity.collector

import akka.actor.ActorSystem
import akka.actor.Props
import com.sirolf2009.bitfinex.wss.model.SubscribeOrderbook

class Collector {

	def static void main(String[] args) {
		val system = ActorSystem.create("Collector")
		val orderbookCollector = system.actorOf(CollectorOrderbook.props("BTCUSD", SubscribeOrderbook.PREC_PRECISE, SubscribeOrderbook.FREQ_REALTIME), "OrderbookCollector")
		val tradeCollector = system.actorOf(CollectorTrades.props("BTCUSD"), "TradeCollector")
		val databaseCollector = system.actorOf(Props.create(CollectorDatabase, [new CollectorDatabase("BTCUSD.odb")]))
		orderbookCollector.tell(new SubscribeMe(), databaseCollector)
		tradeCollector.tell(new SubscribeMe(), databaseCollector)
	}

}
