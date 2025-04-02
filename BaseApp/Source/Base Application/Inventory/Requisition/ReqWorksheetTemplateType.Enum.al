// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

enum 247 "Req. Worksheet Template Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Req.") { Caption = 'Req.'; }
    value(1; "For. Labor") { Caption = 'For. Labor'; }
    value(2; "Planning") { Caption = 'Planning'; }
}
