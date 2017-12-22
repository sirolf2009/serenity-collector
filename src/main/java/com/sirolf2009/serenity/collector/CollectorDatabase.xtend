package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import com.sirolf2009.commonwealth.trading.ITrade
import com.sirolf2009.commonwealth.trading.orderbook.ILimitOrder
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import com.sirolf2009.serenity.collector.model.PersistableLimitOrder
import com.sirolf2009.serenity.collector.model.PersistableOrderbook
import com.sirolf2009.serenity.collector.model.PersistablePoint
import com.sirolf2009.serenity.collector.model.PersistableTrade
import java.util.Collection
import java.util.List
import javax.persistence.EntityManager
import javax.persistence.EntityManagerFactory
import javax.persistence.FlushModeType
import javax.persistence.Persistence
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.text.SimpleDateFormat
import com.sirolf2009.serenity.collector.message.GetOrderbooks
import com.sirolf2009.util.akka.ActorHelper
import com.sirolf2009.serenity.collector.message.Orderbooks
import com.sirolf2009.serenity.collector.message.GetTrades
import com.sirolf2009.serenity.collector.message.Trades

@FinalFieldsConstructor class CollectorDatabase extends AbstractActor {

	extension val ActorHelper helper = new ActorHelper(this)
	val String databaseFile
	var EntityManagerFactory factory
	var EntityManager database

	override preStart() throws Exception {
		factory = Persistence.createEntityManagerFactory(databaseFile)
		database = factory.createEntityManager
		database.flushMode = FlushModeType.AUTO
	}

	override createReceive() {
		return receiveBuilder -> [
			match(IOrderbook) [
				database.transaction.begin()
				database.persist(new PersistableOrderbook() => [ persist |
					persist.timestamp = it.timestamp
					persist.asks = asks.persistable()
					persist.bids = bids.persistable()
				])
				database.transaction.commit()
			]
			match(ITrade) [
				database.transaction.begin()
				database.persist(new PersistableTrade() => [ persist |
					persist.point = new PersistablePoint() => [ pointpersist |
						pointpersist.x = point.x.longValue
						pointpersist.y = point.y.doubleValue
					]
					persist.amount = amount
				])
				database.transaction.commit()
			]
			match(GetOrderbooks) [
				val orderbooks = new Orderbooks() => [ response |
					response.orderbooks = database.createQuery('''SELECT o FROM PersistableOrderbook o WHERE o.timestamp >= {ts '«new SimpleDateFormat("yyy-MM-dd HH:mm:ss").format(since)»'}''').resultList.map[it as IOrderbook].toList()
				]
				sender() => orderbooks
			]
			match(GetTrades) [
				val trades = new Trades() => [ response |
					response.trades = database.createQuery('''SELECT t FROM PersistableTrade t WHERE t.point.x >= «since.time»''').resultList.map[it as ITrade].toList()
				]
				sender() => trades
			]
		]
	}

	def static List<ILimitOrder> persistable(Collection<ILimitOrder> orders) {
		return orders.map [ order |
			new PersistableLimitOrder() => [
				price = order.price
				amount = order.amount
			]
		].map[it as ILimitOrder].toList()
	}

	override postStop() throws Exception {
		database.close()
		factory.close()
	}

}
