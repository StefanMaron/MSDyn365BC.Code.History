#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

table 10900 "IRS Numbers"
{
    Caption = 'IRS Numbers';
    ObsoleteReason = 'Moved to the IS Core App.';
#if CLEAN24
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#else
    LookupPageID = "IRS Number";
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "IRS Number"; Code[10])
        {
            Caption = 'IRS Number';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Reverse Prefix"; Boolean)
        {
            Caption = 'Reverse Prefix';
        }
    }

    keys
    {
        key(Key1; "IRS Number")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "IRS Number", Name)
        {
        }
    }
} 
#endif
