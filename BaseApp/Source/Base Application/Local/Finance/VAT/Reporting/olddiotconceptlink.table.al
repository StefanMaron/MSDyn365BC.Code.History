// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;

table 27041 "DIOT-Concept Link"
{
    Caption = 'DIOT Concept Link';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "DIOT Concept No."; Integer)
        {
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Product Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(3; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Business Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
    }

    keys
    {
        key(Key1; "DIOT Concept No.", "VAT Prod. Posting Group", "VAT Bus. Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

