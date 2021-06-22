table 80 "Gen. Journal Template"
{
    Caption = 'Gen. Journal Template';
    LookupPageID = "General Journal Template List";
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
        field(9; Type; Enum "Gen. Journal Template Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                "Test Report ID" := REPORT::"General Journal - Test";
                "Posting Report ID" := REPORT::"G/L Register";
                SourceCodeSetup.Get();
                case Type of
                    Type::General:
                        begin
                            "Source Code" := SourceCodeSetup."General Journal";
                            "Page ID" := PAGE::"General Journal";
                        end;
                    Type::Sales:
                        begin
                            "Source Code" := SourceCodeSetup."Sales Journal";
                            "Page ID" := PAGE::"Sales Journal";
                        end;
                    Type::Purchases:
                        begin
                            "Source Code" := SourceCodeSetup."Purchase Journal";
                            "Page ID" := PAGE::"Purchase Journal";
                        end;
                    Type::"Cash Receipts":
                        begin
                            "Source Code" := SourceCodeSetup."Cash Receipt Journal";
                            "Page ID" := PAGE::"Cash Receipt Journal";
                        end;
                    Type::Payments:
                        begin
                            "Source Code" := SourceCodeSetup."Payment Journal";
                            "Page ID" := PAGE::"Payment Journal";
                        end;
                    Type::Assets:
                        begin
                            "Source Code" := SourceCodeSetup."Fixed Asset G/L Journal";
                            "Page ID" := PAGE::"Fixed Asset G/L Journal";
                        end;
                    Type::Intercompany:
                        begin
                            "Source Code" := SourceCodeSetup."IC General Journal";
                            "Page ID" := PAGE::"IC General Journal";
                        end;
                    Type::Jobs:
                        begin
                            "Source Code" := SourceCodeSetup."Job G/L Journal";
                            "Page ID" := PAGE::"Job G/L Journal";
                        end;
                end;

                if Recurring then
                    "Page ID" := PAGE::"Recurring General Journal";

                OnAfterValidateType(Rec, SourceCodeSetup);
            end;
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                GenJnlLine.SetRange("Journal Template Name", Name);
                GenJnlLine.ModifyAll("Source Code", "Source Code");
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
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Test Report ID")));
            Caption = 'Test Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Posting Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Posting Report ID")));
            Caption = 'Posting Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Force Doc. Balance"; Boolean)
        {
            Caption = 'Force Doc. Balance';
            InitValue = true;
        }
        field(19; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(20; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if "Bal. Account Type" = "Bal. Account Type"::"G/L Account" then
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        field(21; "No. Series"; Code[20])
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
        field(22; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
            end;
        }
        field(23; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Copy VAT Setup to Jnl. Lines" <> xRec."Copy VAT Setup to Jnl. Lines" then begin
                    GenJnlBatch.SetRange("Journal Template Name", Name);
                    GenJnlBatch.ModifyAll("Copy VAT Setup to Jnl. Lines", "Copy VAT Setup to Jnl. Lines");
                end;
            end;
        }
        field(24; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';

            trigger OnValidate()
            begin
                if "Allow VAT Difference" <> xRec."Allow VAT Difference" then begin
                    GenJnlBatch.SetRange("Journal Template Name", Name);
                    GenJnlBatch.ModifyAll("Allow VAT Difference", "Allow VAT Difference");
                end;
            end;
        }
        field(25; "Cust. Receipt Report ID"; Integer)
        {
            AccessByPermission = TableData Customer = R;
            Caption = 'Cust. Receipt Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(26; "Cust. Receipt Report Caption"; Text[250])
        {
            AccessByPermission = TableData Customer = R;
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Cust. Receipt Report ID")));
            Caption = 'Cust. Receipt Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Vendor Receipt Report ID"; Integer)
        {
            AccessByPermission = TableData Vendor = R;
            Caption = 'Vendor Receipt Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(28; "Vendor Receipt Report Caption"; Text[250])
        {
            AccessByPermission = TableData Vendor = R;
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Vendor Receipt Report ID")));
            Caption = 'Vendor Receipt Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
        }
        field(31; "Copy to Posted Jnl. Lines"; Boolean)
        {
            Caption = 'Copy to Posted Jnl. Lines';

            trigger OnValidate()
            begin
                if "Copy to Posted Jnl. Lines" <> xRec."Copy to Posted Jnl. Lines" then begin
                    TestField(Recurring, false);
                    GenJnlBatch.SetRange("Journal Template Name", Name);
                    GenJnlBatch.ModifyAll("Copy to Posted Jnl. Lines", "Copy to Posted Jnl. Lines");
                end;
            end;
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
        GenJnlAlloc.SetRange("Journal Template Name", Name);
        GenJnlAlloc.DeleteAll();
        GenJnlLine.SetRange("Journal Template Name", Name);
        GenJnlLine.DeleteAll(true);
        GenJnlBatch.SetRange("Journal Template Name", Name);
        GenJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        SourceCodeSetup: Record "Source Code Setup";

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
            GLAcc.TestField("Direct Posting", true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}

