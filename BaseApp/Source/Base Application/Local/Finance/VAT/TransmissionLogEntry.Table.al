// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11012 "Transmission Log Entry"
{
    Caption = 'Transmission Log Entry';
    ReplicateData = false;
    ObsoleteReason = 'Moved to Elster extension, new table Elster Transm. Log Entry.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Sales VAT Adv. Notif. No."; Code[20])
        {
            Caption = 'Sales VAT Adv. Notif. No.';
        }
        field(3; "Transmission Date"; Date)
        {
            Caption = 'Transmission Date';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(5; "Return Code"; Code[20])
        {
            Caption = 'Return Code';
        }
        field(6; "Return Text"; Text[250])
        {
            Caption = 'Return Text';
            Editable = false;
        }
        field(7; "Transmission successful"; Boolean)
        {
            Caption = 'Transmission successful';
        }
        field(8; "XML Response Document"; BLOB)
        {
            Caption = 'XML Response Document';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Sales VAT Adv. Notif. No.")
        {
        }
    }

    fieldgroups
    {
    }
}

