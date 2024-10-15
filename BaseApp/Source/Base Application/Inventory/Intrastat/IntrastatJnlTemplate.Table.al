// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

#if not CLEAN22
using System.Reflection;
#endif

table 261 "Intrastat Jnl. Template"
{
    Caption = 'Intrastat Jnl. Template';
    ReplicateData = true;
#if not CLEAN22
    LookupPageID = "Intrastat Jnl. Template List";
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    DataClassification = CustomerContent;

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
        field(5; "Checklist Report ID"; Integer)
        {
            Caption = 'Checklist Report ID';
#if not CLEAN22
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
#endif
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
#if not CLEAN22
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    "Page ID" := PAGE::"Intrastat Journal";
                "Checklist Report ID" := REPORT::"Intrastat - Checklist";
            end;
#endif
        }
        field(15; "Checklist Report Caption"; Text[250])
        {
#if not CLEAN22
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Checklist Report ID")));
            Caption = 'Checklist Report Caption';
            Editable = false;
            FieldClass = FlowField;
#else
            DataClassification = CustomerContent;
#endif
        }
        field(16; "Page Caption"; Text[250])
        {
#if not CLEAN22
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
#else
            DataClassification = CustomerContent;
#endif
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
#if not CLEAN22
    trigger OnDelete()
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", Name);
        IntrastatJnlLine.DeleteAll();
        IntrastatJnlBatch.SetRange("Journal Template Name", Name);
        IntrastatJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
#endif
}

