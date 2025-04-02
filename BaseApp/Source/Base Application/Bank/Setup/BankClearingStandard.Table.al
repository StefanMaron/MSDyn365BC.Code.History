// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

table 1280 "Bank Clearing Standard"
{
    Caption = 'Bank Clearing Standard';
    LookupPageID = "Bank Clearing Standards";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Text[50])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

