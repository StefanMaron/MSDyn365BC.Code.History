table 5850 "Invt. Document Header"
{
    Caption = 'Item Document Header';
    DataCaptionFields = "Document Type", "No.";
    LookupPageID = "Invt. Document List";

    fields
    {
        field(1; "Document Type"; Enum "Invt. Doc. Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(3; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                UpdateItemDocLines(FieldNo("Document Date"));
            end;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                UpdateItemDocLines(FieldNo("Posting Date"));
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                Location.Get("Location Code");
                Location.TestField("Directed Put-away and Pick", false);

                UpdateItemDocLines(FieldNo("Location Code"));
                CreateDimFromDefaultDim();
            end;
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

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
        field(11; "Salesperson/Purchaser Code"; Code[20])
        {
            Caption = 'Salesperson/Purchaser Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim();
            end;
        }
        field(12; "Receipt Comment"; Boolean)
        {
            CalcFormula = Exist("Inventory Comment Line" WHERE("Document Type" = CONST("Inventory Receipt"),
                                                                "No." = FIELD("No.")));
            Caption = 'Receipt Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Shipment Comment"; Boolean)
        {
            CalcFormula = Exist("Inventory Comment Line" WHERE("Document Type" = CONST("Inventory Shipment"),
                                                                "No." = FIELD("No.")));
            Caption = 'Shipment Comment';
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
                with InvtDocHeader do begin
                    InvtDocHeader := Rec;
                    InvtSetup.Get();
                    TestNoSeries();
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode(), "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := InvtDocHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    InvtSetup.Get();
                    TestNoSeries();
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode(), "Posting No. Series");
                end;
            end;
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(17; "Whse. Adj. Bin Code"; Code[20])
        {
            Caption = 'Whse. Adj. Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(20; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(21; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(23; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                UpdateItemDocLines(FieldNo("Gen. Bus. Posting Group"));
            end;
        }
        field(27; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(30; Correction; Boolean)
        {
            Caption = 'Correction';
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
    begin
        InvtDocLine.SetRange("Document Type", "Document Type");
        InvtDocLine.SetRange("Document No.", "No.");
        if InvtDocLine.Find('-') then
            repeat
                InvtDocLine.SuspendStatusCheck(true);
                InvtDocLine.Delete(true);
            until InvtDocLine.Next() = 0;
    end;

    trigger OnInsert()
    begin
        InvtSetup.Get();
        if "No." = '' then begin
            TestNoSeries();
            NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;
        InitRecord();
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        DimMgt: Codeunit DimensionManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        HideValidationDialog: Boolean;
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 - table caption';
        ConfirmDimChangeQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        DocumentTxt: Label '%1 %2', Locked = true;

    procedure InitRecord()
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                if ("No. Series" <> '') and
                    (InvtSetup."Invt. Receipt Nos." = InvtSetup."Posted Invt. Receipt Nos.")
                then
                    "Posting No. Series" := "No. Series"
                else
                    if "Posting No. Series" = '' then
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", InvtSetup."Posted Invt. Receipt Nos.");
            "Document Type"::Shipment:
                if ("No. Series" <> '') and
                    (InvtSetup."Invt. Shipment Nos." = InvtSetup."Posted Invt. Shipment Nos.")
                then
                    "Posting No. Series" := "No. Series"
                else
                    if "Posting No. Series" = '' then
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", InvtSetup."Posted Invt. Shipment Nos.");
        end;

        "Posting Description" := Format("Document Type") + ' ' + "No.";


        "Posting Date" := WorkDate();
        "Document Date" := "Posting Date";
        OnAfterInitRecord(Rec);
    end;

    procedure AssistEdit(OldInvtDocHeader: Record "Invt. Document Header"): Boolean
    begin
        InvtSetup.Get();
        TestNoSeries();
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode(), OldInvtDocHeader."No. Series", "No. Series") then begin
            InvtSetup.Get();
            TestNoSeries();
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                begin
                    InvtSetup.TestField("Invt. Receipt Nos.");
                    InvtSetup.TestField("Posted Invt. Receipt Nos.");
                end;
            "Document Type"::Shipment:
                begin
                    InvtSetup.TestField("Invt. Shipment Nos.");
                    InvtSetup.TestField("Posted Invt. Shipment Nos.");
                end;
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                exit(InvtSetup."Invt. Receipt Nos.");
            "Document Type"::Shipment:
                exit(InvtSetup."Invt. Shipment Nos.");
        end;
    end;

    local procedure GetPostingNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                exit(InvtSetup."Posted Invt. Receipt Nos.");
            "Document Type"::Shipment:
                exit(InvtSetup."Posted Invt. Shipment Nos.");
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DocLinesExist(): Boolean
    begin
        InvtDocLine.Reset();
        InvtDocLine.SetRange("Document Type", "Document Type");
        InvtDocLine.SetRange("Document No.", "No.");
        exit(not InvtDocLine.IsEmpty());
    end;

#if not CLEAN20
    [Obsolete('Replaced by CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])', '20.0')]
    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        case "Document Type" of
            "Document Type"::Receipt:
                "Dimension Set ID" :=
                  DimMgt.GetDefaultDimID(
                    TableID, No, SourceCodeSetup."Invt. Receipt", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
            "Document Type"::Shipment:
                "Dimension Set ID" :=
                  DimMgt.GetDefaultDimID(
                    TableID, No, SourceCodeSetup."Invt. Shipment", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;

        if (OldDimSetID <> "Dimension Set ID") and DocLinesExist() then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;
#endif

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        case "Document Type" of
            "Document Type"::Receipt:
                "Dimension Set ID" :=
                  DimMgt.GetDefaultDimID(
                    DefaultDimSource, SourceCodeSetup."Invt. Receipt", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
            "Document Type"::Shipment:
                "Dimension Set ID" :=
                  DimMgt.GetDefaultDimID(
                    DefaultDimSource, SourceCodeSetup."Invt. Shipment", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;

        if (OldDimSetID <> "Dimension Set ID") and DocLinesExist() then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

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

    local procedure UpdateItemDocLines(FieldRef: Integer)
    begin
        InvtDocLine.LockTable();
        InvtDocLine.SetRange("Document Type", "Document Type");
        InvtDocLine.SetRange("Document No.", "No.");
        if InvtDocLine.FindSet(true, false) then
            repeat
                case FieldRef of
                    FieldNo("Location Code"):
                        begin
                            InvtDocLine.Validate("Location Code", "Location Code");
                            InvtDocLine.Validate("Posting Date", "Posting Date");
                            InvtDocLine.Validate("Document Date", "Document Date");
                        end;
                    FieldNo("Posting Date"):
                        InvtDocLine.Validate("Posting Date", "Posting Date");
                    FieldNo("Document Date"):
                        InvtDocLine.Validate("Document Date", "Document Date");
                    FieldNo("Gen. Bus. Posting Group"):
                        InvtDocLine.Validate("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                end;
                InvtDocLine.Modify(true);
            until InvtDocLine.Next() = 0;
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo(DocumentTxt, "Document Type", "No."),
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
        if NewParentDimSetID = OldParentDimSetID then
            exit;

        if not HideValidationDialog then
            if not Confirm(ConfirmDimChangeQst) then
                exit;

        InvtDocLine.Reset();
        InvtDocLine.SetRange("Document Type", "Document Type");
        InvtDocLine.SetRange("Document No.", "No.");
        InvtDocLine.LockTable();
        if InvtDocLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(InvtDocLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if InvtDocLine."Dimension Set ID" <> NewDimSetID then begin
                    InvtDocLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      InvtDocLine."Dimension Set ID", InvtDocLine."Shortcut Dimension 1 Code", InvtDocLine."Shortcut Dimension 2 Code");
                    InvtDocLine.Modify();
                end;
            until InvtDocLine.Next() = 0;
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salesperson/Purchaser Code");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var InvtDocumentHeader: Record "Invt. Document Header"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var InvtDocumentHeader: Record "Invt. Document Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;
}

