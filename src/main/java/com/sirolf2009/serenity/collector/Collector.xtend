package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import akka.actor.ActorSystem
import akka.actor.Props
import com.sirolf2009.bitfinex.wss.model.SubscribeOrderbook
import com.sirolf2009.commonwealth.ITick
import com.sirolf2009.util.akka.ActorHelper
import com.typesafe.config.ConfigFactory
import java.io.File
import java.util.Date
import java.util.concurrent.CountDownLatch
import java.util.function.Consumer
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class Collector {

	def static void main(String[] args) {
		val system = ActorSystem.create("Collector", ConfigFactory.parseFile(new File(Collector.classLoader.getResource("host.conf").file)))
		val orderbookCollector = system.actorOf(CollectorOrderbook.props("BTCUSD", SubscribeOrderbook.PREC_PRECISE, SubscribeOrderbook.FREQ_REALTIME), "OrderbookCollector")
		val tradeCollector = system.actorOf(CollectorTrades.props("BTCUSD"), "TradeCollector")
		val databaseCollector = system.actorOf(Props.create(Collector15MinFile, [new Collector15MinFile(new File("BTCUSD"))]), "Database")
		orderbookCollector.tell(new SubscribeMe(), databaseCollector)
		tradeCollector.tell(new SubscribeMe(), databaseCollector)
	}
	
	def static getData(String host, Date from, Date to, Consumer<ITick> tickConsumer) {
		val CountDownLatch countdownLatch = new CountDownLatch(1)
		val system = ActorSystem.create("Client", ConfigFactory.parseFile(new File(Collector.classLoader.getResource("client.conf").file)))
		system.actorOf(Props.create(RetrieverActor, [new RetrieverActor(host, from, to, countdownLatch, tickConsumer)]))
		countdownLatch.await()
		system.terminate()
	}
	
	@FinalFieldsConstructor static class RetrieverActor extends AbstractActor {
		
		extension val ActorHelper helper = new ActorHelper(this)
		val String host
		val Date from
		val Date to
		val CountDownLatch countdownLatch
		val Consumer<ITick> tickConsumer
		
		override preStart() throws Exception {
			getContext().actorSelection('''akka.tcp://Collector@«host»:4567/user/Database''').tell(new RequestData(from, to), self())
		}
		
		override createReceive() {
			return receiveBuilder -> [
				match(TickResponse) [
					tickConsumer.accept(data)
				]
				match(DataEndResponse) [
					countdownLatch.countDown()
				]
			]
		}
		
	}

}
