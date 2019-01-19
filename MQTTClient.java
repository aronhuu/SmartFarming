import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import java.net.URL;

public class MQTTClient implements MqttCallback {

	MqttClient client;
	
	public MQTTClient() {}
	
	
	public void doDemo() {
	    try {
	        client = new MqttClient("tcp://127.0.0.1:1883", MqttClient.generateClientId());
	        client.connect();
	        client.setCallback(this);
	        client.subscribe("test");
	        
	    } catch (MqttException e) {
	        e.printStackTrace();
	    }
	}
	
	@Override
	public void connectionLost(Throwable cause) {
	    // TODO Auto-generated method stub
	
	}
	
	@Override
	public void messageArrived(String topic, MqttMessage message) throws Exception {
	 System.out.println("Meassage arrived: " + message);
	}
	
	
	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
	    // TODO Auto-generated method stub
	
	}
	
	
	public static void main(String[] args) {
	    new MQTTClient().doDemo();
	}

}
