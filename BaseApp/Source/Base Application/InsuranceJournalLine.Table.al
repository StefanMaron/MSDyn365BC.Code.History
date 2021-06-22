table 5635 "Insurance Journal Line"
{
    Caption = 'Insurance Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Insurance Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Insurance Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;

            trigger OnValidate()
            begin
                if "Insurance No." = '' then begin
                    CreateDim(DATABASE::Insurance, "Insurance No.");
                    exit;
                end;

                Insurance.Get("Insurance No.");
                Insurance.TestField(Blocked, false);
                Description := Insurance.Description;

                CreateDim(DATABASE::Insurance, "Insurance No.");
            end;
        }
        field(6; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                if "FA No." = '' then begin
                    "FA Description" := '';
                    exit;
                end;
                FA.Get("FA No.");
                "FA Description" := FA.Description;
                FA.TestField(Blocked, false);
                FA.TestField(Inactive, false);
            end;
        }
        field(7; "FA Description"; Text[100])
        {
            Caption = 'FA Description';
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(9; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,,Invoice,Credit Memo';
            OptionMembers = " ",,Invoice,"Credit Memo";
        }
        field(10; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(12; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(13; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(14; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify;
            end;
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify;
            end;
        }
        field(17; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(18; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(20; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(21; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "Posting Date")
        {
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        InsuranceJnlTempl.Get("Journal Template Name");
        "Source Code" := InsuranceJnlTempl."Source Code";
        InsuranceJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        "Reason Code" := InsuranceJnlBatch."Reason Code";

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        Insurance: Record Insurance;
        FA: Record "Fixed Asset";
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        InsuranceJnlLine: Record "Insurance Journal Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;

    procedure SetUpNewLine(LastInsuranceJnlLine: Record "Insurance Journal Line")
    begin
        InsuranceJnlTempl.Get("Journal Template Name");
        InsuranceJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        InsuranceJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        InsuranceJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if InsuranceJnlLine.FindFirst then begin
            "Posting Date" := LastInsuranceJnlLine."Posting Date";
            "Document No." := LastInsuranceJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate;
            if InsuranceJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.TryGetNextNo(InsuranceJnlBatch."No. Series", "Posting Date");
            end;
        end;
        "Source Code" := InsuranceJnlTempl."Source Code";
        "Reason Code" := InsuranceJnlBatch."Reason Code";
        "Posting No. Series" := InsuranceJnlBatch."Posting No. Series";
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                InsuranceJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            InsuranceJournalBatch.SetFilter(Name, BatchFilter);
            InsuranceJournalBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var InsuranceJournalLine: Record "Insurance Journal Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var InsuranceJournalLine: Record "Insurance Journal Line"; var xInsuranceJournalLine: Record "Insurance Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var InsuranceJournalLine: Record "Insurance Journal Line"; var xInsuranceJournalLine: Record "Insurance Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

