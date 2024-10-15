// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Reflection;

table 255 "VAT Statement Template"
{
    Caption = 'VAT Statement Template';
    LookupPageID = "VAT Statement Template List";
    ReplicateData = true;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    "Page ID" := PAGE::"VAT Statement";
                "VAT Statement Report ID" := REPORT::"VAT Statement";
            end;
        }
        field(7; "VAT Statement Report ID"; Integer)
        {
            Caption = 'VAT Statement Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "VAT Statement Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("VAT Statement Report ID")));
            Caption = 'VAT Statement Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11760; "XML Format"; Option)
        {
            Caption = 'XML Format';
            OptionCaption = 'DPHDP2,DPHDP3';
            OptionMembers = DPHDP2,DPHDP3;
            InitValue = DPHDP3;
            ObsoleteState = Removed;
            ObsoleteReason = 'The file format DPHDP2 is deprecated. Only the DPHDP3 format will be supported. This field will be removed and should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11761; "Allow Comments/Attachments"; Boolean)
        {
            Caption = 'Allow Comments/Attachments';
            InitValue = true; // NAVCZ
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VATStmtLine.SetRange("Statement Template Name", Name);
        VATStmtLine.DeleteAll();
        VATStmtName.SetRange("Statement Template Name", Name);
        VATStmtName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        VATStmtName: Record "VAT Statement Name";
        VATStmtLine: Record "VAT Statement Line";
}

