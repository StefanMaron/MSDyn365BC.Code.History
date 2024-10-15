// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

table 2162 "O365 C2Graph Event Settings"
{
    Caption = 'O365 C2Graph Event Settings';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Inv. Sent Enabled"; Boolean)
        {
            Caption = 'Inv. Sent Enabled';
        }
        field(3; "Inv. Sent Event"; Integer)
        {
            Caption = 'Inv. Sent Event';
        }
        field(4; "Inv. Paid Enabled"; Boolean)
        {
            Caption = 'Inv. Paid Enabled';
        }
        field(5; "Inv. Paid Event"; Integer)
        {
            Caption = 'Inv. Paid Event';
        }
        field(6; "Inv. Draft Enabled"; Boolean)
        {
            Caption = 'Inv. Draft Enabled';
        }
        field(7; "Inv. Draft Duration (Day)"; Integer)
        {
            Caption = 'Inv. Draft Duration (Day)';
            InitValue = 1;
        }
        field(8; "Inv. Draft Event"; Integer)
        {
            Caption = 'Inv. Draft Event';
        }
        field(9; "Inv. Overdue Enabled"; Boolean)
        {
            Caption = 'Inv. Overdue Enabled';
        }
        field(10; "Inv. Overdue Event"; Integer)
        {
            Caption = 'Inv. Overdue Event';
        }
        field(11; "Inv. Inactivity Enabled"; Boolean)
        {
            Caption = 'Inv. Inactivity Enabled';
        }
        field(12; "Inv. Inactivity Duration (Day)"; Integer)
        {
            Caption = 'Inv. Inactivity Duration (Day)';
            InitValue = 7;
        }
        field(13; "Inv. Inactivity Event"; Integer)
        {
            Caption = 'Inv. Inactivity Event';
        }
        field(14; "Est. Sent Enabled"; Boolean)
        {
            Caption = 'Est. Sent Enabled';
        }
        field(15; "Est. Accepted Enabled"; Boolean)
        {
            Caption = 'Est. Accepted Enabled';
        }
        field(16; "Est. Expiring Enabled"; Boolean)
        {
            Caption = 'Est. Expiring Enabled';
        }
        field(17; "Est. Expiring Week Start (WD)"; Integer)
        {
            Caption = 'Est. Expiring Week Start (WD)';
            InitValue = 1;
        }
        field(18; "Est. Expiring Event"; Integer)
        {
            Caption = 'Est. Expiring Event';
        }
        field(19; "Inv. Email Failed Enabled"; Boolean)
        {
            Caption = 'Inv. Email Failed Enabled';
        }
        field(20; "Inv. Email Failed Event"; Integer)
        {
            Caption = 'Inv. Email Failed Event';
        }
        field(21; "Est. Email Failed Enabled"; Boolean)
        {
            Caption = 'Est. Email Failed Enabled';
        }
        field(22; "Est. Email Failed Event"; Integer)
        {
            Caption = 'Est. Email Failed Event';
        }
        field(23; "Kpi Update Enabled"; Boolean)
        {
            Caption = 'Kpi Update Enabled';
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

