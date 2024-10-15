﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

table 10902 "IRS Types"
{
    Caption = 'IRS Types';
    ObsoleteReason = 'Moved to the IS Core App.';
#if CLEAN24
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#else
    LookupPageID = "IRS Type";
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[4])
        {
            Caption = 'No.';
        }
        field(2; Type; Text[60])
        {
            Caption = 'Type';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}