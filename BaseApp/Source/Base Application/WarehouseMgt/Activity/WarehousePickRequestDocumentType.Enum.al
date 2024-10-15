// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

enum 7325 "Warehouse Pick Request Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Shipment") { Caption = 'Shipment'; }
    value(1; "Internal Pick") { Caption = 'Internal Pick'; }
    value(2; "Production") { Caption = 'Production'; }
    value(3; "Assembly") { Caption = 'Assembly'; }
    value(4; "Job") { Caption = 'Job'; }
}
