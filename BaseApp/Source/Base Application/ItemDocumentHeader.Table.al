table 12450 "Item Document Header"
{
    Caption = 'Item Document Header';
    DataCaptionFields = "Document Type", "No.";
    LookupPageID = "Item Document List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
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
                if "Document Type" = "Document Type"::Receipt then
                    Location.TestField("Require Receive", false)
                else
                    Location.TestField("Require Shipment", false);
                Location.TestField("Directed Put-away and Pick", false);

                UpdateItemDocLines(FieldNo("Location Code"));
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
        field(11; "Salesperson/Purchaser Code"; Code[20])
        {
            Caption = 'Salesperson/Purchaser Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Salesperson/Purchaser Code");
            end;
        }
        field(12; "Receipt Comment"; Boolean)
        {
            CalcFormula = Exist ("Inventory Comment Line" WHERE("Document Type" = CONST("Item Receipt"),
                                                                "No." = FIELD("No.")));
            Caption = 'Receipt Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Shipment Comment"; Boolean)
        {
            CalcFormula = Exist ("Inventory Comment Line" WHERE("Document Type" = CONST("Item Shipment"),
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
                with ItemDocHeader do begin
                    ItemDocHeader := Rec;
                    InvtSetup.Get();
                    TestNoSeries;
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode, "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := ItemDocHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    TestNoSeries;
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode, "Posting No. Series");
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
                ShowDocDim;
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
        DocSignMgt.DeleteDocSign(DATABASE::"Item Document Header", "Document Type", "No.");

        ItemDocLine.SetRange("Document Type", "Document Type");
        ItemDocLine.SetRange("Document No.", "No.");
        if ItemDocLine.Find('-') then
            repeat
                ItemDocLine.SuspendStatusCheck(true);
                ItemDocLine.Delete(true);
            until ItemDocLine.Next = 0;
    end;

    trigger OnInsert()
    begin
        InvtSetup.Get();
        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;
        InitRecord;

        DocSignMgt.SetDefaults(DATABASE::"Item Document Header", "Document Type", "No.");
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        ItemDocHeader: Record "Item Document Header";
        ItemDocLine: Record "Item Document Line";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        DimMgt: Codeunit DimensionManagement;
        Text003: Label 'You cannot rename a %1.';
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocSignMgt: Codeunit "Doc. Signature Management";
        HideValidationDialog: Boolean;
        Text064: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                begin
                    if ("No. Series" <> '') and
                       (InvtSetup."Item Receipt Nos." = InvtSetup."Posted Item Receipt Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        if "Posting No. Series" = '' then
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", InvtSetup."Posted Item Receipt Nos.");
                end;
            "Document Type"::Shipment:
                begin
                    if ("No. Series" <> '') and
                       (InvtSetup."Item Shipment Nos." = InvtSetup."Posted Item Shipment Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        if "Posting No. Series" = '' then
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", InvtSetup."Posted Item Shipment Nos.");
                end;
        end;

        "Posting Description" := Format("Document Type") + ' ' + "No.";

        if "Posting No. Series" = '' then
            "Posting No. Series" := "No. Series";

        "Posting Date" := WorkDate;
        "Document Date" := "Posting Date";
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldItemDocHeader: Record "Item Document Header"): Boolean
    begin
        InvtSetup.Get();
        TestNoSeries;
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldItemDocHeader."No. Series", "No. Series") then begin
            InvtSetup.Get();
            TestNoSeries;
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                begin
                    InvtSetup.TestField("Item Receipt Nos.");
                    InvtSetup.TestField("Posted Item Receipt Nos.");
                end;
            "Document Type"::Shipment:
                begin
                    InvtSetup.TestField("Item Shipment Nos.");
                    InvtSetup.TestField("Posted Item Shipment Nos.");
                end;
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                exit(InvtSetup."Item Receipt Nos.");
            "Document Type"::Shipment:
                exit(InvtSetup."Item Shipment Nos.");
        end;
    end;

    local procedure GetPostingNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Receipt:
                exit(InvtSetup."Posted Item Receipt Nos.");
            "Document Type"::Shipment:
                exit(InvtSetup."Posted Item Shipment Nos.");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [Scope('OnPrem')]
    procedure DocLinesExist(): Boolean
    begin
        ItemDocLine.Reset();
        ItemDocLine.SetRange("Document Type", "Document Type");
        ItemDocLine.SetRange("Document No.", "No.");
        exit(ItemDocLine.FindFirst);
    end;

    [Scope('OnPrem')]
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
                    TableID, No, SourceCodeSetup."Item Receipt", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
            "Document Type"::Shipment:
                "Dimension Set ID" :=
                  DimMgt.GetDefaultDimID(
                    TableID, No, SourceCodeSetup."Item Shipment", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;

        if (OldDimSetID <> "Dimension Set ID") and DocLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if DocLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateItemDocLines(FieldRef: Integer)
    begin
        ItemDocLine.LockTable();
        ItemDocLine.SetRange("Document Type", "Document Type");
        ItemDocLine.SetRange("Document No.", "No.");
        if ItemDocLine.FindSet(true, false) then begin
            repeat
                case FieldRef of
                    FieldNo("Location Code"):
                        begin
                            ItemDocLine.Validate("Location Code", "Location Code");
                            ItemDocLine.Validate("Posting Date", "Posting Date");
                            ItemDocLine.Validate("Document Date", "Document Date");
                        end;
                    FieldNo("Posting Date"):
                        ItemDocLine.Validate("Posting Date", "Posting Date");
                    FieldNo("Document Date"):
                        ItemDocLine.Validate("Document Date", "Document Date");
                    FieldNo("Gen. Bus. Posting Group"):
                        ItemDocLine.Validate("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                end;
                ItemDocLine.Modify(true);
            until ItemDocLine.Next = 0;
        end;
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
            Modify;
            if DocLinesExist then
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
        if not HideValidationDialog then
            if not Confirm(Text064) then
                exit;

        ItemDocLine.Reset();
        ItemDocLine.SetRange("Document Type", "Document Type");
        ItemDocLine.SetRange("Document No.", "No.");
        ItemDocLine.LockTable();
        if ItemDocLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(ItemDocLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ItemDocLine."Dimension Set ID" <> NewDimSetID then begin
                    ItemDocLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ItemDocLine."Dimension Set ID", ItemDocLine."Shortcut Dimension 1 Code", ItemDocLine."Shortcut Dimension 2 Code");
                    ItemDocLine.Modify();
                end;
            until ItemDocLine.Next = 0;
    end;
}

