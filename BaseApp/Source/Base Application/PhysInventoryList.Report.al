report 722 "Phys. Inventory List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PhysInventoryList.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Physical Inventory List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PageLoop; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ShowLotSN; ShowLotSN)
            {
            }
            column(CaptionFilter_ItemJnlBatch; "Item Journal Batch".TableCaption + ': ' + ItemJnlBatchFilter)
            {
            }
            column(ItemJnlBatchFilter; ItemJnlBatchFilter)
            {
            }
            column(CaptionFilter_ItemJnlLine; "Item Journal Line".TableCaption + ': ' + ItemJnlLineFilter)
            {
            }
            column(ItemJnlLineFilter; ItemJnlLineFilter)
            {
            }
            column(ShowQtyCalculated; ShowQtyCalculated)
            {
            }
            column(Note1; Note1Lbl)
            {
            }
            column(SummaryPerItem; SummaryPerItemLbl)
            {
            }
            column(ShowNote; ShowNote)
            {
            }
            column(PhysInventoryListCaption; PhysInventoryListCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemJnlLinePostDtCaption; ItemJnlLinePostDtCaptionLbl)
            {
            }
            column(GetShorDimCodeCaption1; CaptionClassTranslate('1,1,1'))
            {
            }
            column(GetShorDimCodeCaption2; CaptionClassTranslate('1,1,2'))
            {
            }
            column(QtyPhysInventoryCaption; QtyPhysInventoryCaptionLbl)
            {
            }
            dataitem("Item Journal Batch"; "Item Journal Batch")
            {
                RequestFilterFields = "Journal Template Name", Name;
                column(TemplateName_ItemJnlBatch; "Journal Template Name")
                {
                }
                column(Name_ItemJournalBatch; Name)
                {
                }
                dataitem("Item Journal Line"; "Item Journal Line")
                {
                    DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                    DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Location Code", "Bin Code";
                    column(PostingDt_ItemJournalLine; Format("Posting Date"))
                    {
                    }
                    column(DocNo_ItemJournalLine; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ItemNo_ItemJournalLine; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Desc_ItemJournalLine; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(ShotcutDim1Code_ItemJnlLin; "Shortcut Dimension 1 Code")
                    {
                    }
                    column(ShotcutDim2Code_ItemJnlLin; "Shortcut Dimension 2 Code")
                    {
                    }
                    column(LocCode_ItemJournalLine; "Location Code")
                    {
                        IncludeCaption = true;
                    }
                    column(QtyCalculated_ItemJnlLin; "Qty. (Calculated)")
                    {
                        IncludeCaption = true;
                    }
                    column(BinCode_ItemJournalLine; "Bin Code")
                    {
                        IncludeCaption = true;
                    }
                    column(Note; Note)
                    {
                    }
                    column(ShowSummary; ShowSummary)
                    {
                    }
                    column(LineNo_ItemJournalLine; "Line No.")
                    {
                    }
                    dataitem(ItemTrackingSpecification; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(LotNoCaption; GetLotNoCaption)
                        {
                        }
                        column(SerialNoCaption; GetSerialNoCaption)
                        {
                        }
                        column(QuantityBaseCaption; GetQuantityBaseCaption)
                        {
                        }
                        column(ReservEntryBufferLotNo; ReservEntryBuffer."Lot No.")
                        {
                        }
                        column(ReservEntryBufferSerialNo; ReservEntryBuffer."Serial No.")
                        {
                        }
                        column(ReservEntryBufferQtyBase; ReservEntryBuffer."Quantity (Base)")
                        {
                            DecimalPlaces = 0 : 0;
                        }
                        column(SummaryperItemCaption; SummaryperItemCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                ReservEntryBuffer.FindSet
                            else
                                ReservEntryBuffer.Next;
                        end;

                        trigger OnPreDataItem()
                        begin
                            ReservEntryBuffer.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
                            ReservEntryBuffer.SetRange("Source ID", "Item Journal Line"."Journal Template Name");
                            ReservEntryBuffer.SetRange("Source Ref. No.", "Item Journal Line"."Line No.");
                            ReservEntryBuffer.SetRange("Source Type", DATABASE::"Item Journal Line");
                            ReservEntryBuffer.SetFilter("Source Subtype", '=%1', ReservEntryBuffer."Source Subtype"::"0");
                            ReservEntryBuffer.SetRange("Source Batch Name", "Item Journal Line"."Journal Batch Name");

                            if ReservEntryBuffer.IsEmpty then
                                CurrReport.Break();
                            SetRange(Number, 1, ReservEntryBuffer.Count);

                            GetLotNoCaption := ReservEntryBuffer.FieldCaption("Lot No.");
                            GetSerialNoCaption := ReservEntryBuffer.FieldCaption("Serial No.");
                            GetQuantityBaseCaption := ReservEntryBuffer.FieldCaption("Quantity (Base)");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ShowLotSN then begin
                            Note := '';
                            ShowSummary := false;
                            if "Bin Code" <> '' then
                                if not ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then begin
                                    Note := NoteTxt;
                                    ShowSummary := true;
                                end;
                            Clear(ReservEntryBuffer);
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ItemJournalTemplate.Get("Journal Template Name") then
                        if ItemJournalTemplate.Type <> ItemJournalTemplate.Type::"Phys. Inventory" then
                            CurrReport.Skip();
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowCalculatedQty; ShowQtyCalculated)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Qty. (Calculated)';
                        ToolTip = 'Specifies if you want the report to show the calculated quantity of the items.';
                    }
                    field(ShowSerialLotNumber; ShowLotSN)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Show Serial/Lot Number';
                        ToolTip = 'Specifies if you want the report to show lot and serial numbers.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemJnlLineFilter := "Item Journal Line".GetFilters;
        ItemJnlBatchFilter := "Item Journal Batch".GetFilters;
        if ShowLotSN then begin
            ShowNote := false;
            ItemJnlLine.CopyFilters("Item Journal Line");
            "Item Journal Batch".CopyFilter("Journal Template Name", ItemJnlLine."Journal Template Name");
            "Item Journal Batch".CopyFilter(Name, ItemJnlLine."Journal Batch Name");
            CreateSNLotEntries(ItemJnlLine);
        end;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        ReservEntryBuffer: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemJnlLineFilter: Text;
        ItemJnlBatchFilter: Text;
        Note: Text[1];
        ShowQtyCalculated: Boolean;
        ShowLotSN: Boolean;
        ShowNote: Boolean;
        ShowSummary: Boolean;
        NoteTxt: Label '*', Locked = true;
        EntryNo: Integer;
        GetLotNoCaption: Text[80];
        GetSerialNoCaption: Text[80];
        GetQuantityBaseCaption: Text[80];
        Note1Lbl: Label '*Note:';
        SummaryPerItemLbl: Label 'Your system is set up to use Bin Mandatory and not SN/Lot Warehouse Tracking. Therefore, you will not see serial/lot numbers by bin but merely as a summary per item.';
        PhysInventoryListCaptionLbl: Label 'Phys. Inventory List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemJnlLinePostDtCaptionLbl: Label 'Posting Date';
        QtyPhysInventoryCaptionLbl: Label 'Qty. (Phys. Inventory)';
        SummaryperItemCaptionLbl: Label 'Summary per Item *';

    procedure Initialize(ShowQtyCalculated2: Boolean)
    begin
        ShowQtyCalculated := ShowQtyCalculated2;
    end;

    local procedure CreateSNLotEntries(var ItemJnlLine: Record "Item Journal Line")
    begin
        EntryNo := 0;
        if ItemJnlLine.FindSet then
            repeat
                if ItemJnlLine."Bin Code" <> '' then begin
                    if ItemTrackingMgt.GetWhseItemTrkgSetup(ItemJnlLine."Item No.") then
                        PickSNLotFromWhseEntry(ItemJnlLine."Item No.",
                          ItemJnlLine."Variant Code", ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine."Unit of Measure Code")
                    else begin
                        CreateSummary(ItemJnlLine);
                        ShowNote := true;
                    end;
                end
                else begin
                    if DirectedPutAwayAndPick(ItemJnlLine."Location Code") then
                        CreateSummary(ItemJnlLine)
                    else
                        PickSNLotFromILEntry(ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Location Code");
                end;
            until ItemJnlLine.Next = 0;
    end;

    local procedure PickSNLotFromILEntry(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", "Location Code");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        if ItemJnlLine."Qty. (Phys. Inventory)" = 0 then  // Item Not on Inventory, show old SN/Lot
            ItemLedgEntry.SetRange(Open, false)
        else
            ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange("Variant Code", VariantCode);
        ItemLedgEntry.SetRange("Location Code", LocationCode);
        ItemLedgEntry.SetFilter("Item Tracking", '<>%1', ItemLedgEntry."Item Tracking"::None);

        if ItemLedgEntry.FindSet then
            repeat
                CreateReservEntry(ItemJnlLine, ItemLedgEntry."Remaining Quantity",
                  ItemLedgEntry."Serial No.", ItemLedgEntry."Lot No.", ItemLedgEntry."Item Tracking");
            until ItemLedgEntry.Next = 0;
    end;

    local procedure PickSNLotFromWhseEntry(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UnitOM: Code[10])
    var
        WhseEntry: Record "Warehouse Entry";
        ItemTrackg: Option "None","Lot No.","Lot and Serial No.","Serial No.";
    begin
        WhseEntry.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code",
          "Lot No.", "Serial No.", "Entry Type");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Bin Code", BinCode);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Variant Code", VariantCode);
        WhseEntry.SetRange("Unit of Measure Code", UnitOM);

        if WhseEntry.FindSet then
            repeat
                if (WhseEntry."Lot No." <> '') and (WhseEntry."Serial No." <> '') then
                    CreateReservEntry(ItemJnlLine, WhseEntry."Qty. (Base)",
                      WhseEntry."Serial No.", WhseEntry."Lot No.", ItemTrackg::"Lot and Serial No.")
                else begin
                    if WhseEntry."Lot No." <> '' then
                        CreateReservEntry(ItemJnlLine, WhseEntry."Qty. (Base)",
                          WhseEntry."Serial No.", WhseEntry."Lot No.", ItemTrackg::"Lot No.");
                    if WhseEntry."Serial No." <> '' then
                        CreateReservEntry(ItemJnlLine, WhseEntry."Qty. (Base)",
                          WhseEntry."Serial No.", WhseEntry."Lot No.", ItemTrackg::"Serial No.");
                end;
            until WhseEntry.Next = 0;
    end;

    local procedure CreateReservEntry(ItemJournalLine: Record "Item Journal Line"; Qty: Decimal; SerialNo: Code[50]; LotNo: Code[50]; ItemTracking: Option "None","Lot No.","Lot and Serial No.","Serial No.")
    var
        FoundRec: Boolean;
    begin
        ReservEntryBuffer.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Item Tracking", "Reservation Status", "Lot No.", "Serial No.");
        ReservEntryBuffer.SetRange("Item No.", ItemJournalLine."Item No.");
        ReservEntryBuffer.SetRange("Variant Code", ItemJournalLine."Variant Code");
        ReservEntryBuffer.SetRange("Location Code", ItemJournalLine."Location Code");
        ReservEntryBuffer.SetRange("Reservation Status", ReservEntryBuffer."Reservation Status"::Prospect);
        ReservEntryBuffer.SetRange("Item Tracking", ItemTracking);
        ReservEntryBuffer.SetRange("Serial No.", SerialNo);
        ReservEntryBuffer.SetRange("Lot No.", LotNo);

        if ReservEntryBuffer.FindSet then begin
            repeat
                if (ReservEntryBuffer."Source Ref. No." = ItemJournalLine."Line No.") and
                   (ReservEntryBuffer."Source ID" = ItemJournalLine."Journal Template Name") and
                   (ReservEntryBuffer."Source Batch Name" = ItemJournalLine."Journal Batch Name")
                then
                    FoundRec := true;
            until (ReservEntryBuffer.Next = 0) or FoundRec;
        end;

        if not FoundRec then begin
            EntryNo += 1;
            ReservEntryBuffer."Entry No." := EntryNo;
            ReservEntryBuffer."Item No." := ItemJournalLine."Item No.";
            ReservEntryBuffer."Location Code" := ItemJournalLine."Location Code";
            ReservEntryBuffer."Quantity (Base)" := Qty;
            ReservEntryBuffer."Variant Code" := ItemJournalLine."Variant Code";
            ReservEntryBuffer."Reservation Status" := ReservEntryBuffer."Reservation Status"::Prospect;
            ReservEntryBuffer."Creation Date" := WorkDate;
            ReservEntryBuffer."Source Type" := DATABASE::"Item Journal Line";
            ReservEntryBuffer."Source ID" := ItemJournalLine."Journal Template Name";
            ReservEntryBuffer."Source Batch Name" := ItemJournalLine."Journal Batch Name";
            ReservEntryBuffer."Source Ref. No." := ItemJournalLine."Line No.";
            ReservEntryBuffer."Qty. per Unit of Measure" := ItemJournalLine."Qty. per Unit of Measure";
            ReservEntryBuffer."Serial No." := SerialNo;
            ReservEntryBuffer."Lot No." := LotNo;
            ReservEntryBuffer."Item Tracking" := ItemTracking;
            ReservEntryBuffer.Insert();
        end
        else begin
            ReservEntryBuffer."Quantity (Base)" += Qty;
            ReservEntryBuffer.Modify();
        end;
    end;

    local procedure DirectedPutAwayAndPick(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);
        Location.Get(LocationCode);
        exit(Location."Directed Put-away and Pick");
    end;

    local procedure CreateSummary(var ItemJnlLine1: Record "Item Journal Line")
    var
        ItemJnlLine2: Record "Item Journal Line";
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        NewGroup: Boolean;
    begin
        // Create SN/Lot entry only for the last journal line in the group
        ItemNo := ItemJnlLine1."Item No.";
        VariantCode := ItemJnlLine1."Variant Code";
        LocationCode := ItemJnlLine1."Location Code";
        NewGroup := false;
        ItemJnlLine2 := ItemJnlLine1;
        repeat
            if (ItemNo <> ItemJnlLine1."Item No.") or
               (VariantCode <> ItemJnlLine1."Variant Code") or
               (LocationCode <> ItemJnlLine1."Location Code")
            then
                NewGroup := true
            else
                ItemJnlLine2 := ItemJnlLine1;
        until (ItemJnlLine1.Next = 0) or NewGroup;
        ItemJnlLine1 := ItemJnlLine2;
        PickSNLotFromILEntry(ItemJnlLine1."Item No.", ItemJnlLine1."Variant Code", ItemJnlLine1."Location Code");
    end;
}

