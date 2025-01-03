# module: event_processor.py
import json
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EventProcessor:
    def __init__(self, mapping_file_path):
        """
        Initialize the EventProcessor class.

        :param mapping_file_path: Path to the JSON file containing event-to-DB workflow mappings.
        """
        self.mapping_file_path = mapping_file_path
        self.event_mappings = self._load_event_mappings()

    def _load_event_mappings(self):
        """Load event-to-DB workflow mappings from the JSON file."""
        try:
            with open(self.mapping_file_path, 'r') as file:
                mappings = json.load(file)
                logger.info("Event mappings loaded successfully.")
                return mappings
        except FileNotFoundError:
            logger.error(f"Mapping file not found at {self.mapping_file_path}")
            raise
        except json.JSONDecodeError:
            logger.error(f"Error decoding JSON file at {self.mapping_file_path}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error while loading mappings: {e}")
            raise

    def process_event_message(self, event_message):
        """
        Process the event message, adding the event-to-DB workflow mapping.

        :param event_message: Original event message as a dictionary.
        :return: Augmented event message with the workflow mapping added.
        """
        try:
            event_name = event_message.get("event_name")
            if not event_name:
                raise ValueError("Event message does not contain 'event_name' key.")

            workflow_mapping = self.event_mappings.get(event_name)
            if not workflow_mapping:
                logger.warning(f"No workflow mapping found for event '{event_name}'.")
                workflow_mapping = {}

            event_message["workflow_mapping"] = workflow_mapping
            return event_message
        except Exception as e:
            logger.error(f"Error processing event message: {e}")
            raise




===================================================================

# Updated kafka_consumer.py
from confluent_kafka import Consumer, KafkaException
import logging
from event_processor import EventProcessor

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for AKV configuration
akv_auth = None
secret_names = None

class KafkaConsumerHandler:
    def __init__(self, kafka_broker_url, kafka_topic, kafka_group_id, mapping_file_path):
        """
        Initialize the KafkaConsumerHandler class.

        :param kafka_broker_url: Kafka broker URL.
        :param kafka_topic: Kafka topic to subscribe to.
        :param kafka_group_id: Kafka consumer group ID.
        :param mapping_file_path: Path to the event-to-DB workflow mappings JSON file.
        """
        self.kafka_broker_url = kafka_broker_url
        self.kafka_topic = kafka_topic
        self.kafka_group_id = kafka_group_id
        self.mapping_file_path = mapping_file_path
        self.consumer = None
        self.event_processor = EventProcessor(mapping_file_path)

    def create_consumer(self):
        """Create a Kafka consumer with the fetched credentials."""
        try:
            username, password = akv_auth.get_kafka_credentials()
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
        except KafkaException as ke:
            logger.error(f"Kafka exception occurred: {ke}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error creating Kafka consumer: {e}")
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
                    # Decode and process the message
                    event_message = json.loads(msg.value().decode('utf-8'))
                    augmented_message = self.event_processor.process_event_message(event_message)
                    logger.info(f"Processed message: {augmented_message}")

        except KafkaException as ke:
            logger.error(f"Kafka runtime error: {ke}")
        except Exception as e:
            logger.error(f"Unexpected error listening to Kafka topic: {e}")
        finally:
            self.consumer.close()


======================================================

{
    "eventA": {"workflow": "workflowA"},
    "eventB": {"workflow": "workflowB"}
}



