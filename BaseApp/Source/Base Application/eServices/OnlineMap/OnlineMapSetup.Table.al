// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

using System.Privacy;

table 800 "Online Map Setup"
{
    Caption = 'Online Map Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Map Parameter Setup Code"; Code[10])
        {
            Caption = 'Map Parameter Setup Code';
            TableRelation = "Online Map Parameter Setup";
        }
        field(3; "Distance In"; Option)
        {
            Caption = 'Distance In';
            OptionCaption = 'Miles,Kilometers';
            OptionMembers = Miles,Kilometers;
        }
        field(4; Route; Option)
        {
            Caption = 'Route';
            OptionCaption = 'Quickest,Shortest';
            OptionMembers = Quickest,Shortest;
        }
        field(13; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
            begin
                if not xRec."Enabled" and Rec."Enabled" then
                    Rec."Enabled" := CustomerConsentMgt.ConfirmUserConsentToMicrosoftService();
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

