package com.sirolf2009.serenity.collector

import akka.actor.AbstractActor
import akka.actor.Props
import com.sirolf2009.commonwealth.trading.ITrade
import com.sirolf2009.commonwealth.trading.orderbook.ILimitOrder
import com.sirolf2009.commonwealth.trading.orderbook.IOrderbook
import java.util.Date
import java.util.List
import javax.jdo.annotations.Index
import javax.persistence.Embedded
import javax.persistence.Entity
import javax.persistence.EntityManager
import javax.persistence.EntityManagerFactory
import javax.persistence.FlushModeType
import javax.persistence.GeneratedValue
import javax.persistence.Id
import javax.persistence.Persistence
import javax.persistence.Temporal
import org.apache.commons.collections4.queue.CircularFifoQueue
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.annotations.ToString
import java.util.Collection
import javax.persistence.Embeddable
import com.sirolf2009.commonwealth.timeseries.IPoint

@FinalFieldsConstructor class CollectorDatabase extends AbstractActor {
	
	val String databaseFile
	var EntityManagerFactory factory
	var EntityManager database
	
	override preStart() throws Exception {
		factory = Persistence.createEntityManagerFactory(databaseFile)
		database = factory.createEntityManager
		database.flushMode = FlushModeType.AUTO
	}
	
	override createReceive() {
		return receiveBuilder().match(IOrderbook, [
			database.transaction.begin()
			database.persist(new PersistableOrderbook() => [persist|
				persist.timestamp = it.timestamp
				persist.asks = asks.persistable()
				persist.bids = bids.persistable()
			])
			database.transaction.commit()
		]).match(ITrade, [
			database.transaction.begin()
			database.persist(new PersistableTrade() => [persist|
				persist.point = new PersistablePoint() => [pointpersist|
					pointpersist.x = point.x
					pointpersist.y = point.y
				]
				persist.amount = amount
			])
			database.transaction.commit()
		]).match(GetOrderbook, [
			database.createQuery("SELECT o FROM PersistableOrderbook o").resultList.map[it as PersistableOrderbook].forEach[
				println(it)
			]
		]).build()
	}
	
	def static List<ILimitOrder> persistable(Collection<ILimitOrder> orders) {
		return orders.map[order|
			new PersistableLimitOrder() => [
				price = order.price
				amount = order.amount
			]
		].map[it as ILimitOrder].toList()
	}
	
	override postStop() throws Exception {
		println("stopping")
		database.close()
		factory.close()
	}
	
	def static Props props(int orderbookSize, int tradeSize) {
		return Props.create(CollectorBuffer, [new CollectorBuffer(new CircularFifoQueue<IOrderbook>(orderbookSize), new CircularFifoQueue<ITrade>(tradeSize))])
	}
	
	@Data static class GetOrderbook {
		val Date since
	}
	
	@Entity @Accessors @ToString static class PersistableOrderbook implements IOrderbook {
		@Id @GeneratedValue var long ID
		@Temporal(TIMESTAMP) @Index var Date timestamp
		var List<ILimitOrder> asks
		var List<ILimitOrder> bids
	}
	
	@Accessors @Embeddable static class PersistableLimitOrder implements ILimitOrder {
		var Number price
		var Number amount
		
		override toString() {
			return '''«amount» for «price»$'''
		}
	}
	
	@Entity @Accessors @ToString static class PersistableTrade implements ITrade {
		@Id @GeneratedValue var long ID
		var IPoint point
		var Number amount
	}
	@Accessors @Embeddable static class PersistablePoint implements IPoint {
		var Number x
		var Number y
	}
	
}