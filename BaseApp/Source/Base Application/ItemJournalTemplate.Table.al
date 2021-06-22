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
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(8; "Force Posting Report"; Boolean)
        {
            Caption = 'Force Posting Report';
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Item,Transfer,Phys. Inventory,Revaluation,Consumption,Output,Capacity,Prod. Order';
            OptionMembers = Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order";

            trigger OnValidate()
            begin
                "Test Report ID" := REPORT::"Inventory Posting - Test";
                "Posting Report ID" := REPORT::"Item Register - Quantity";
                "Whse. Register Report ID" := REPORT::"Warehouse Register - Quantity";
                SourceCodeSetup.Get;
                case Type of
                    Type::Item:
                        begin
                            "Source Code" := SourceCodeSetup."Item Journal";
                            "Page ID" := PAGE::"Item Journal";
                        end;
                    Type::Transfer:
                        begin
                            "Source Code" := SourceCodeSetup."Item Reclass. Journal";
                            "Page ID" := PAGE::"Item Reclass. Journal";
                        end;
                    Type::"Phys. Inventory":
                        begin
                            "Source Code" := SourceCodeSetup."Phys. Inventory Journal";
                            "Page ID" := PAGE::"Phys. Inventory Journal";
                        end;
                    Type::Revaluation:
                        begin
                            "Source Code" := SourceCodeSetup."Revaluation Journal";
                            "Page ID" := PAGE::"Revaluation Journal";
                            "Test Report ID" := REPORT::"Revaluation Posting - Test";
                            "Posting Report ID" := REPORT::"Item Register - Value";
                        end;
                    Type::Consumption:
                        begin
                            "Source Code" := SourceCodeSetup."Consumption Journal";
                            "Page ID" := PAGE::"Consumption Journal";
                        end;
                    Type::Output:
                        begin
                            "Source Code" := SourceCodeSetup."Output Journal";
                            "Page ID" := PAGE::"Output Journal";
                        end;
                    Type::Capacity:
                        begin
                            "Source Code" := SourceCodeSetup."Capacity Journal";
                            "Page ID" := PAGE::"Capacity Journal";
                        end;
                    Type::"Prod. Order":
                        begin
                            "Source Code" := SourceCodeSetup."Production Journal";
                            "Page ID" := PAGE::"Production Journal";
                        end;
                end;
                if Recurring then
                    case Type of
                        Type::Item:
                            "Page ID" := PAGE::"Recurring Item Jnl.";
                        Type::Consumption:
                            "Page ID" := PAGE::"Recurring Consumption Journal";
                        Type::Output:
                            "Page ID" := PAGE::"Recurring Output Journal";
                        Type::Capacity:
                            "Page ID" := PAGE::"Recurring Capacity Journal";
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
                Modify;
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
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Test Report ID")));
            Caption = 'Test Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Posting Report Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Posting Report ID")));
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
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(22; "Whse. Register Report Caption"; Text[250])
        {
            AccessByPermission = TableData "Bin Content" = R;
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Whse. Register Report ID")));
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
        ItemJnlBatch.DeleteAll;
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
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateType(ItemJournalTemplate: Record "Item Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}

