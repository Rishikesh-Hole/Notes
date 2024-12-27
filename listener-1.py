# module: akv_auth.py
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AKVAuth:
    def __init__(self, akv_url, secret_names):
        """
        Initialize the AKVAuth class.

        :param akv_url: URL of the Azure Key Vault.
        :param secret_names: Dictionary containing secret names for Kafka authentication.
        """
        self.akv_url = akv_url
        self.secret_names = secret_names

        # Create Azure Key Vault client
        self.credential = DefaultAzureCredential()
        self.secret_client = SecretClient(vault_url=self.akv_url, credential=self.credential)

    def get_kafka_credentials(self):
        """Fetch Kafka credentials from Azure Key Vault."""
        try:
            username = self.secret_client.get_secret(self.secret_names["username"]).value
            password = self.secret_client.get_secret(self.secret_names["password"]).value
            return username, password
        except Exception as e:
            logger.error(f"Error fetching Kafka credentials: {e}")
            raise

# module: kafka_consumer.py
from confluent_kafka import Consumer, KafkaException
from akv_auth import AKVAuth
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KafkaConsumerHandler:
    def __init__(self, akv_auth, kafka_broker_url, kafka_topic, kafka_group_id):
        """
        Initialize the KafkaConsumerHandler class.

        :param akv_auth: Instance of AKVAuth to fetch credentials.
        :param kafka_broker_url: Kafka broker URL.
        :param kafka_topic: Kafka topic to subscribe to.
        :param kafka_group_id: Kafka consumer group ID.
        """
        self.akv_auth = akv_auth
        self.kafka_broker_url = kafka_broker_url
        self.kafka_topic = kafka_topic
        self.kafka_group_id = kafka_group_id
        self.consumer = None

    def create_consumer(self):
        """Create a Kafka consumer with the fetched credentials."""
        try:
            username, password = self.akv_auth.get_kafka_credentials()
            consumer_config = {
                'bootstrap.servers': self.kafka_broker_url,
                'security.protocol': 'SASL_SSL',
                'sasl.mechanisms': 'PLAIN',
                'sasl.username': username,
                'sasl.password': password,
                'group.id': self.kafka_group_id,
                'auto.offset.reset': 'earliest'
            }
            self.consumer = Consumer(consumer_config)
            self.consumer.subscribe([self.kafka_topic])
        except Exception as e:
            logger.error(f"Error creating Kafka consumer: {e}")
            raise

    def listen_to_topic(self):
        """Listen to the Kafka topic and process events."""
        if not self.consumer:
            logger.error("Kafka consumer is not initialized.")
            return

        try:
            while True:
                msg = self.consumer.poll(1.0)  # Poll for new messages

                if msg is None:
                    continue  # No new message
                if msg.error():
                    if msg.error().code() == KafkaException._PARTITION_EOF:
                        logger.info(f"Reached end of partition for topic {msg.topic()}")
                    else:
                        logger.error(f"Kafka error: {msg.error()}")
                else:
                    # Process the message
                    logger.info(f"Received message: {msg.value().decode('utf-8')}")

        except Exception as e:
            logger.error(f"Error listening to Kafka topic: {e}")
        finally:
            self.consumer.close()

# module: listener.py
from akv_auth import AKVAuth
from kafka_consumer import KafkaConsumerHandler
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KafkaListener:
    def __init__(self, akv_url, secret_names, kafka_broker_url, kafka_topic, kafka_group_id):
        """
        Initialize the KafkaListener class.

        :param akv_url: URL of the Azure Key Vault.
        :param secret_names: Dictionary containing secret names for Kafka authentication.
        :param kafka_broker_url: Kafka broker URL.
        :param kafka_topic: Kafka topic to subscribe to.
        :param kafka_group_id: Kafka consumer group ID.
        """
        self.akv_auth = AKVAuth(akv_url, secret_names)
        self.kafka_handler = KafkaConsumerHandler(
            akv_auth=self.akv_auth,
            kafka_broker_url=kafka_broker_url,
            kafka_topic=kafka_topic,
            kafka_group_id=kafka_group_id
        )

    def start_listener(self):
        """Start the Kafka listener."""
        try:
            logger.info("Creating Kafka consumer...")
            self.kafka_handler.create_consumer()
            logger.info("Starting to listen to the Kafka topic...")
            self.kafka_handler.listen_to_topic()
        except Exception as e:
            logger.error(f"Error in KafkaListener: {e}")

if __name__ == "__main__":
    # Example usage
    akv_url = "https://<your-key-vault-name>.vault.azure.net/"
    secret_names = {
        "username": "kafka-username-secret",
        "password": "kafka-password-secret"
    }
    kafka_broker_url = "<kafka_broker_url>"
    kafka_topic = "your-kafka-topic"
    kafka_group_id = "your-consumer-group-id"

    listener = KafkaListener(akv_url, secret_names, kafka_broker_url, kafka_topic, kafka_group_id)
    listener.start_listener()
