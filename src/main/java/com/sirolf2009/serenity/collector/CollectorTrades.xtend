package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import akka.actor.ActorRef
import akka.actor.Props
import akka.event.Logging
import com.google.common.eventbus.Subscribe
import com.sirolf2009.bitfinex.wss.BitfinexWebsocketClient
import com.sirolf2009.bitfinex.wss.event.OnDisconnected
import com.sirolf2009.bitfinex.wss.event.OnSubscribed
import com.sirolf2009.bitfinex.wss.model.SubscribeTrades
import com.sirolf2009.commonwealth.trading.ITrade
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class CollectorTrades extends AbstractActor {

	val log = Logging.getLogger(getContext().getSystem(), this)
	val String symbol
	val List<ActorRef> subscriptions
	var BitfinexWebsocketClient client

	new(String symbol) {
		this.symbol = symbol
		this.subscriptions = new ArrayList()
	}
	
	override preStart() throws Exception {
		connect()
	}

	@Subscribe def void onSubscribed(OnSubscribed sub) {
		sub.eventBus.register(this)
	}

	@Subscribe def void onTrade(ITrade trade) {
		subscriptions.forEach [
			tell(trade, self())
		]
	}

	@Subscribe def void onDisconnected(OnDisconnected onDisconnected) {
		log.warning(onDisconnected+"")
		log.warning("reconnecting...")
		connect()
	}

	def void connect() {
		client = new BitfinexWebsocketClient()
		client.eventBus.register(this)
		client.connectBlocking()
		client.send(new SubscribeTrades(symbol))
		log.info("Connected")
	}

	override createReceive() {
		return receiveBuilder().match(SubscribeMe, [
			subscriptions.add(sender())
			log.info(sender()+" subscribed")
		]).match(SubscribeMe, [
			subscriptions.remove(sender())
			log.info(sender()+" unsubscribed")
		]).build()
	}

	def static Props props(String symbol) {
		return Props.create(CollectorTrades, [new CollectorTrades(symbol)])
	}

}
