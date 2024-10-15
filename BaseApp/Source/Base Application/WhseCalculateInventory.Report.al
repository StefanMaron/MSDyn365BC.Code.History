report 7390 "Whse. Calculate Inventory"
{
    Caption = 'Whse. Calculate Inventory';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bin Content"; "Bin Content")
        {
            DataItemTableView = SORTING("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
            RequestFilterFields = "Zone Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code", "Bin Type Code", "Warehouse Class Code";

            trigger OnAfterGetRecord()
            begin
                if SkipCycleSKU("Location Code", "Item No.", "Variant Code") then
                    CurrReport.Skip;

                if not HideValidationDialog then
                    Window.Update;
                CalcFields("Quantity (Base)");
                if ("Quantity (Base)" <> 0) or ZeroQty then
                    InsertWhseJnlLine("Bin Content");
            end;

            trigger OnPostDataItem()
            begin
                if not HideValidationDialog then
                    Window.Close;
            end;

            trigger OnPreDataItem()
            var
                WhseJnlTemplate: Record "Warehouse Journal Template";
                WhseJnlBatch: Record "Warehouse Journal Batch";
            begin
                if RegisteringDate = 0D then
                    Error(Text001, WhseJnlLine.FieldCaption("Registering Date"));

                SetRange("Location Code", WhseJnlLine."Location Code");

                WhseJnlTemplate.Get(WhseJnlLine."Journal Template Name");
                WhseJnlBatch.Get(
                  WhseJnlLine."Journal Template Name",
                  WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
                if NextDocNo = '' then begin
                    if WhseJnlBatch."No. Series" <> '' then begin
                        WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
                        WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
                        WhseJnlLine.SetRange("Location Code", WhseJnlLine."Location Code");
                        if not WhseJnlLine.FindFirst then
                            NextDocNo :=
                              NoSeriesMgt.GetNextNo(WhseJnlBatch."No. Series", RegisteringDate, false);
                        WhseJnlLine.Init;
                    end;
                    if NextDocNo = '' then
                        Error(Text001, WhseJnlLine.FieldCaption("Whse. Document No."));
                end;

                NextLineNo := 0;

                if not HideValidationDialog then
                    Window.Open(Text002, "Bin Code");
            end;
        }
        dataitem("Warehouse Entry"; "Warehouse Entry")
        {

            trigger OnAfterGetRecord()
            var
                BinContent: Record "Bin Content";
            begin
                GetLocation("Location Code");
                if ("Bin Code" = Location."Adjustment Bin Code") or
                   SkipCycleSKU("Location Code", "Item No.", "Variant Code")
                then
                    CurrReport.Skip;

                BinContent.CopyFilters("Bin Content");
                BinContent.SetRange("Location Code", "Location Code");
                BinContent.SetRange("Item No.", "Item No.");
                BinContent.SetRange("Variant Code", "Variant Code");
                BinContent.SetRange("Unit of Measure Code", "Unit of Measure Code");
                if not BinContent.IsEmpty then
                    CurrReport.Skip;

                TempBinContent.Init;
                TempBinContent."Location Code" := "Location Code";
                TempBinContent."Item No." := "Item No.";
                TempBinContent."Zone Code" := "Zone Code";
                TempBinContent."Bin Code" := "Bin Code";
                TempBinContent."Variant Code" := "Variant Code";
                TempBinContent."Unit of Measure Code" := "Unit of Measure Code";
                TempBinContent."Quantity (Base)" := 0;
                if not TempBinContent.Find then
                    TempBinContent.Insert;
            end;

            trigger OnPostDataItem()
            begin
                TempBinContent.Reset;
                if TempBinContent.FindSet then
                    repeat
                        InsertWhseJnlLine(TempBinContent);
                    until TempBinContent.Next = 0;
            end;

            trigger OnPreDataItem()
            begin
                if ("Bin Content".GetFilter("Zone Code") = '') and
                   ("Bin Content".GetFilter("Bin Code") = '')
                then
                    CurrReport.Break;

                "Bin Content".CopyFilter("Location Code", "Location Code");
                "Bin Content".CopyFilter("Zone Code", "Zone Code");
                "Bin Content".CopyFilter("Bin Code", "Bin Code");
                "Bin Content".CopyFilter("Item No.", "Item No.");
                "Bin Content".CopyFilter("Variant Code", "Variant Code");
                "Bin Content".CopyFilter("Unit of Measure Code", "Unit of Measure Code");
                "Bin Content".CopyFilter("Bin Type Code", "Bin Type Code");
                "Bin Content".CopyFilter("Lot No. Filter", "Lot No.");
                "Bin Content".CopyFilter("Serial No. Filter", "Serial No.");
                TempBinContent.Reset;
                TempBinContent.DeleteAll;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(RegisteringDate; RegisteringDate)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registering Date';
                        ToolTip = 'Specifies the date for registering this batch job. The program automatically enters the work date in this field, but you can change it.';

                        trigger OnValidate()
                        begin
                            ValidateRegisteringDate;
                        end;
                    }
                    field(WhseDocumentNo; NextDocNo)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Document No.';
                        ToolTip = 'Specifies which document number will be entered in the Document No. field on the journal lines created by the batch job.';
                    }
                    field(ZeroQty; ZeroQty)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory, that is, items where the value in the Qty. (Calculated) field is 0.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if RegisteringDate = 0D then
                RegisteringDate := WorkDate;
            ValidateRegisteringDate;
        end;
    }

    labels
    {
    }

    var
        Text001: Label 'Enter the %1.';
        Text002: Label 'Processing bins    #1##########';
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        Location: Record Location;
        Bin: Record Bin;
        TempBinContent: Record "Bin Content" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        RegisteringDate: Date;
        CycleSourceType: Option " ",Item,SKU;
        PhysInvtCountCode: Code[10];
        NextDocNo: Code[20];
        NextLineNo: Integer;
        ZeroQty: Boolean;
        HideValidationDialog: Boolean;
        StockProposal: Boolean;

    procedure SetWhseJnlLine(var NewWhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine := NewWhseJnlLine;
    end;

    local procedure ValidateRegisteringDate()
    begin
        WhseJnlBatch.Get(
          WhseJnlLine."Journal Template Name",
          WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
        if WhseJnlBatch."No. Series" = '' then
            NextDocNo := ''
        else begin
            NextDocNo :=
              NoSeriesMgt.GetNextNo(WhseJnlBatch."No. Series", RegisteringDate, false);
            Clear(NoSeriesMgt);
        end;
    end;

    procedure InsertWhseJnlLine(BinContent: Record "Bin Content")
    var
        WhseEntry: Record "Warehouse Entry";
        ItemUOM: Record "Item Unit of Measure";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        with WhseJnlLine do begin
            if NextLineNo = 0 then begin
                LockTable;
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                SetRange("Location Code", "Location Code");
                if FindLast then
                    NextLineNo := "Line No.";

                SourceCodeSetup.Get;
            end;

            GetLocation(BinContent."Location Code");

            WhseEntry.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Variant Code",
              "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
            WhseEntry.SetRange("Item No.", BinContent."Item No.");
            WhseEntry.SetRange("Bin Code", BinContent."Bin Code");
            WhseEntry.SetRange("Location Code", BinContent."Location Code");
            WhseEntry.SetRange("Variant Code", BinContent."Variant Code");
            WhseEntry.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
            if WhseEntry.Find('-') then;
            repeat
                WhseEntry.SetRange("Lot No.", WhseEntry."Lot No.");
                WhseEntry.SetRange("Serial No.", WhseEntry."Serial No.");
                WhseEntry.CalcSums("Qty. (Base)");
                if (WhseEntry."Qty. (Base)" <> 0) or ZeroQty then begin
                    ItemUOM.Get(BinContent."Item No.", BinContent."Unit of Measure Code");
                    NextLineNo := NextLineNo + 10000;
                    Init;
                    "Line No." := NextLineNo;
                    Validate("Registering Date", RegisteringDate);
                    Validate("Entry Type", "Entry Type"::"Positive Adjmt.");
                    Validate("Whse. Document No.", NextDocNo);
                    Validate("Item No.", BinContent."Item No.");
                    Validate("Variant Code", BinContent."Variant Code");
                    Validate("Location Code", BinContent."Location Code");
                    "From Bin Code" := Location."Adjustment Bin Code";
                    "From Zone Code" := Bin."Zone Code";
                    "From Bin Type Code" := Bin."Bin Type Code";
                    Validate("To Zone Code", BinContent."Zone Code");
                    Validate("To Bin Code", BinContent."Bin Code");
                    Validate("Zone Code", BinContent."Zone Code");
                    SetProposal(StockProposal);
                    Validate("Bin Code", BinContent."Bin Code");
                    Validate("Source Code", SourceCodeSetup."Whse. Phys. Invt. Journal");
                    Validate("Unit of Measure Code", BinContent."Unit of Measure Code");
                    "Serial No." := WhseEntry."Serial No.";
                    "Lot No." := WhseEntry."Lot No.";
                    "Warranty Date" := WhseEntry."Warranty Date";
                    ExpDate := ItemTrackingMgt.ExistingExpirationDate("Item No.", "Variant Code", "Lot No.", "Serial No.", false, EntriesExist);
                    if EntriesExist then
                        "Expiration Date" := ExpDate
                    else
                        "Expiration Date" := WhseEntry."Expiration Date";
                    "Phys. Inventory" := true;

                    "Qty. (Calculated)" := Round(WhseEntry."Qty. (Base)" / ItemUOM."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    "Qty. (Calculated) (Base)" := WhseEntry."Qty. (Base)";

                    Validate("Qty. (Phys. Inventory)", "Qty. (Calculated)");
                    Validate("Qty. (Phys. Inventory) (Base)", WhseEntry."Qty. (Base)");

                    if Location."Use ADCS" then
                        Validate("Qty. (Phys. Inventory)", 0);
                    "Registering No. Series" := WhseJnlBatch."Registering No. Series";
                    "Whse. Document Type" :=
                      "Whse. Document Type"::"Whse. Phys. Inventory";
                    if WhseJnlBatch."Reason Code" <> '' then
                        "Reason Code" := WhseJnlBatch."Reason Code";
                    "Phys Invt Counting Period Code" := PhysInvtCountCode;
                    "Phys Invt Counting Period Type" := CycleSourceType;

                    OnBeforeWhseJnlLineInsert(WhseJnlLine, WhseEntry);
                    Insert(true);
                    OnAfterWhseJnlLineInsert(WhseJnlLine);
                end;
                if WhseEntry.Find('+') then;
                WhseEntry.SetRange("Lot No.");
                WhseEntry.SetRange("Serial No.");
            until WhseEntry.Next = 0;
        end;
    end;

    procedure InitializeRequest(NewRegisteringDate: Date; WhseDocNo: Code[20]; ItemsNotOnInvt: Boolean)
    begin
        RegisteringDate := NewRegisteringDate;
        NextDocNo := WhseDocNo;
        ZeroQty := ItemsNotOnInvt;
    end;

    procedure InitializePhysInvtCount(PhysInvtCountCode2: Code[10]; CycleSourceType2: Option " ",Item,SKU)
    begin
        PhysInvtCountCode := PhysInvtCountCode2;
        CycleSourceType := CycleSourceType2;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure SkipCycleSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if CycleSourceType = CycleSourceType::Item then
            if SKU.ReadPermission then
                if SKU.Get(LocationCode, ItemNo, VariantCode) then
                    exit(true);
        exit(false);
    end;

    procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then begin
            Location.Get(LocationCode);
            Location.TestField("Adjustment Bin Code");
            Bin.Get(Location.Code, Location."Adjustment Bin Code");
            Bin.TestField("Zone Code");
        end;
    end;

    procedure SetProposalMode(NewValue: Boolean)
    begin
        StockProposal := NewValue;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseJnlLineInsert(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlLineInsert(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;
}

