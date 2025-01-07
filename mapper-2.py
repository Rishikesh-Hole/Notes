import json
import os
from typing import Dict, Any, TypedDict

class EventMessage(TypedDict):
    name: str
    businessDate: str
    additionalData: Dict[str, Any]

def validate_event(event: Dict[str, Any]) -> EventMessage:
    """
    Validate the event structure and return it as a typed EventMessage.

    :param event: The raw event object.
    :return: Validated and typed event object.
    """
    if not isinstance(event.get("name"), str):
        raise ValueError("Event must have a 'name' key of type string.")
    if not isinstance(event.get("businessDate"), str):
        raise ValueError("Event must have a 'businessDate' key of type string.")
    if not isinstance(event.get("additionalData"), dict):
        raise ValueError("Event must have an 'additionalData' key of type dictionary.")

    return event  # Return as is, since validation is complete.

def process_event(event: Dict[str, Any], json_mapping_path: str) -> Dict[str, Any]:
    """
    Process an event using the mapping JSON file to enrich the event data.

    :param event: The event object containing `name`, `businessDate`, and `additionalData`.
    :param json_mapping_path: Path to the JSON mapping file.
    :return: Processed event with enriched data.
    """
    # Validate the event structure
    event = validate_event(event)

    # Load the JSON mapping file
    if not os.path.exists(json_mapping_path):
        raise FileNotFoundError(f"Mapping file not found: {json_mapping_path}")

    with open(json_mapping_path, 'r') as file:
        mappings = json.load(file)

    # Find the matching mapping
    matching_mapping = next((m for m in mappings if m.get('expected_input_event_name') == event.get('name')), None)

    if not matching_mapping:
        raise ValueError(f"No matching mapping found for event name: {event.get('name')}")

    # Construct the final output
    output = {
        "businessDate": event.get("businessDate"),
        "additionalData": {
            **event.get("additionalData", {}),
            "workflowID": matching_mapping.get("workflowID"),
            "workflowVersion": matching_mapping.get("workflowVersion"),
            "workflowName": matching_mapping.get("workflowName"),
        }
    }

    return output

# Example usage
def main():
    # Simulate incoming Kafka message
    msg = type("KafkaMessage", (object,), {"value": lambda: b'{"name": "eventName1", "businessDate": "2025-01-07", "additionalData": {"key1": "value1", "key2": "value2"}}'})()
    event_message = json.loads(msg.value().decode('utf-8'))

    # Path to the JSON mapping file
    json_mapping_path = "mapping.json"

    try:
        # Process the event
        processed_event = process_event(event_message, json_mapping_path)
        print("Processed Event:", json.dumps(processed_event, indent=4))
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
