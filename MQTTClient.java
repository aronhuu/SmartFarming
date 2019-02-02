import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import java.net.URL;

import javax.swing.JFrame;
import javax.swing.JOptionPane;
import com.google.gson.Gson;

public class MQTTClient implements MqttCallback {

	MqttClient client;
    Gson gson = new Gson();

	public MQTTClient() {}
	
	public void doDemo() {
	    try {
	        client = new MqttClient("tcp://138.100.48.251:1883", MqttClient.generateClientId()); //138.100.48.251, 10.49.1.26 
	        client.connect();
	        client.setCallback(this);
	        client.subscribe("smartFarming/commanding");
	        
	    } catch (MqttException e) {
	        e.printStackTrace();
	    }
	}
	
	@Override
	public void connectionLost(Throwable cause) {
	    // TODO Auto-generated method stub
	
	}
	
    JFrame frame = new JFrame("JOptionPane showMessageDialog example");

	
	@Override
	public void messageArrived(String topic, MqttMessage message) throws Exception {
        CommandingMsg commandingMsg = gson.fromJson(message.toString(), CommandingMsg.class);

		if(commandingMsg.buzzerActive==1) {
			System.out.println("Buzzer alert received from cow " +commandingMsg.name + " with ID "+ commandingMsg.animalID);			 			    
		    JOptionPane.showMessageDialog(frame,"Buzzer alert received from cow " +commandingMsg.name + " with ID "+ commandingMsg.animalID+"\n Buzzer is running...");
		}
		if(commandingMsg.tranquilizerActive==1) {
			System.out.println("Tranquilizer alert received from animal " + commandingMsg.animalID);
		    JOptionPane.showMessageDialog(frame,"Tranquilizer alert received from cow " +commandingMsg.name + " with ID "+ commandingMsg.animalID+"\n Injecting tranquilizer...");

		}
		
	}
	
	
	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
	    // TODO Auto-generated method stub
	
	}
	
	
	public static void main(String[] args) {
	    new MQTTClient().doDemo();
	}

}
