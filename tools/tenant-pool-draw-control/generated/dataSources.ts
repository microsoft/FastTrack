/*!
 * Copyright (C) Microsoft Corporation. All rights reserved.
 * This file is auto-generated. Do not modify it manually.
 * Changes to this file may be overwritten.
 */

export default {
  "powerplatformadminv2": {
    "tableId": "",
    "version": "",
    "primaryKey": "",
    "dataSourceType": "Connector",
    "apis": {
      "InvokeAdvisorMCP": {
        "path": "/{connectionId}/analytics/mcp/Advisor",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "Mcp-Session-Id",
            "in": "header",
            "required": false,
            "type": "string"
          },
          {
            "name": "queryRequest",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "202": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "ExecuteRecommendationAction": {
        "path": "/{connectionId}/analytics/actions/{actionName}",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          },
          {
            "name": "actionName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetRecommendations": {
        "path": "/{connectionId}/analytics/advisorRecommendations",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$skipToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetRecommendationResources": {
        "path": "/{connectionId}/analytics/advisorRecommendations/{scenario}/resources",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "scenario",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$skipToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetTenantApplicationPackage": {
        "path": "/{connectionId}/appmanagement/applicationPackages",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentApplicationPackage": {
        "path": "/{connectionId}/appmanagement/environments/{environmentId}/applicationPackages",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "appInstallState",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "lcid",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "InstallApplicationPackage": {
        "path": "/{connectionId}/appmanagement/environments/{environmentId}/applicationPackages/{uniqueName}/install",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "uniqueName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "202": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetApplicationPackageInstallStatus": {
        "path": "/{connectionId}/appmanagement/environments/{environmentId}/operations/{operationId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "operationId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "ListEnvironmentGroupRoleAssignments": {
        "path": "/{connectionId}/authorization/environmentGroups/{environmentGroupId}/roleAssignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentGroupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "CreateEnvironmentGroupRoleAssignment": {
        "path": "/{connectionId}/authorization/environmentGroups/{environmentGroupId}/roleAssignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentGroupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeleteEnvironmentGroupRoleAssignment": {
        "path": "/{connectionId}/authorization/environmentGroups/{environmentGroupId}/roleAssignments/{roleAssignmentId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentGroupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "roleAssignmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "SearchEnvironmentRoleAssignments": {
        "path": "/{connectionId}/authorization/environments/{environmentId}/listRoleAssignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListEnvironmentRoleAssignments": {
        "path": "/{connectionId}/authorization/environments/{environmentId}/roleAssignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "CreateEnvironmentRoleAssignment": {
        "path": "/{connectionId}/authorization/environments/{environmentId}/roleAssignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeleteEnvironmentRoleAssignment": {
        "path": "/{connectionId}/authorization/environments/{environmentId}/roleAssignments/{roleAssignmentId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "roleAssignmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "SearchRoleAssignments": {
        "path": "/{connectionId}/authorization/listRoleAssignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRoleAssignments": {
        "path": "/{connectionId}/authorization/roleAssignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "CreateRoleAssignment": {
        "path": "/{connectionId}/authorization/roleAssignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeleteRoleAssignment": {
        "path": "/{connectionId}/authorization/roleAssignments/{roleAssignmentId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "roleAssignmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRoleDefinitions": {
        "path": "/{connectionId}/authorization/roleDefinitions",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListConnections": {
        "path": "/{connectionId}/connectivity/environments/{environmentId}/connections",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "ListConnectors": {
        "path": "/{connectionId}/connectivity/environments/{environmentId}/connectors",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "GetConnectorById": {
        "path": "/{connectionId}/connectivity/environments/{environmentId}/connectors/{connectorId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "connectorId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "DownloadAgentChannelManifest": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/agents/{AgentId}/channels/{ChannelName}/download",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "AgentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "ChannelName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "includeAgentSchema",
            "in": "query",
            "required": false,
            "type": "boolean"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "string",
            "format": "binary"
          }
        }
      },
      "DeleteCopilotAgent": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botAdminOperations",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          }
        }
      },
      "ReassignCopilotAgent": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botAdminOperations/reassign",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetBotQuarantineStatus": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botQuarantine",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "SetBotAsQuarantined": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botQuarantine/SetAsQuarantined",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "SetBotAsUnquarantined": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botQuarantine/SetAsUnquarantined",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "GetConnectorConsentBypass": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/connectorConsentBypass",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "SetConnectorConsentBypass": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/connectorConsentBypass",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "ListMakerEvaluationTestRuns": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/makerevaluation/testruns",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "GetMakerEvaluationTestRun": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/makerevaluation/testruns/{TestRunId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "TestRunId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "DownloadMakerEvaluationSnapshot": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/makerevaluation/testruns/{TestRunId}/snapshot",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "TestRunId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "string",
            "format": "binary"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "ListMakerEvaluationTestSets": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/makerevaluation/testsets",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "GetMakerEvaluationTestSet": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/makerevaluation/testsets/{TestSetId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "TestSetId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "RunMakerEvaluationTestSet": {
        "path": "/{connectionId}/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/makerevaluation/testsets/{TestSetId}/run",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "EnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "BotId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "TestSetId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GenerateLicensingReport": {
        "path": "/{connectionId}/copilotstudio/licensing/reports/{ReportName}",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "ReportName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "DownloadLicensingReportFile": {
        "path": "/{connectionId}/copilotstudio/licensing/reports/{ReportName}/files/{FileName}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "ReportName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "FileName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "string",
            "format": "binary"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetLicensingReportOperation": {
        "path": "/{connectionId}/copilotstudio/licensing/reports/{ReportName}/operations/{OperationId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "ReportName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "OperationId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetFinOpsMaintenanceSettings": {
        "path": "/{connectionId}/dynamics/environments/{environmentId}/finopsadminsettings",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "UpdateFinOpsMaintenanceSettings": {
        "path": "/{connectionId}/dynamics/environments/{environmentId}/finopsadminsettings",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "GetFinOpsProperties": {
        "path": "/{connectionId}/dynamics/environments/{environmentId}/finopsproperties",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "GetFinOpsVersions": {
        "path": "/{connectionId}/dynamics/environments/{environmentId}/finopsversions",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "ApplyFinOpsVersion": {
        "path": "/{connectionId}/dynamics/environments/{environmentId}/finopsversions/{version}/apply",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "version",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "GetFinOpsOperationErrors": {
        "path": "/{connectionId}/dynamics/environments/{environmentId}/operationerrors",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "maxResults",
            "in": "query",
            "required": false,
            "type": "integer"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "CreateEnvironmentManagementSettings": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/settings",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "409": {
            "type": "object"
          }
        }
      },
      "ListEnvironmentManagementSettings": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/settings",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "$select",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "429": {
            "type": "object"
          }
        }
      },
      "UpdateEnvironmentManagementSettings": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/settings",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "409": {
            "type": "object"
          },
          "412": {
            "type": "object"
          }
        }
      },
      "CreateEnvironmentBackup": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/backups",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentBackups": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/backups",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "DeleteEnvironmentBackup": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/backups/{backupId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "backupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetBusinessContinuityStateFullSnapshot": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/businessContinuityStateFullSnapshot",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "DisableDisasterRecovery": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/disableDisasterRecovery",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "PerformDRDrill": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/disasterRecoveryDrill",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "EnableDisasterRecovery": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/enableDisasterRecovery",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "PerformFailback": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/failback",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "PerformForceFailover": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/forceFailover",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "DisableManagedEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/governanceSetting/disableManaged",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "EnableManagedEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/governanceSetting/enableManaged",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "ModifyEnvironmentSku": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/modifySku",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetOperationsForEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/operations",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "limit",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "RecoverEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/recover",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "ResetEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}/reset",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentCopyCandidates": {
        "path": "/{connectionId}/environmentmanagement/environments/{sourceEnvironmentId}/copyCandidates",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "sourceEnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetRestoreCandidates": {
        "path": "/{connectionId}/environmentmanagement/environments/{sourceEnvironmentId}/restoreCandidates",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "sourceEnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "CopyEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{targetEnvironmentId}/copy",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "targetEnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentOperationByID": {
        "path": "/{connectionId}/environmentmanagement/environments/{targetEnvironmentId}/operations/{operationId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "targetEnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "operationId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "RestoreEnvironment": {
        "path": "/{connectionId}/environmentmanagement/environments/{targetEnvironmentId}/restore",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "targetEnvironmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetOperationByID": {
        "path": "/{connectionId}/environmentmanagement/operations/{operationId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "operationId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "ProvisionNewEnvironment": {
        "path": "/{connectionId}/environmentmanagement/provisioning/environments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "LinkDataverse": {
        "path": "/{connectionId}/environmentmanagement/provisioning/environments/{environmentId}/link",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetSupportedLocations": {
        "path": "/{connectionId}/environmentmanagement/provisioning/locations",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetProvisioningCurrencies": {
        "path": "/{connectionId}/environmentmanagement/provisioning/locations/{location}/currencies",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "location",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetProvisioningLanguages": {
        "path": "/{connectionId}/environmentmanagement/provisioning/locations/{location}/languages",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "location",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetProvisioningTemplates": {
        "path": "/{connectionId}/environmentmanagement/provisioning/locations/{location}/templates",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "location",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentGroupOperation": {
        "path": "/{connectionId}/environmentmanagement/environmentGroupOperations/{operationId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "operationId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "CreateEnvironmentGroup": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "ListEnvironmentGroups": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "GetEnvironmentGroup": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups/{groupId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "UpdateEnvironmentGroup": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups/{groupId}",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "DeleteEnvironmentGroup": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups/{groupId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "AddEnvironmentToGroup": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups/{groupId}/addEnvironment/{environmentId}",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "RemoveEnvironmentFromGroup": {
        "path": "/{connectionId}/environmentmanagement/environmentGroups/{groupId}/removeEnvironment/{environmentId}",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          }
        }
      },
      "ListEnvironmentsForUser": {
        "path": "/{connectionId}/environmentmanagement/environments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "$select",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "$skip",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "$orderby",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "GetEnvironmentByIdForUser": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$select",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "DeleteEnvironmentByID": {
        "path": "/{connectionId}/environmentmanagement/environments/{environmentId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ValidateOnly",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "ValidateProperties",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "409": {
            "type": "object"
          },
          "429": {
            "type": "void"
          }
        }
      },
      "CreateRuleBasedPolicy": {
        "path": "/{connectionId}/governance/ruleBasedPolicies",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRuleBasedPolicies": {
        "path": "/{connectionId}/governance/ruleBasedPolicies",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetRuleBasedPolicyByID": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "UpdateRuleBasedPolicyByID": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "PatchRuleBasedPolicy": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRuleAssignmentsByPolicyId": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}/assignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "includeRuleSetCounts",
            "in": "query",
            "required": true,
            "type": "boolean"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "CreateEnviornmentGroupRuleBasedAssignment": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}/environmentGroups/{groupId}/assignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "CreateEnvironmentRuleBasedAssignment": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}/environments/{environmentId}/assignments",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "RemoveRuleFromRuleBasedPolicy": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/{policyId}/removeRule",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "policyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRuleAssignments": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/assignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "includeRuleSetCounts",
            "in": "query",
            "required": true,
            "type": "boolean"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRuleAssignmentsByEnvironmentGroupId": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/environmentGroups/{environmentGroupId}/assignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentGroupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "includeRuleSetCounts",
            "in": "query",
            "required": true,
            "type": "boolean"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListRuleAssignmentsByEnvironmentId": {
        "path": "/{connectionId}/governance/ruleBasedPolicies/environments/{environmentId}/assignments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "includeRuleSetCounts",
            "in": "query",
            "required": true,
            "type": "boolean"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetRuleSet": {
        "path": "/{connectionId}/governance/environmentGroups/{groupId}/ruleSets",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "CreateRuleSet": {
        "path": "/{connectionId}/governance/environmentGroups/{groupId}/ruleSets",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "groupId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "GetRuleSetListForTenant": {
        "path": "/{connectionId}/governance/ruleSets",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$select",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "$expand",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "$skiptoken",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "integer"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "UpdateRuleSet": {
        "path": "/{connectionId}/governance/ruleSets/{ruleSetId}",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "ruleSetId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "DeleteRuleSet": {
        "path": "/{connectionId}/governance/ruleSets/{ruleSetId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "ruleSetId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "500": {
            "type": "object"
          }
        }
      },
      "ListCrossTenantConnectionReports": {
        "path": "/{connectionId}/governance/crossTenantConnectionReports",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "CreateCrossTenantConnectionReport": {
        "path": "/{connectionId}/governance/crossTenantConnectionReports",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "202": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetCrossTenantConnectionReport": {
        "path": "/{connectionId}/governance/crossTenantConnectionReports/{reportId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "reportId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "PutAllocationsV2": {
        "path": "/{connectionId}/licensing/allocationsV2",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetAllocationsAvailabilityV2": {
        "path": "/{connectionId}/licensing/allocationsV2/availability",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetManyEntitlementsReservedV2": {
        "path": "/{connectionId}/licensing/allocationsV2/entitlements/reserved",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetEntitlement": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentResources": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/environments/{environmentId}/resources",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "fromDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "toDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "searchRequest",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "includeFields",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "orderbyConsumed",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetTenantLicenseTrends": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/licenses",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "fromDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "toDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetTenantResourcesAcrossEnvironments": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/resources",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "fromDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "toDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetTenantUserConsumptionByResource": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/resources/{resourceId}/users",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "resourceId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "fromDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "toDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "searchRequest",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetAllResourceThresholds": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/resourceThresholds",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetTenantUsers": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/users",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "fromDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "toDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "searchRequest",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "orderbyConsumed",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetTenantResourceConsumptionByUser": {
        "path": "/{connectionId}/licensing/entitlements/{entitlementId}/users/{userId}/resources",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "userId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "fromDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "toDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "searchRequest",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetManyEnvironmentEntitlements": {
        "path": "/{connectionId}/licensing/environments/{environmentId}/entitlements",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$filter",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "UpsertResourceThreshold": {
        "path": "/{connectionId}/licensing/environments/{environmentId}/entitlements/{entitlementId}/resources/{resourceId}/threshold",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entitlementId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "resourceId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetFinOpsLicenseSummaryV2": {
        "path": "/{connectionId}/licensing/FinOpsLicensing/GetLicenseSummaryV2",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "ListAllocationsByEnvironment": {
        "path": "/{connectionId}/licensing/allocationsByEnvironment",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "UpdateAllocationsByEnvironment": {
        "path": "/{connectionId}/licensing/allocationsByEnvironment",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetAllocationsByEnvironment": {
        "path": "/{connectionId}/licensing/allocationsByEnvironment/{environmentId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "ListBillingPolicies": {
        "path": "/{connectionId}/licensing/billingPolicies",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "CreateBillingPolicy": {
        "path": "/{connectionId}/licensing/billingPolicies",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetBillingPolicy": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "UpdateBillingPolicy": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "DeleteBillingPolicy": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "ListBillingPolicyEnvironments": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}/environments",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetBillingPolicyEnvironment": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}/environments/{environmentId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "AddBillingPolicyEnvironment": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}/environments/add",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "RemoveBillingPolicyEnvironment": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}/environments/remove",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "RefreshProvisioningStatus": {
        "path": "/{connectionId}/licensing/billingPolicies/{billingPolicyId}/refreshProvisioningStatus",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "billingPolicyId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetCurrencyAllocationByEnvironment": {
        "path": "/{connectionId}/licensing/environments/{environmentId}/allocations",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "PatchCurrencyAllocationByEnvironment": {
        "path": "/{connectionId}/licensing/environments/{environmentId}/allocations",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetEnvironmentBillingPolicy": {
        "path": "/{connectionId}/licensing/environments/{environmentId}/billingPolicy",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "ListISVContracts": {
        "path": "/{connectionId}/licensing/isvContracts",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "CreateISVContract": {
        "path": "/{connectionId}/licensing/isvContracts",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "201": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          }
        }
      },
      "GetISVContract": {
        "path": "/{connectionId}/licensing/isvContracts/{isvContractId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "isvContractId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "UpdateISVContract": {
        "path": "/{connectionId}/licensing/isvContracts/{isvContractId}",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "isvContractId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": false,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "DeleteISVContract": {
        "path": "/{connectionId}/licensing/isvContracts/{isvContractId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "isvContractId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "GetStorageWarningByCategory": {
        "path": "/{connectionId}/licensing/storageWarning/{storageCategory}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "storageCategory",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetStorageWarningByCategoryAndEntity": {
        "path": "/{connectionId}/licensing/storageWarning/{storageCategory}/{entityName}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "storageCategory",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "entityName",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "ListStorageWarnings": {
        "path": "/{connectionId}/licensing/storageWarning/getAllStorageWarnings",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "RetrieveTemporaryCurrencyEntitlementCount": {
        "path": "/{connectionId}/licensing/TemporaryCurrencyEntitlement/{currencyType}/Count",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "currencyType",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "array"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetTenantCapacityDetails": {
        "path": "/{connectionId}/licensing/tenantCapacity",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "404": {
            "type": "void"
          }
        }
      },
      "ListCurrencyReports": {
        "path": "/{connectionId}/licensing/tenantCapacity/currencyReports",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "includeAllocations",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "includeConsumptions",
            "in": "query",
            "required": false,
            "type": "boolean"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          }
        }
      },
      "GetUserPerFlowCapacitySource": {
        "path": "/{connectionId}/licensing/UserPerFlowCapacitySource",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "startDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "endDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "pageNumber",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "userId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "flowContext",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "flowLicenseCategorization",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "resourceId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetUserPerFlowCapacitySourceFlowContextSummary": {
        "path": "/{connectionId}/licensing/UserPerFlowCapacitySource/FlowContextSummary",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "startDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "endDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "pageNumber",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "environmentId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetUserPerFlowCapacitySourceFlowContextSummaryForUserId": {
        "path": "/{connectionId}/licensing/UserPerFlowCapacitySource/FlowContextSummary/{userId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "userId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "startDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "endDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "pageNumber",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "environmentId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetUserPerFlowCapacitySourceTenantContextSummary": {
        "path": "/{connectionId}/licensing/UserPerFlowCapacitySource/TenantContextSummary",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "startDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "endDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetUserPerFlowCapacitySourceUserContextSummary": {
        "path": "/{connectionId}/licensing/UserPerFlowCapacitySource/UserContextSummary",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "startDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "endDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "pageNumber",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "environmentId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetUserPerFlowCapacitySourceUserContextSummaryForUserId": {
        "path": "/{connectionId}/licensing/UserPerFlowCapacitySource/UserContextSummary/{userId}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "userId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "startDate",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "endDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "pageNumber",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "pageSize",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "environmentId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "OnAlertTriggered": {
        "path": "/{connectionId}/monitoringhub/powerplatform/triggeredAlerts/poll",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "cursor",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "202": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "429": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "Get-AdminApps": {
        "path": "/{connectionId}/powerapps/environments/{environmentId}/apps",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "$top",
            "in": "query",
            "required": false,
            "type": "integer"
          },
          {
            "name": "$skiptoken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "default": {
            "type": "void"
          }
        }
      },
      "Get-AdminApp": {
        "path": "/{connectionId}/powerapps/environments/{environmentId}/apps/{app}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "app",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          }
        }
      },
      "ListCloudFlows": {
        "path": "/{connectionId}/powerautomate/environments/{environmentId}/cloudFlows",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "workflowId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "resourceId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "createdBy",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "ownerId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "createdOnStartDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "createdOnEndDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "modifiedOnStartDate",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "modifiedOnEndDate",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListFlowActions": {
        "path": "/{connectionId}/powerautomate/environments/{environmentId}/flowActions",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "workflowId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "parentProcessStageId",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "connector",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "isTrigger",
            "in": "query",
            "required": false,
            "type": "boolean"
          },
          {
            "name": "parameterName",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "parameterValue",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "exact",
            "in": "query",
            "required": false,
            "type": "boolean"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ListFlowRuns": {
        "path": "/{connectionId}/powerautomate/environments/{environmentId}/flowRuns",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "workflowId",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "object"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetAffectedSites": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/exceptions/affectedSites",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "exceptionType",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GrantException": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/exceptions/grant",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "403": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetExceptions": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/exceptions/list",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "exceptionType",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "RevokeException": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/exceptions/revoke",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetWebsites": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "skip",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          }
        }
      },
      "CreateWebsite": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetWebsiteById": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "DeleteWebsite": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "Operation-Location",
            "in": "header",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "UploadCertificate": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/certificates",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "certType",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "file",
            "in": "formData",
            "required": false,
            "type": "file"
          },
          {
            "name": "password",
            "in": "formData",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "string"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetCertificatesByPortal": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/certificates",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "certType",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "DeleteCertificateByPortal": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/certificates",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "thumbprint",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "certType",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "ConvertTrialToProduction": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/convertToProduction",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "CreateWafRules": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/createWafRules",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "ListHostNamesForPortal": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/customDomain",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "CreateCustomDomain": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/customDomain",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "customDomain",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "DeleteHostNameForPortal": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/customDomain",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "hostName",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "DeleteWafCustomRules": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/deleteWafCustomRules",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "array"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "DisableWaf": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/disableWaf",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "string"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "EnableWAF": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/enableWaf",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          },
          "409": {
            "type": "object"
          }
        }
      },
      "GetWAFRules": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/getWafRules",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "ruleType",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetWAFStatus": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/getWafStatus",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "string"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetAllowedIpAddresses": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/ipaddressrules",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "AddAllowedIpAddresses": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/ipaddressrules",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "RemoveAllowedIpAddresses": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/removeAllowedIpAddresses",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "RestartWebsite": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/restart",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetSecurityScanReport": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/scan/deep/getLatestCompletedReport",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "GetSecurityScanScore": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/scan/deep/getSecurityScore",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "StartDeepScan": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/scan/deep/start",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "202": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "StartQuickScan": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/scan/quick/execute",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "lcid",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "SetPortalBootstrapV5Enabled": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/SetPortalBootstrapV5Enabled",
        "method": "PATCH",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "SetPortalDataModelVersion": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/setPortalDataModelVersion",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "ListSslBindingsByThumbprints": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/sslBindings",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "hostName",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "array"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "AddSslBindingByPortal": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/sslBindings",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "thumbprint",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "hostName",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "DeleteSslBindingByThumbprint": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/sslBindings",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "hostName",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "thumbprint",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "StartWebsite": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/start",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "StopWebsite": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/stop",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "ToggleAFDTrafficRouting": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/toggleAFDTrafficRouting",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "enableAFD",
            "in": "query",
            "required": true,
            "type": "boolean"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "UpdatePortalSecurityGroup": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/updatePortalSecurityGroup",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "securityGroupId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "UpdateSiteVisibility": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/updateSiteVisibility",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "siteVisibility",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "UpdateWafPolicySettings": {
        "path": "/{connectionId}/powerpages/environments/{environmentId}/websites/{id}/updateWafPolicySettings",
        "method": "PUT",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "object"
          },
          "401": {
            "type": "object"
          },
          "404": {
            "type": "object"
          }
        }
      },
      "QueryResources": {
        "path": "/{connectionId}/resourcequery/resources/query",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "type": "object"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "429": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "ApplyAdminRole": {
        "path": "/{connectionId}/usermanagement/environments/{environmentId}/user/applyAdminRole",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "void"
          }
        }
      },
      "GetFlowRunActionsForDsr": {
        "path": "/{connectionId}/workflowsagent/aiFlows/{aiFlowId}/runs/{runId}/actions",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "aiFlowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "runId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "integer"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetApprovals": {
        "path": "/{connectionId}/workflowsagent/approvals",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeleteApproval": {
        "path": "/{connectionId}/workflowsagent/approvals/{approvalId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "approvalId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetConnections": {
        "path": "/{connectionId}/workflowsagent/connections",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeleteConnection": {
        "path": "/{connectionId}/workflowsagent/connections/{connectionIdentifier}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "connectionIdentifier",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetConversationTranscriptsForDsr": {
        "path": "/{connectionId}/workflowsagent/conversationTranscripts",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetFlowRunActionsWithEnvironment": {
        "path": "/{connectionId}/workflowsagent/environments/{environmentId}/aiFlows/{aiFlowId}/runs/{runId}/actions",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "aiFlowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "runId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "integer"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetConversationTranscriptsWithEnvironment": {
        "path": "/{connectionId}/workflowsagent/environments/{environmentId}/conversationTranscripts",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "401": {
            "type": "void"
          },
          "403": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetFlowRunsNonSingleton": {
        "path": "/{connectionId}/workflowsagent/environments/{environmentId}/flows/{flowId}/flowRuns",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "flowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetRunHistoryDataNonSingleton": {
        "path": "/{connectionId}/workflowsagent/environments/{environmentId}/flows/{flowId}/runs/{runId}/runHistoryData",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "environmentId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "flowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "runId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetFlows": {
        "path": "/{connectionId}/workflowsagent/flows",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeleteFlow": {
        "path": "/{connectionId}/workflowsagent/flows/{flowId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "flowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetFlowRunsSingleton": {
        "path": "/{connectionId}/workflowsagent/flows/{flowId}/flowRuns",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "flowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetRunHistoryData": {
        "path": "/{connectionId}/workflowsagent/flows/{flowId}/runs/{runId}/runHistoryData",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "flowId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "runId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "GetPrompts": {
        "path": "/{connectionId}/workflowsagent/prompts",
        "method": "GET",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          },
          {
            "name": "continuationToken",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "DeletePrompt": {
        "path": "/{connectionId}/workflowsagent/prompts/{promptId}",
        "method": "DELETE",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "promptId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "api-version",
            "in": "query",
            "required": true,
            "type": "string"
          }
        ],
        "responseInfo": {
          "204": {
            "type": "void"
          },
          "400": {
            "type": "void"
          },
          "401": {
            "type": "void"
          },
          "404": {
            "type": "void"
          },
          "500": {
            "type": "void"
          }
        }
      },
      "mcp_EnvironmentManagement": {
        "path": "/{connectionId}/mcp/EnvironmentManagement",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "queryRequest",
            "in": "body",
            "required": false,
            "type": "object"
          },
          {
            "name": "sessionId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "default": {
            "type": "void"
          }
        }
      },
      "mcp_Governance": {
        "path": "/{connectionId}/mcp/Governance",
        "method": "POST",
        "parameters": [
          {
            "name": "connectionId",
            "in": "path",
            "required": true,
            "type": "string"
          },
          {
            "name": "queryRequest",
            "in": "body",
            "required": false,
            "type": "object"
          },
          {
            "name": "sessionId",
            "in": "query",
            "required": false,
            "type": "string"
          }
        ],
        "responseInfo": {
          "200": {
            "type": "object"
          },
          "default": {
            "type": "void"
          }
        }
      }
    }
  }
};
