// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

enum 7324 "Warehouse Put-away Request Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Receipt") { Caption = 'Receipt'; }
    value(1; "Internal Put-away") { Caption = 'Internal Put-away'; }
}
