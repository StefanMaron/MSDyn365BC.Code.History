table 5628 Insurance
{
    Caption = 'Insurance';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Insurance List";
    LookupPageID = "Insurance List";
    Permissions = TableData "Ins. Coverage Ledger Entry" = r;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    FASetup.Get();
                    NoSeriesMgt.TestManual(FASetup."Insurance Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
        }
        field(3; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(4; "Policy No."; Text[30])
        {
            Caption = 'Policy No.';
        }
        field(6; "Annual Premium"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Annual Premium';
            MinValue = 0;
        }
        field(7; "Policy Coverage"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Policy Coverage';
            MinValue = 0;
        }
        field(10; "Total Value Insured"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Ins. Coverage Ledger Entry".Amount WHERE("Insurance No." = FIELD("No."),
                                                                         "Disposed FA" = CONST(false),
                                                                         "Posting Date" = FIELD("Date Filter")));
            Caption = 'Total Value Insured';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist ("Comment Line" WHERE("Table Name" = CONST(Insurance),
                                                      "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Insurance Type"; Code[10])
        {
            Caption = 'Insurance Type';
            TableRelation = "Insurance Type";
        }
        field(13; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(14; "Insurance Vendor No."; Code[20])
        {
            Caption = 'Insurance Vendor No.';
            TableRelation = Vendor;
        }
        field(15; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(16; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(17; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(18; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(19; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(32; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(33; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(34; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(35; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(36; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Policy No.")
        {
        }
    }

    trigger OnDelete()
    begin
        FAMoveEntries.MoveInsuranceEntries(Rec);
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Insurance);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::Insurance, "No.");
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            FASetup.Get();
            FASetup.TestField("Insurance Nos.");
            NoSeriesMgt.InitSeries(FASetup."Insurance Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        DimMgt.UpdateDefaultDim(
          DATABASE::Insurance, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::Insurance, xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        CommentLine: Record "Comment Line";
        FASetup: Record "FA Setup";
        Insurance: Record Insurance;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        FAMoveEntries: Codeunit "FA MoveEntries";
        DimMgt: Codeunit DimensionManagement;

    procedure AssistEdit(OldInsurance: Record Insurance): Boolean
    begin
        with Insurance do begin
            Insurance := Rec;
            FASetup.Get();
            FASetup.TestField("Insurance Nos.");
            if NoSeriesMgt.SelectSeries(FASetup."Insurance Nos.", OldInsurance."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := Insurance;
                exit(true);
            end;
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Insurance, "No.", FieldNumber, ShortcutDimCode);
            Modify(true);
        end;
	
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Insurance: Record Insurance; var xInsurance: Record Insurance; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Insurance: Record Insurance; var xInsurance: Record Insurance; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

