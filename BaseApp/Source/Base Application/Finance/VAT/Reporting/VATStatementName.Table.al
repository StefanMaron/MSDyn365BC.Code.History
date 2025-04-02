// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 257 "VAT Statement Name"
{
    Caption = 'VAT Statement Name';
    LookupPageID = "VAT Statement Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            NotBlank = true;
            TableRelation = "VAT Statement Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
#if not CLEANSCHEMA25
        field(11000; "Sales VAT Adv. Notification"; Boolean)
        {
            Caption = 'Sales VAT Adv. Notification';
            ObsoleteReason = 'Moved to Elster extension, new field Sales VAT Adv. Notif.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Statement Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VATStmtLine.SetRange("Statement Template Name", "Statement Template Name");
        VATStmtLine.SetRange("Statement Name", Name);
        VATStmtLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        VATStmtLine.SetRange("Statement Template Name", xRec."Statement Template Name");
        VATStmtLine.SetRange("Statement Name", xRec.Name);
        while VATStmtLine.FindFirst() do
            VATStmtLine.Rename("Statement Template Name", Name, VATStmtLine."Line No.");
    end;

    var
        VATStmtLine: Record "VAT Statement Line";
}

