﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

table 10687 "VAT Specification"
{
    Caption = 'VAT Code';
    LookupPageID = "VAT Specifications";

    fields
    {
        field(1; "Code"; Code[50])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "VAT Report Value"; Text[250])
        {
            Caption = 'VAT Report Value';
        }
    }
}
