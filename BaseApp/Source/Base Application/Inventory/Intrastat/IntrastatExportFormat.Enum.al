// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN22
namespace Microsoft.Inventory.Intrastat;

enum 263 "Intrastat Export Format"
{
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    Extensible = true;

    value(0; "2021")
    {
        Caption = '2021';
    }
    value(1; "2022")
    {
        Caption = '2022';
    }
}
#endif
