﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

#pragma warning disable AL0659
enum 7325 "Warehouse Pick Request Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Shipment") { Caption = 'Shipment'; }
    value(1; "Internal Pick") { Caption = 'Internal Pick'; }
    value(2; "Production") { Caption = 'Production'; }
    value(3; "Assembly") { Caption = 'Assembly'; }
    value(4; "Job") { Caption = 'Job'; }
}
