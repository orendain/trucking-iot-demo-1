package com.orendainx.hortonworks.trucking.storm.java.bolts;

import com.orendainx.hortonworks.trucking.commons.models.EnrichedTruckAndTrafficData;
import com.orendainx.hortonworks.trucking.commons.models.EnrichedTruckData;
import com.orendainx.hortonworks.trucking.commons.models.TrafficData;
import org.apache.storm.task.OutputCollector;
import org.apache.storm.task.TopologyContext;
import org.apache.storm.topology.OutputFieldsDeclarer;
import org.apache.storm.topology.base.BaseWindowedBolt;
import org.apache.storm.tuple.Fields;
import org.apache.storm.tuple.Tuple;
import org.apache.storm.tuple.Values;
import org.apache.storm.windowing.TupleWindow;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

import static java.lang.Math.abs;

/**
  * Bolt responsible for joining tuples housing different data types together
  *
  * @author Edgar Orendain <edgar@orendainx.com>
  */
public class TruckAndTrafficJoinBolt extends BaseWindowedBolt {

  private OutputCollector outputCollector;

  public void prepare(Map stormConf, TopologyContext context, OutputCollector collector) {
    outputCollector = collector;
  }

  public void execute(TupleWindow inputWindow) {

    // Collections to store data in
    HashMap<Integer, ArrayList<EnrichedTruckData>> truckDataPerRoute = new HashMap<>();
    HashMap<Integer, ArrayList<TrafficData>> trafficDataPerRoute = new HashMap<>();

    // Process each one of the tuples captured in the input window, separating data according to routeId
    for (Tuple tuple : inputWindow.get()) {
      switch (tuple.getStringByField("dataType")) {
        case "EnrichedTruckData":
          EnrichedTruckData truckData = (EnrichedTruckData)tuple.getValueByField("data");
          ArrayList<EnrichedTruckData> truckList = truckDataPerRoute.getOrDefault(truckData.routeId(), new ArrayList<>());
          truckList.add(truckData);
          truckDataPerRoute.put(truckData.routeId(), truckList);
          break;
        case "TrafficData":
          TrafficData trafficData = (TrafficData)tuple.getValueByField("data");
          ArrayList<TrafficData> trafficList = trafficDataPerRoute.getOrDefault(trafficData.routeId(), new ArrayList<>());
          trafficList.add(trafficData);
          trafficDataPerRoute.put(trafficData.routeId(), trafficList);
          break;
      }
    }

    processAndEmitData(truckDataPerRoute, trafficDataPerRoute);

    // Acknowledge all tuples processed.  It is best practice to perform this after all processing has been completed.
    inputWindow.get().forEach(outputCollector::ack);
  }

  /**
    * Correlate the two sets of data so that traffic data is merged with truck data.
    * After correlation, emit the data into an output stream.
    *
    * Note: the specific inner-workings of this method aren't important, except for how we emit the resulting
    * tuple using outputCollector.emit()
    */
  private void processAndEmitData(Map<Integer, ArrayList<EnrichedTruckData>> truckDataPerRoute,
                                 Map<Integer, ArrayList<TrafficData>> trafficDataPerRoute) {

    // For each EnrichedTruckData object, find the TrafficData object with the closest timestamp
    for (Map.Entry<Integer, ArrayList<EnrichedTruckData>> entry : truckDataPerRoute.entrySet()) {

      int routeId = entry.getKey();
      ArrayList<EnrichedTruckData> truckDataList = entry.getValue();
      ArrayList<TrafficData> trafficDataList = trafficDataPerRoute.get(routeId);

      // If test fails, window didn't capture any traffic data for this truck's route
      if (trafficDataList != null) {
        truckDataList.forEach(truckData ->
          trafficDataList.stream()
              .sorted(Comparator.comparingLong(d -> abs(d.eventTime() - truckData.eventTime()))) // Sort by event with the closest timestamp
              .findFirst() // Take the first result
              .ifPresent(td -> {
                EnrichedTruckAndTrafficData joinedData =
                    new EnrichedTruckAndTrafficData(truckData.eventTime(), truckData.truckId(), truckData.driverId(), truckData.driverName(),
                        truckData.routeId(), truckData.routeName(), truckData.latitude(), truckData.longitude(), truckData.speed(),
                        truckData.eventType(), truckData.foggy(), truckData.rainy(), truckData.windy(), td.congestionLevel());

                outputCollector.emit(new Values("EnrichedTruckAndTrafficData", joinedData, joinedData.driverId()));
              })
        );
      }
    }
  }

  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    declarer.declare(new Fields("dataType", "data", "driverId"));
  }
}
