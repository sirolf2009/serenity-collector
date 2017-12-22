package com.sirolf2009.serenity.collector

import akka.actor.ActorSystem
import akka.actor.Props
import akka.testkit.javadsl.TestKit
import com.sirolf2009.commonwealth.timeseries.Point
import com.sirolf2009.commonwealth.trading.Trade
import com.sirolf2009.commonwealth.trading.orderbook.LimitOrder
import com.sirolf2009.commonwealth.trading.orderbook.Orderbook
import com.sirolf2009.serenity.collector.message.GetOrderbooks
import com.sirolf2009.serenity.collector.message.GetTrades
import com.sirolf2009.serenity.collector.message.Orderbooks
import java.io.File
import java.util.Date
import java.util.concurrent.TimeUnit
import org.junit.Assert
import org.junit.Test
import scala.concurrent.duration.FiniteDuration
import com.sirolf2009.serenity.collector.message.Trades

class CollectorDatabaseTest {
	
	@Test
	def void test() {
		new File("src/test/resources/CollectorDatabaseTest.odb") => [
			parentFile.mkdirs
			delete
		]
		val system = ActorSystem.create()
		new TestKit(system) => [
			val database = system.actorOf(Props.create(CollectorDatabase, [new CollectorDatabase("src/test/resources/CollectorDatabaseTest.odb")]))
			
			database.tell(new Orderbook(new Date(1000), #[new LimitOrder(100, 100)], #[new LimitOrder(1, 1)]), getRef())
			database.tell(new Orderbook(new Date(2000), #[new LimitOrder(200, 200)], #[new LimitOrder(2, 2)]), getRef())
			database.tell(new Orderbook(new Date(3000), #[new LimitOrder(300, 300)], #[new LimitOrder(3, 3)]), getRef())
			
			Thread.sleep(1000)
			
			database.tell(new GetOrderbooks() => [
				since = new Date(2000)
			], getRef())
			
			val orderbooks = expectMsgClass(FiniteDuration.create(1, TimeUnit.SECONDS), Orderbooks)
			Assert.assertEquals(2, orderbooks.orderbooks.size())
			Assert.assertNotNull(orderbooks.orderbooks.filter[timestamp.equals(new Date(2000))])
			Assert.assertNotNull(orderbooks.orderbooks.filter[timestamp.equals(new Date(3000))])
			
			database.tell(new Trade(new Point(1000, 100), 100), getRef())
			database.tell(new Trade(new Point(2000, 200), 200), getRef())
			database.tell(new Trade(new Point(3000, 300), 300), getRef())
			
			Thread.sleep(1000)
			
			database.tell(new GetTrades() => [
				since = new Date(2000)
			], getRef())
			
			val trades = expectMsgClass(FiniteDuration.create(1, TimeUnit.SECONDS), Trades)
			Assert.assertEquals(2, trades.trades.size())
			Assert.assertNotNull(trades.trades.filter[point.x.intValue == 2000])
			Assert.assertNotNull(trades.trades.filter[point.x.intValue == 3000])
		]
		TestKit.shutdownActorSystem(system)
	}
	
}