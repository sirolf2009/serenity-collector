package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import akka.actor.ActorRef
import akka.actor.Props
import akka.event.Logging
import com.google.common.eventbus.Subscribe
import com.sirolf2009.bitfinex.wss.BitfinexWebsocketClient
import com.sirolf2009.bitfinex.wss.event.OnDisconnected
import com.sirolf2009.bitfinex.wss.event.OnSubscribed
import com.sirolf2009.bitfinex.wss.model.SubscribeOrderbook
import com.sirolf2009.bitfinex.wss.model.SubscribeTrades
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class CollectorOrderbook extends AbstractActor {

	val log = Logging.getLogger(getContext().getSystem(), this)
	val String symbol
	val String precision
	val String frequency
	val List<ActorRef> subscriptions
	var BitfinexWebsocketClient client

	new(String symbol, String precision, String frequency) {
		this.symbol = symbol
		this.precision = precision
		this.frequency = frequency
		this.subscriptions = new ArrayList()
	}
	
	override preStart() throws Exception {
		connect()
	}

	@Subscribe def void onSubscribed(OnSubscribed sub) {
		sub.eventBus.register(this)
	}

	@Subscribe def void onOrderbook(IOrderbook orderbook) {
		subscriptions.forEach [
			tell(orderbook, self())
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
		client.send(new SubscribeOrderbook(symbol, precision, frequency))
		client.send(new SubscribeTrades(symbol))
		log.info("Connected")
	}
	

	override createReceive() {
		return receiveBuilder().match(SubscribeMe, [
			log.info(sender()+" subscribed")
			subscriptions.add(sender())
		]).match(SubscribeMe, [
			log.info(sender()+" subscribed")
			subscriptions.remove(sender())
		]).build()
	}

	def static Props props(String symbol, String precision, String frequency) {
		return Props.create(CollectorOrderbook, [new CollectorOrderbook(symbol, precision, frequency)])
	}

}
