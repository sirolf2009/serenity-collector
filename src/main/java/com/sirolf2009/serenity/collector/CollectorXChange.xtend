package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import akka.actor.ActorRef
import com.sirolf2009.commonwealth.timeseries.Point
import com.sirolf2009.commonwealth.trading.Trade
import com.sirolf2009.util.akka.ActorHelper
import info.bitrich.xchangestream.core.StreamingExchange
import java.util.ArrayList
import java.util.List
import org.knowm.xchange.currency.CurrencyPair
import org.knowm.xchange.dto.Order.OrderType

class CollectorXChange extends AbstractActor {

	extension val ActorHelper helper = new ActorHelper(this)
	val StreamingExchange exchange
	val CurrencyPair pair
	val List<ActorRef> subscriptions

	new(StreamingExchange exchange, CurrencyPair pair) {
		this.exchange = exchange
		this.pair = pair
		subscriptions = new ArrayList()
	}

	override preStart() throws Exception {
		exchange.streamingMarketDataService.getTrades(pair).subscribe[
			val trade = new Trade(new Point(timestamp.time, price.doubleValue()), if(type == OrderType.BID) originalAmount.doubleValue() else -originalAmount.doubleValue())
			subscriptions.forEach[tell(trade, self())]
		]
	}

	override createReceive() {
		return receiveBuilder -> [
			match(SubscribeMe) [
				subscriptions.add(sender())
				info(sender() + " subscribed")
			]
			match(UnsubscribeMe) [
				subscriptions.remove(sender())
				log.info(sender() + " unsubscribed")
			]
		]
	}

}
