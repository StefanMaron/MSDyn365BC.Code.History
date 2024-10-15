﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

enum 124 "Sales Document IC Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "New") { Caption = 'New'; }
    value(1; "Pending") { Caption = 'Pending'; }
    value(2; "Sent") { Caption = 'Sent'; }
}
