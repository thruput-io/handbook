# This document

Provides information about how we use Service Bus.

## Only topics

- Topics are used for pub/sub scenarios.
- Queues cannot be tested and do not follow Open-Closed Principle (OCP)

## State and Events

- We have exactly to types of topics: state and events.
- State topics are named after the entity in plural Orders.
- Events topics are named after the event in plural OrderEvents.
- Schema for state topcis should be named after the entity in plural Orders_V1.yaml
- Schema for events topics should be named after the event in plural OrderEvents_V1.yaml
- Schema files should have the _V{version} suffix.

## Events schema
Event schemas should have each event type as an optional property. That makes the schema easy to evolve.
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://international.com/schemas/PaymentEvents.schema.json",
  "title": "PaymentEvents",
  "type": "object",
  "properties": {
    "created": {
      "$ref": "#/definitions/PaymentCreated"
    },
    "deleted": {
      "$ref": "#/definitions/PaymentDeleted"
    }
  },
  "definitions": {
    "PlanId": {
      "type": "string",
      "format": "uuid",
      "description": "Payment plan id"
    },
    "Invoice": {
      "type": "object",
      "required": [
        "invoiceNumber",
        "dueDate"
      ],
      "properties": {
        "invoiceNumber": {
          "type": "string",
          "minLength": 3
        },
        "dueDate": {
          "type": "string",
          "format": "date"
        }
      }
    },
    "PaymentCreated": {
      "required": [
        "planId",
        "invoices"
      ],
      "properties": {
        "planId": {
          "$ref": "#/definitions/PlanId"
        },
        "invoices": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Invoice"
          },
          "minItems": 1,
          "uniqueItems": true,
          "description": "List of invoices that are overdue"
        }
      }
    },
    "PaymentDeleted": {
      "required": [
        "planId",
        "contractNumber"
      ],
      "properties": {
        "planId": {
          "$ref": "#/definitions/PlanId"
        }
      }
    }
  }
}
```



