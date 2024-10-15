// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

enum 5337 "Integration Deletion Conflict Resolution"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = ' '; }
    value(1; "Restore Records") { Caption = 'Restore records'; }
    value(2; "Remove Coupling") { Caption = 'Delete coupling'; }
}