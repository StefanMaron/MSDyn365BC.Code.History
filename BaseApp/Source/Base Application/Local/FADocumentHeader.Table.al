table 12470 "FA Document Header"
{
    Caption = 'FA Document Header';
    DataCaptionFields = "No.";
    LookupPageID = "FA Document List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Writeoff,Release,Movement';
            OptionMembers = Writeoff,Release,Movement;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                Validate("FA Posting Date", "Posting Date");
                UpdateFADocLines(FieldNo("Posting Date"));
            end;
        }
        field(6; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';

            trigger OnValidate()
            begin
                UpdateFADocLines(FieldNo("FA Posting Date"));
            end;
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(10; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(11; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist("FA Comment" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Document Line No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(15; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with FADocHeader do begin
                    FADocHeader := Rec;
                    FASetup.Get();
                    TestNoSeries();
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode(), "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := FADocHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    FASetup.Get();
                    TestNoSeries();
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode(), "Posting No. Series");
                end;
            end;
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(20; "Posting No."; Code[10])
        {
            Caption = 'Posting No.';
        }
        field(22; "Reason Document No."; Code[20])
        {
            Caption = 'Reason Document No.';
        }
        field(23; "Reason Document Date"; Date)
        {
            Caption = 'Reason Document Date';
        }
        field(24; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";

            trigger OnValidate()
            var
                FALocation: Record "FA Location";
            begin
                if FALocation.Get("FA Location Code") then
                    "FA Employee No." := FALocation."Employee No.";
                CheckLines();
            end;
        }
        field(25; "New FA Location Code"; Code[10])
        {
            Caption = 'New FA Location Code';
            TableRelation = "FA Location";

            trigger OnValidate()
            begin
                UpdateFADocLines(FieldNo("New FA Location Code"));
            end;
        }
        field(26; "FA Employee No."; Code[20])
        {
            Caption = 'FA Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                CheckLines();
            end;
        }
        field(27; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        FAComment: Record "FA Comment";
    begin
        FAComment.Reset();
        FAComment.SetRange("Document Type", "Document Type");
        FAComment.SetRange("Document No.", "No.");
        FAComment.DeleteAll();

        DocSignMgt.DeleteDocSign(DATABASE::"FA Document Header", "Document Type", "No.");

        FADocLine.Reset();
        FADocLine.SetRange("Document Type", "Document Type");
        FADocLine.SetRange("Document No.", "No.");
        FADocLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        FASetup.Get();
        if "No." = '' then begin
            TestNoSeries();
            NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "FA Posting Date", "No.", "No. Series");
        end;
        InitRecord();

        DocSignMgt.SetDefaults(DATABASE::"FA Document Header", "Document Type", "No.");
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
        FASetup: Record "FA Setup";
        DimMgt: Codeunit DimensionManagement;
        Text003: Label 'You cannot rename a %1.';
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocSignMgt: Codeunit "Doc. Signature Management";
        Text064: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        case "Document Type" of
            "Document Type"::Writeoff:
                begin
                    if ("No. Series" <> '') and
                       (FASetup."Writeoff Nos." = FASetup."Posted Writeoff Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        if "Posting No. Series" = '' then
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", FASetup."Posted Writeoff Nos.");
                end;
            "Document Type"::Release:
                begin
                    if ("No. Series" <> '') and
                       (FASetup."Release Nos." = FASetup."Posted Release Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        if "Posting No. Series" = '' then
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", FASetup."Posted Release Nos.");
                end;
            "Document Type"::Movement:
                begin
                    if ("No. Series" <> '') and
                       (FASetup."Disposal Nos." = FASetup."Posted Disposal Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        if "Posting No. Series" = '' then
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", FASetup."Posted Disposal Nos.");
                end;
        end;

        if "Posting No. Series" = '' then
            "Posting No. Series" := "No. Series";

        "Posting Date" := WorkDate();
        "FA Posting Date" := WorkDate();

        "Posting Description" := StrSubstNo('%1 %2', "Document Type", "No.");
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldFADocHeader: Record "FA Document Header"): Boolean
    begin
        FASetup.Get();
        TestNoSeries();
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode(), OldFADocHeader."No. Series", "No. Series") then begin
            FASetup.Get();
            TestNoSeries();
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    begin
        case "Document Type" of
            "Document Type"::Writeoff:
                begin
                    FASetup.TestField("Writeoff Nos.");
                    FASetup.TestField("Posted Writeoff Nos.");
                end;
            "Document Type"::Release:
                begin
                    FASetup.TestField("Release Nos.");
                    FASetup.TestField("Posted Release Nos.");
                end;
            "Document Type"::Movement:
                begin
                    FASetup.TestField("Disposal Nos.");
                    FASetup.TestField("Posted Disposal Nos.");
                end;
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Writeoff:
                exit(FASetup."Writeoff Nos.");
            "Document Type"::Release:
                exit(FASetup."Release Nos.");
            "Document Type"::Movement:
                exit(FASetup."Disposal Nos.");
        end;
    end;

    local procedure GetPostingNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Writeoff:
                exit(FASetup."Posted Writeoff Nos.");
            "Document Type"::Release:
                exit(FASetup."Posted Release Nos.");
            "Document Type"::Movement:
                exit(FASetup."Posted Disposal Nos.");
        end;
    end;

    [Scope('OnPrem')]
    procedure DocLinesExist(): Boolean
    begin
        FADocLine.Reset();
        FADocLine.SetRange("Document Type", "Document Type");
        FADocLine.SetRange("Document No.", "No.");
        exit(not FADocLine.IsEmpty);
    end;

#if not CLEAN20
    [Obsolete('Replaced by CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])', '20.0')]
    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimMgt.GetDefaultDimID(
          TableID, No, SourceCodeSetup."Fixed Asset G/L Journal", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;
#endif

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimMgt.GetDefaultDimID(
            DefaultDimSource, SourceCodeSetup."Fixed Asset G/L Journal", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if DocLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateFADocLines(CalledByFieldNo: Integer)
    begin
        FADocLine.SetRange("Document Type", "Document Type");
        FADocLine.SetRange("Document No.", "No.");
        FADocLine.LockTable();
        if FADocLine.Find('-') then
            repeat
                case CalledByFieldNo of
                    FieldNo("Posting Date"):
                        FADocLine.Validate("Posting Date", "Posting Date");
                    FieldNo("FA Posting Date"):
                        FADocLine.Validate("FA Posting Date", "FA Posting Date");
                    FieldNo("New FA Location Code"):
                        FADocLine.Validate("FA Location Code", "New FA Location Code");
                end;
                FADocLine.Modify(true);
            until FADocLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetFAComments(var Comment: array[5] of Text[80]; Type: Integer)
    var
        FAComment: Record "FA Comment";
        Index: Integer;
    begin
        Clear(Comment);
        Index := 0;
        FAComment.Reset();
        FAComment.SetCurrentKey("Document Type", "Document No.", "Document Line No.", Type);
        FAComment.SetRange("Document Type", "Document Type");
        FAComment.SetRange("Document No.", "No.");
        FAComment.SetRange("Document Line No.", 0);
        FAComment.SetRange(Type, Type);
        if FAComment.FindSet() then
            repeat
                Index += 1;
                Comment[Index] := FAComment.Comment
            until (FAComment.Next() = 0) or (Index = ArrayLen(Comment));
    end;

    [Scope('OnPrem')]
    procedure CheckLines()
    var
        FADocLine: Record "FA Document Line";
    begin
        FADocLine.SetRange("Document Type", "Document Type");
        FADocLine.SetRange("Document No.", "No.");
        if FADocLine.FindSet() then
            repeat
                FADocLine.Check("FA Location Code", "New FA Location Code", "FA Employee No.");
            until FADocLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if DocLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text064) then
            exit;

        FADocLine.Reset();
        FADocLine.SetRange("Document Type", "Document Type");
        FADocLine.SetRange("Document No.", "No.");
        FADocLine.LockTable();
        if FADocLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(FADocLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if FADocLine."Dimension Set ID" <> NewDimSetID then begin
                    FADocLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      FADocLine."Dimension Set ID", FADocLine."Shortcut Dimension 1 Code", FADocLine."Shortcut Dimension 2 Code");
                    FADocLine.Modify();
                end;
            until FADocLine.Next() = 0;
    end;
}

