﻿namespace Microsoft.Inventory.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Journal;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Structure;
using System.Reflection;

table 82 "Item Journal Template"
{
    Caption = 'Item Journal Template';
    LookupPageID = "Item Journal Template List";
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
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(8; "Force Posting Report"; Boolean)
        {
            Caption = 'Force Posting Report';
        }
        field(9; Type; Enum "Item Journal Template Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                "Test Report ID" := REPORT::"Inventory Posting - Test";
                "Posting Report ID" := REPORT::"Item Register - Quantity";
                "Whse. Register Report ID" := Report::"Warehouse Register - Quantity";
                SourceCodeSetup.Get();
                case Type of
                    Type::Item:
                        begin
                            "Source Code" := SourceCodeSetup."Item Journal";
                            "Page ID" := Page::"Item Journal";
                        end;
                    Type::Transfer:
                        begin
                            "Source Code" := SourceCodeSetup."Item Reclass. Journal";
                            "Page ID" := Page::"Item Reclass. Journal";
                        end;
                    Type::"Phys. Inventory":
                        begin
                            "Source Code" := SourceCodeSetup."Phys. Inventory Journal";
                            "Page ID" := Page::"Phys. Inventory Journal";
                        end;
                    Type::Revaluation:
                        begin
                            "Source Code" := SourceCodeSetup."Revaluation Journal";
                            "Page ID" := Page::"Revaluation Journal";
                            "Test Report ID" := REPORT::"Revaluation Posting - Test";
                            "Posting Report ID" := REPORT::"Item Register - Value";
                        end;
                    Type::Consumption:
                        begin
                            "Source Code" := SourceCodeSetup."Consumption Journal";
                            "Page ID" := Page::"Consumption Journal";
                        end;
                    Type::Output:
                        begin
                            "Source Code" := SourceCodeSetup."Output Journal";
                            "Page ID" := Page::"Output Journal";
                        end;
                    Type::Capacity:
                        begin
                            "Source Code" := SourceCodeSetup."Capacity Journal";
                            "Page ID" := Page::"Capacity Journal";
                        end;
                    Type::"Prod. Order":
                        begin
                            "Source Code" := SourceCodeSetup."Production Journal";
                            "Page ID" := Page::"Production Journal";
                        end;
                end;
                if Recurring then
                    case Type of
                        Type::Item:
                            "Page ID" := Page::"Recurring Item Jnl.";
                        Type::Consumption:
                            "Page ID" := Page::"Recurring Consumption Journal";
                        Type::Output:
                            "Page ID" := Page::"Recurring Output Journal";
                        Type::Capacity:
                            "Page ID" := Page::"Recurring Capacity Journal";
                    end;

                OnAfterValidateType(Rec, SourceCodeSetup);
            end;
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                ItemJnlLine.SetRange("Journal Template Name", Name);
                ItemJnlLine.ModifyAll("Source Code", "Source Code");
                Modify();
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(12; Recurring; Boolean)
        {
            Caption = 'Recurring';

            trigger OnValidate()
            begin
                Validate(Type);
                if Recurring then
                    TestField("No. Series", '');
            end;
        }
        field(15; "Test Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Posting Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Posting Report ID")));
            Caption = 'Posting Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    if Recurring then
                        Error(
                          Text000,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        "Posting No. Series" := '';
                end;
            end;
        }
        field(20; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
            end;
        }
        field(21; "Whse. Register Report ID"; Integer)
        {
            AccessByPermission = TableData "Bin Content" = R;
            Caption = 'Whse. Register Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(22; "Whse. Register Report Caption"; Text[250])
        {
            AccessByPermission = TableData "Bin Content" = R;
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Whse. Register Report ID")));
            Caption = 'Whse. Register Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
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
        fieldgroup(DropDown; Name, Description, Type)
        {
        }
    }

    trigger OnDelete()
    begin
        ItemJnlLine.SetRange("Journal Template Name", Name);
        ItemJnlLine.DeleteAll(true);
        ItemJnlBatch.SetRange("Journal Template Name", Name);
        ItemJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    trigger OnRename()
    begin
        ReservEngineMgt.RenamePointer(DATABASE::"Item Journal Line",
          0, xRec.Name, '', 0, 0,
          0, Name, '', 0, 0);
    end;

    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";

        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateType(ItemJournalTemplate: Record "Item Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}

