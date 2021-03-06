# frozen_string_literal: true

APISchemas["v1/notes.yaml"][:rfc7807] = {
  description: "Schema for rfc7807 (errors)",
  properties: {

    type: {
      description: "A URI reference [RFC3986] that identifies the problem type.",
      type: "string",
      format: "uri"
    },
    title: {
      description: "A short, human-readable summary of the problem type.",
      type: "string"
    },
    status: {
      description: "The HTTP status code ([RFC7231], Section 6) generated by the origin server for this occurrence of the problem.",
      type: "number"
    },
    instance: {
      description: "A URI reference that identifies the specific occurrence of the problem.",
      type: "string"
    },
    detail: {
      description: "A human-readable explanation specific to this occurrence of the problem.",
      type: "string"
    }
  },
  required: %w[type]
}
