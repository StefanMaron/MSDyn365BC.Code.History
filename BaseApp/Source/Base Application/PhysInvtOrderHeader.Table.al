table 5875 "Phys. Invt. Order Header"
{
    Caption = 'Phys. Invt. Order Header';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Physical Inventory Orders";
    LookupPageID = "Physical Inventory Orders";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    InvtSetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Finished';
            OptionMembers = Open,Finished;
        }
        field(20; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if "Posting Date" <> xRec."Posting Date" then begin
                    PhysInvtOrderLine.Reset();
                    PhysInvtOrderLine.SetRange("Document No.", "No.");
                    PhysInvtOrderLine.SetFilter("Item No.", '<>%1', '');
                    if PhysInvtOrderLine.Find('-') then begin
                        TestField("Posting Date");
                        if not Confirm(
                             StrSubstNo(
                               ConfirmChangeQst,
                               PhysInvtOrderLine.FieldCaption("Qty. Expected (Base)"),
                               FieldCaption("Posting Date")),
                             false)
                        then begin
                            "Posting Date" := xRec."Posting Date";
                            exit;
                        end;
                        PhysInvtOrderLine.LockTable();
                        PhysInvtOrderLine.Reset();
                        PhysInvtOrderLine.SetRange("Document No.", "No.");
                        if PhysInvtOrderLine.Find('-') then
                            repeat
                                if PhysInvtOrderLine."Item No." <> '' then begin
                                    PhysInvtOrderLine.ResetQtyExpected;
                                    PhysInvtOrderLine.Modify();
                                end;
                            until PhysInvtOrderLine.Next = 0;
                        Modify;
                    end;
                end;
            end;
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = Exist ("Phys. Invt. Comment Line" WHERE("Document Type" = CONST(Order),
                                                                  "Order No." = FIELD("No."),
                                                                  "Recording No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            TableRelation = Employee;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(41; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(50; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(51; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(60; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with PhysInvtOrderHeader do begin
                    PhysInvtOrderHeader := Rec;
                    InvtSetup.Get();
                    TestNoSeries;
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode, "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := PhysInvtOrderHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    InvtSetup.Get();
                    TestNoSeries;
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode, "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }
        field(61; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(64; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(71; "No. Finished Recordings"; Integer)
        {
            CalcFormula = Count ("Phys. Invt. Record Header" WHERE("Order No." = FIELD("No."),
                                                                   Status = CONST(Finished)));
            Caption = 'No. Finished Recordings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(111; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Location.Get("Location Code");
                    Location.TestField("Bin Mandatory", true);
                    Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
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
                DimManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }

    trigger OnDelete()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
    begin
        TestField(Status, Status::Open);

        TestField("No. Finished Recordings", 0);

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", "No.");
        PhysInvtOrderLine.DeleteAll(true);

        PhysInvtCommentLine.Reset();
        PhysInvtCommentLine.SetRange("Document Type", PhysInvtCommentLine."Document Type"::Order);
        PhysInvtCommentLine.SetRange("Order No.", "No.");
        PhysInvtCommentLine.SetRange("Recording No.", 0);
        PhysInvtCommentLine.DeleteAll();

        PhysInvtRecordHeader.Reset();
        PhysInvtRecordHeader.SetRange("Order No.", "No.");
        PhysInvtRecordHeader.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        InvtSetup.Get();

        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Order Date", "No.", "No. Series");
        end;

        if PstdPhysInvtOrderHdr.Get("No.") then
            Error(AlreadyExistsErr, "No.");

        InitRecord;
    end;

    trigger OnModify()
    begin
        TestField(Status, Status::Open);
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        AlreadyExistsErr: Label 'Posted Invt. Count Order %1 already exists.', Comment = '%1 = Order No.';
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 = table caption';
        ConfirmChangeQst: Label '%1 will be reset in all order lines. Do you want to change %2?', Comment = '%1 = field caption, %2 = Posting Date';
        InvtSetup: Record "Inventory Setup";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Location: Record Location;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimManagement: Codeunit DimensionManagement;
        UpdateDimQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        MoreThanOneLineErr: Label 'There are more than one order lines in Order %1 for Item No. %2, Variant Code %3, Location Code %4, Bin Code %5.', Comment = '%1 Order No. %2 Item No. %3 Variant Code %4 Location Code %5 Bin Code';
        NoLineErr: Label 'There are no order line in Order %1 for Item No. %2, Variant Code %3, Location Code %4, Bin Code %5.', Comment = '%1 Order No. %2 Item No. %3 Variant Code %4 Location Code %5 Bin Code';

    procedure InitRecord()
    begin
        if ("No. Series" <> '') and
           (InvtSetup."Phys. Invt. Order Nos." = InvtSetup."Posted Phys. Invt. Order Nos.")
        then
            "Posting No. Series" := "No. Series"
        else
            NoSeriesMgt.SetDefaultSeries("Posting No. Series", InvtSetup."Posted Phys. Invt. Order Nos.");

        if "Posting Date" = 0D then
            Validate("Posting Date", WorkDate);
    end;

    procedure AssistEdit(OldPhysInvtOrderHeader: Record "Phys. Invt. Order Header"): Boolean
    begin
        with PhysInvtOrderHeader do begin
            PhysInvtOrderHeader := Rec;
            InvtSetup.Get();
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldPhysInvtOrderHeader."No. Series", "No. Series") then begin
                InvtSetup.Get();
                TestNoSeries;
                NoSeriesMgt.SetSeries("No.");
                Rec := PhysInvtOrderHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        InvtSetup.TestField("Phys. Invt. Order Nos.");
        InvtSetup.TestField("Posted Phys. Invt. Order Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[10]
    begin
        exit(InvtSetup."Phys. Invt. Order Nos.");
    end;

    local procedure GetPostingNoSeriesCode(): Code[10]
    begin
        exit(InvtSetup."Posted Phys. Invt. Order Nos.");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimManagement.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if PhysInvtOrderLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure GetSamePhysInvtOrderLine(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; var ErrorText: Text[250]; var PhysInvtOrderLine2: Record "Phys. Invt. Order Line"): Integer
    var
        NoOfOrderLines: Integer;
    begin
        Clear(PhysInvtOrderLine2);

        PhysInvtOrderLine2.Reset();
        PhysInvtOrderLine2.SetCurrentKey(
          "Document No.", "Item No.", "Variant Code", "Location Code", "Bin Code");
        PhysInvtOrderLine2.SetRange("Document No.", "No.");
        PhysInvtOrderLine2.SetRange("Item No.", ItemNo);
        PhysInvtOrderLine2.SetRange("Variant Code", VariantCode);
        PhysInvtOrderLine2.SetRange("Location Code", LocationCode);
        PhysInvtOrderLine2.SetRange("Bin Code", BinCode);
        OnGetSamePhysInvtOrderLineOnAfterSetFilters(PhysInvtOrderLine2, Rec);
        NoOfOrderLines := PhysInvtOrderLine2.Count();

        case NoOfOrderLines of
            0:
                ErrorText := StrSubstNo(NoLineErr, "No.", ItemNo, VariantCode, LocationCode, BinCode);
            1:
                ErrorText := '';
            else
                ErrorText := StrSubstNo(MoreThanOneLineErr, "No.", ItemNo, VariantCode, LocationCode, BinCode);
        end;

        if NoOfOrderLines > 0 then
            PhysInvtOrderLine2.Find('-');

        exit(NoOfOrderLines);
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if PhysInvtOrderLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure PhysInvtOrderLinesExist(): Boolean
    begin
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", "No.");
        exit(PhysInvtOrderLine.FindFirst);
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(UpdateDimQst) then
            exit;

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", "No.");
        PhysInvtOrderLine.LockTable();
        if PhysInvtOrderLine.FindSet then
            repeat
                NewDimSetID := DimManagement.GetDeltaDimSetID(PhysInvtOrderLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if PhysInvtOrderLine."Dimension Set ID" <> NewDimSetID then begin
                    PhysInvtOrderLine."Dimension Set ID" := NewDimSetID;
                    DimManagement.UpdateGlobalDimFromDimSetID(
                      PhysInvtOrderLine."Dimension Set ID", PhysInvtOrderLine."Shortcut Dimension 1 Code",
                      PhysInvtOrderLine."Shortcut Dimension 2 Code");
                    PhysInvtOrderLine.Modify();
                end;
            until PhysInvtOrderLine.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var xPhysInvtOrderHeader: Record "Phys. Invt. Order Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var xPhysInvtOrderHeader: Record "Phys. Invt. Order Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSamePhysInvtOrderLineOnAfterSetFilters(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;
}

