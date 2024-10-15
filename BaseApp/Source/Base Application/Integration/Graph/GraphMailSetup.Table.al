// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

table 407 "Graph Mail Setup"
{
    Caption = 'Graph Mail Setup';
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
        field(2; "Refresh Code"; BLOB)
        {
            Caption = 'Refresh Code';
            ObsoleteReason = 'The suggested way to store the secrets is Isolated Storage, therefore this field will be removed.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(3; "Expires On"; DateTime)
        {
            Caption = 'Expires On';
        }
        field(4; "Sender Email"; Text[250])
        {
            Caption = 'Sender Email';
        }
        field(5; "Sender Name"; Text[250])
        {
            Caption = 'Sender Name';
        }
        field(6; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(7; "Sender AAD ID"; Text[80])
        {
            Caption = 'Sender Microsoft Entra ID';
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

