# Service Bus Guidelines

This document provides information about how we use Service Bus.

## Use Topics Over Queues

- Topics MUST be used for pub/sub scenarios.
- Queues SHOULD NOT be used because they cannot be easily tested in multiple-consumer scenarios and do not follow the Open-Closed Principle (OCP).

## State and Events

- We have exactly two types of topics: **state** and **events**.
- **State topics** are named after the entity in plural (e.g., `Orders`).
- **Events topics** are named after the event type in plural (e.g., `OrderEvents`).
- **State topic schemas** SHOULD be named after the entity in plural with a version suffix (e.g., `Orders_V1.yaml`).
- **Event topic schemas** SHOULD be named after the event type in plural with a version suffix (e.g., `OrderEvents_V1.yaml`).
- All schema files MUST have the `_V{version}` suffix.

## Publishing

- `SessionId` and `PartitionKey` SHOULD be set to the ID of the entity.

## Schemas

- The entity's ID SHOULD be replicated inside the message body.

## Events Schema

- Event schemas SHOULD have each event type as an optional property. This makes the schema easier to evolve.

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



