// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

enum 264 "Intrastat Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    value(0; "") { Caption = ''; }
    value(1; "Item Entry") { Caption = 'Item Entry'; }
    value(2; "Job Entry") { Caption = 'Job Entry'; }
}
