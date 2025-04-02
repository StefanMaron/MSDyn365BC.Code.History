// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Foundation.NoSeries;

table 323 "VAT Business Posting Group"
{
    Caption = 'VAT Business Posting Group';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Business Posting Groups";
    LookupPageID = "VAT Business Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(12100; "Default Sales Operation Type"; Code[20])
        {
            Caption = 'Default Sales Operation Type';
            TableRelation = "No. Series" where("No. Series Type" = const(Sales));
        }
        field(12101; "Default Purch. Operation Type"; Code[20])
        {
            Caption = 'Default Purch. Operation Type';
            TableRelation = "No. Series" where("No. Series Type" = const(Purchase));
        }
        field(12102; "Check VAT Exemption"; Boolean)
        {
            Caption = 'Check VAT Exemption';
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
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;
}
