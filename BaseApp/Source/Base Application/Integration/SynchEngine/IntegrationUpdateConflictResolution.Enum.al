// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

enum 5338 "Integration Update Conflict Resolution"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = ' '; }
    value(1; "Send Update to Integration") { Caption = 'Send data update to integration table'; }
    value(2; "Get Update from Integration") { Caption = 'Get data update from integration table'; }
}