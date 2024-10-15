namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Costing;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;
using System.Globalization;

table 339 "Item Application Entry"
{
    Caption = 'Item Application Entry';
    DrillDownPageID = "Item Application Entries";
    LookupPageID = "Item Application Entries";
    Permissions = TableData "Item Application Entry" = rm,
                  TableData "Item Application Entry History" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(3; "Inbound Item Entry No."; Integer)
        {
            Caption = 'Inbound Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(4; "Outbound Item Entry No."; Integer)
        {
            Caption = 'Outbound Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Transferred-from Entry No."; Integer)
        {
            Caption = 'Transferred-from Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(25; "Creation Date"; DateTime)
        {
            Caption = 'Creation Date';
        }
        field(26; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(27; "Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
        }
        field(28; "Last Modified By User"; Code[50])
        {
            Caption = 'Last Modified By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5800; "Cost Application"; Boolean)
        {
            Caption = 'Cost Application';
        }
        field(5804; "Output Completely Invd. Date"; Date)
        {
            Caption = 'Output Completely Invd. Date';
        }
        field(5805; "Outbound Entry is Updated"; Boolean)
        {
            Caption = 'Outbound Entry is Updated';
            InitValue = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Posting Date", "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application")
        {
            IncludedFields = Quantity;
        }
        key(Key3; "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.")
        {
            IncludedFields = "Inbound Item Entry No.", "Outbound Entry is Updated";
        }
        key(Key4; "Transferred-from Entry No.", "Cost Application")
        {
        }
        key(Key5; "Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application")
        {
        }
        key(Key6; "Item Ledger Entry No.", "Output Completely Invd. Date")
        {
        }
        key(Key9; "Inbound Item Entry No.", "Transferred-from Entry No.", "Item Ledger Entry No.")
        {
            IncludedFields = "Outbound Item Entry No.", "Posting Date", Quantity;
        }
        key(Key10; "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application")
        {
            IncludedFields = "Outbound Entry is Updated";
        }
    }

    fieldgroups
    {
    }

    var
        TempVisitedItemApplnEntry: Record "Item Application Entry" temporary;
        TempItemLedgEntryInChainNo: Record "Integer" temporary;
        SearchedItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntryTypesUsed: Dictionary of [Enum "Item Ledger Entry Type", Boolean];
        TrackChain: Boolean;
        MaxValuationDate: Date;

        Text001: Label 'You have to run the %1 batch job, before you can revalue %2 %3.';

    procedure AppliedOutbndEntryExists(InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean; FilterOnOnlyCostNotAdjusted: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        if IsCostApplication then
            SetRange("Cost Application", true);

        if FilterOnOnlyCostNotAdjusted then
            SetRange("Outbound Entry is Updated", false);

        exit(FindSet());
    end;

    procedure AppliedInbndTransEntryExists(InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        if IsEmpty() then
            exit(false);

        Reset();
        SetCurrentKey("Transferred-from Entry No.", "Cost Application");
        SetRange("Transferred-from Entry No.", InbndItemLedgEntryNo);
        if IsCostApplication then
            SetRange("Cost Application", true);
        if IsEmpty() then
            exit(false);

        FindSet();
        exit(true);
    end;

    procedure AppliedInbndEntryExists(OutbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.");
        SetRange("Outbound Item Entry No.", OutbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', OutbndItemLedgEntryNo);
        SetRange("Transferred-from Entry No.", 0);
        if IsCostApplication then
            SetRange("Cost Application", true);
        exit(FindSet());
    end;

    procedure AppliedFromEntryExists(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        SetRange("Item Ledger Entry No.", InbndItemLedgEntryNo);
        exit(FindSet());
    end;

    procedure GetInboundEntriesTheOutbndEntryAppliedTo(OutbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        SetRange("Outbound Item Entry No.", OutbndItemLedgEntryNo);
        SetRange("Item Ledger Entry No.", OutbndItemLedgEntryNo);
        SetFilter("Inbound Item Entry No.", '<>%1', 0);
        exit(FindSet());
    end;

    procedure GetOutboundEntriesAppliedToTheInboundEntry(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        exit(FindSet());
    end;

    procedure CheckAppliedFromEntryToAdjust(InbndItemLedgEntryNo: Integer)
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        ObjTransl: Record "Object Translation";
    begin
        if AppliedFromEntryExists(InbndItemLedgEntryNo) then
            repeat
                OutbndItemLedgEntry.SetLoadFields("Applied Entry to Adjust");
                OutbndItemLedgEntry.Get("Outbound Item Entry No.");
                if OutbndItemLedgEntry."Applied Entry to Adjust" then
                    Error(
                      Text001,
                      ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Adjust Cost - Item Entries"),
                      OutbndItemLedgEntry.TableCaption(), InbndItemLedgEntryNo);
            until Next() = 0;
    end;

    procedure CostReceiver(): Integer
    begin
        if "Outbound Item Entry No." = 0 then
            exit(0);
        if "Item Ledger Entry No." = "Outbound Item Entry No." then
            exit("Outbound Item Entry No.");
        if "Item Ledger Entry No." = "Inbound Item Entry No." then
            exit("Inbound Item Entry No.");
        exit(0);
    end;

    procedure "Fixed"() Result: Boolean
    var
        InboundItemLedgerEntry: Record "Item Ledger Entry";
        OutboundItemLedgerEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        OnBeforeFixed(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Outbound Item Entry No." = 0 then
            exit(false);
        InboundItemLedgerEntry.SetLoadFields("Applies-to Entry");
        if not InboundItemLedgerEntry.Get("Inbound Item Entry No.") then
            exit(true);
        if InboundItemLedgerEntry."Applies-to Entry" = "Outbound Item Entry No." then
            exit(true);
        OutboundItemLedgerEntry.SetLoadFields("Applies-to Entry");
        if not OutboundItemLedgerEntry.Get("Outbound Item Entry No.") then
            exit(true);
        if OutboundItemLedgerEntry."Applies-to Entry" = "Inbound Item Entry No." then
            exit(true);
        exit(false);
    end;

    procedure InsertHistory(): Integer
    var
        ItemApplnEntryHistory: Record "Item Application Entry History";
        EntryNo: Integer;
    begin
        ItemApplnEntryHistory.SetCurrentKey("Primary Entry No.");
        if not ItemApplnEntryHistory.FindLast() then
            EntryNo := 1;
        EntryNo := ItemApplnEntryHistory."Primary Entry No.";
        ItemApplnEntryHistory.TransferFields(Rec, true);
        ItemApplnEntryHistory."Deleted Date" := CurrentDateTime;
        ItemApplnEntryHistory."Deleted By User" := UserId;
        ItemApplnEntryHistory."Primary Entry No." := EntryNo + 1;
        ItemApplnEntryHistory.Insert();
        exit(ItemApplnEntryHistory."Primary Entry No.");
    end;

    procedure CostApplication(): Boolean
    begin
        exit((Quantity > 0) and ("Item Ledger Entry No." = "Inbound Item Entry No."))
    end;

    procedure CheckIsCyclicalLoop(CheckItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        if CheckItemLedgEntry."Entry No." = FromItemLedgEntry."Entry No." then
            exit(true);
        TempVisitedItemApplnEntry.DeleteAll();
        TempItemLedgEntryInChainNo.DeleteAll();

        if FromItemLedgEntry.Positive then begin
            if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, FromItemLedgEntry."Entry No.") then
                exit(true);
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry, FromItemLedgEntry."Entry No."));
        end;
        if FromItemLedgEntry."Entry Type" = FromItemLedgEntry."Entry Type"::Consumption then
            if CheckCyclicProdCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then
                exit(true);
        if FromItemLedgEntry."Entry Type" = FromItemLedgEntry."Entry Type"::"Assembly Consumption" then
            if CheckCyclicAsmCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then
                exit(true);
        exit(CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry, FromItemLedgEntry."Entry No."));
    end;

    local procedure CheckCyclicProdCyclicalLoop(CheckItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckCyclicProdCyclicalLoop(Rec, CheckItemLedgEntry, ItemLedgEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsItemEverOutput(ItemLedgEntry."Item No.") then
            exit(false);

        if ItemLedgEntry."Order Type" <> ItemLedgEntry."Order Type"::Production then
            exit(false);
        if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Output then
            exit(false);
        if ItemLedgEntry.Positive then
            exit(false);
        if (CheckItemLedgEntry."Entry Type" = CheckItemLedgEntry."Entry Type"::Output) and
           (ItemLedgEntry."Order Type" = CheckItemLedgEntry."Order Type") and
           (ItemLedgEntry."Order No." = CheckItemLedgEntry."Order No.") and
           (ItemLedgEntry."Order Line No." = CheckItemLedgEntry."Order Line No.")
        then
            exit(true);

        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type");
        ItemLedgEntry.SetRange("Order No.", ItemLedgEntry."Order No.");
        ItemLedgEntry.SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        if MaxValuationDate <> 0D then
            ItemLedgEntry.SetRange("Posting Date", 0D, MaxValuationDate);
        ItemLedgEntry.SetLoadFields(Positive);
        if ItemLedgEntry.FindSet() then
            repeat
                if TrackChain then begin
                    TempItemLedgEntryInChainNo.Number := ItemLedgEntry."Entry No.";
                    if TempItemLedgEntryInChainNo.Insert() then;

                    if SearchedItemLedgerEntryFound(ItemLedgEntry) then
                        exit(true);
                end;

                if ItemLedgEntry."Entry No." = CheckItemLedgEntry."Entry No." then
                    exit(true);

                if ItemLedgEntry.Positive then
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, ItemLedgEntry."Entry No.") then
                        exit(true);
            until ItemLedgEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckCyclicAsmCyclicalLoop(CheckItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        if ItemLedgEntry."Order Type" <> ItemLedgEntry."Order Type"::Assembly then
            exit(false);
        if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::"Assembly Output" then
            exit(false);
        if ItemLedgEntry.Positive then
            exit(false);
        if (CheckItemLedgEntry."Entry Type" = CheckItemLedgEntry."Entry Type"::"Assembly Output") and
           (ItemLedgEntry."Order Type" = CheckItemLedgEntry."Order Type") and
           (ItemLedgEntry."Order No." = CheckItemLedgEntry."Order No.")
        then
            exit(true);

        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type");
        ItemLedgEntry.SetRange("Order No.", ItemLedgEntry."Order No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Assembly Output");
        if MaxValuationDate <> 0D then
            ItemLedgEntry.SetRange("Posting Date", 0D, MaxValuationDate);
        ItemLedgEntry.SetLoadFields(Positive);
        if ItemLedgEntry.FindSet() then
            repeat
                if TrackChain then begin
                    TempItemLedgEntryInChainNo.Number := ItemLedgEntry."Entry No.";
                    if TempItemLedgEntryInChainNo.Insert() then;

                    if SearchedItemLedgerEntryFound(ItemLedgEntry) then
                        exit(true);
                end;

                if ItemLedgEntry."Entry No." = CheckItemLedgEntry."Entry No." then
                    exit(true);

                if ItemLedgEntry.Positive then
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, ItemLedgEntry."Entry No.") then
                        exit(true);
            until ItemLedgEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedOutbndEntryExists(EntryNo, false, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry, ItemApplnEntry, EntryNo, true));
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndEntryExists(EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry, ItemApplnEntry, EntryNo, false));
        exit(false);
    end;

    local procedure CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if not ItemLedgerEntryTypeIsUsed("Item Ledger Entry Type"::Transfer) then
            exit(false);

        if ItemApplnEntry.AppliedInbndTransEntryExists(EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry, ItemApplnEntry, EntryNo, false));
        exit(false);
    end;

    local procedure CheckCyclicFwdToProdOutput(CheckItemLedgEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgEntry.Get(EntryNo) then
            exit(false);
        exit(CheckCyclicProdCyclicalLoop(CheckItemLedgEntry, ItemLedgEntry));
    end;

    local procedure CheckCyclicFwdToAsmOutput(CheckItemLedgEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgEntry.Get(EntryNo) then
            exit(false);
        exit(CheckCyclicAsmCyclicalLoop(CheckItemLedgEntry, ItemLedgEntry));
    end;

    local procedure CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry: Record "Item Ledger Entry"; var ItemApplnEntry: Record "Item Application Entry"; FromEntryNo: Integer; IsPositiveToNegativeFlow: Boolean): Boolean
    var
        ToEntryNo: Integer;
    begin
        if EntryIsVisited(FromEntryNo) then
            exit(false);

        repeat
            if IsPositiveToNegativeFlow then
                ToEntryNo := ItemApplnEntry."Outbound Item Entry No."
            else
                ToEntryNo := ItemApplnEntry."Inbound Item Entry No.";

            if CheckLatestItemLedgEntryValuationDate(ItemApplnEntry."Item Ledger Entry No.", MaxValuationDate) then begin
                if TrackChain then begin
                    TempItemLedgEntryInChainNo.Number := ToEntryNo;
                    if TempItemLedgEntryInChainNo.Insert() then;
                end;

                if ToEntryNo = CheckItemLedgEntry."Entry No." then
                    exit(true);

                if not IsPositiveToNegativeFlow then begin
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, ToEntryNo) then
                        exit(true);
                end else begin
                    if CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry, ToEntryNo) then
                        exit(true);
                    if CheckCyclicFwdToProdOutput(CheckItemLedgEntry, ToEntryNo) then
                        exit(true);
                    if CheckCyclicFwdToAsmOutput(CheckItemLedgEntry, ToEntryNo) then
                        exit(true);
                end;
            end;
        until ItemApplnEntry.Next() = 0;

        if IsPositiveToNegativeFlow then
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry, FromEntryNo));
        exit(false);
    end;

    local procedure EntryIsVisited(EntryNo: Integer): Boolean
    begin
        if TempVisitedItemApplnEntry.Get(EntryNo) then begin
            // This is to take into account quantity flows from an inbound entry to an inbound transfer
            if TempVisitedItemApplnEntry.Quantity = 2 then
                exit(true);
            TempVisitedItemApplnEntry.Quantity := TempVisitedItemApplnEntry.Quantity + 1;
            TempVisitedItemApplnEntry.Modify();
            exit(false);
        end;
        TempVisitedItemApplnEntry.Init();
        TempVisitedItemApplnEntry."Entry No." := EntryNo;
        TempVisitedItemApplnEntry.Quantity := TempVisitedItemApplnEntry.Quantity + 1;
        TempVisitedItemApplnEntry.Insert();
        exit(false);
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure GetVisitedEntries(FromItemLedgEntry: Record "Item Ledger Entry"; var ItemLedgEntryInChain: Record "Item Ledger Entry"; WithinValuationDate: Boolean)
    var
        ToItemLedgEntry: Record "Item Ledger Entry";
        DummyItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        MaxValuationDate := 0D;
        if WithinValuationDate then begin
            ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
            ValueEntry.SetRange("Item Ledger Entry No.", FromItemLedgEntry."Entry No.");
            ValueEntry.SetLoadFields("Valuation Date");
            ValueEntry.FindLast();
            MaxValuationDate := AvgCostEntryPointHandler.GetMaxValuationDate(FromItemLedgEntry, ValueEntry);
        end;

        TrackChain := true;
        ItemLedgEntryInChain.Reset();
        ItemLedgEntryInChain.DeleteAll();
        DummyItemLedgEntry.Init();
        DummyItemLedgEntry."Entry No." := -1;
        DummyItemLedgEntry.CollectItemLedgerEntryTypesUsed(ItemLedgerEntryTypesUsed, '');
        CheckIsCyclicalLoop(DummyItemLedgEntry, FromItemLedgEntry);
        if TempItemLedgEntryInChainNo.FindSet() then
            repeat
                ToItemLedgEntry.Get(TempItemLedgEntryInChainNo.Number);
                ItemLedgEntryInChain := ToItemLedgEntry;
                ItemLedgEntryInChain.Insert();
            until TempItemLedgEntryInChainNo.Next() = 0;
    end;

    procedure OutboundApplied(EntryNo: Integer; SameType: Boolean): Decimal
    var
        Applications: Record "Item Application Entry";
        ItemEntry: Record "Item Ledger Entry";
        OriginalEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        OriginalEntry.SetLoadFields("Entry Type");
        if not OriginalEntry.Get(EntryNo) then
            exit(0);
        if OriginalEntry."Entry Type" = OriginalEntry."Entry Type"::Transfer then
            exit(0);
        Applications.SetCurrentKey("Outbound Item Entry No.");
        Applications.SetRange("Outbound Item Entry No.", EntryNo);
        Applications.SetRange("Item Ledger Entry No.", EntryNo);
        Quantity := 0;
        if Applications.FindSet() then
            repeat
                ItemEntry.SetLoadFields("Entry Type");
                if ItemEntry.Get(Applications."Inbound Item Entry No.") then
                    if SameType then begin
                        if ItemEntry."Entry Type" = OriginalEntry."Entry Type" then
                            Quantity := Quantity + Applications.Quantity
                    end else
                        Quantity := Quantity + Applications.Quantity;
            until Applications.Next() <= 0;
        exit(Quantity);
    end;

    procedure InboundApplied(EntryNo: Integer; SameType: Boolean): Decimal
    var
        Applications: Record "Item Application Entry";
        ItemEntry: Record "Item Ledger Entry";
        OriginalEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        OriginalEntry.SetLoadFields("Entry Type", Positive);
        if not OriginalEntry.Get(EntryNo) then
            exit(0);
        if OriginalEntry."Entry Type" = OriginalEntry."Entry Type"::Transfer then
            exit(0);
        Applications.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        Applications.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        Applications.SetRange("Inbound Item Entry No.", EntryNo);
        if not OriginalEntry.Positive then
            Applications.SetRange("Item Ledger Entry No.", EntryNo);
        Quantity := 0;
        if Applications.FindSet() then
            repeat
                ItemEntry.SetLoadFields("Entry Type", "Applies-to Entry");
                if ItemEntry.Get(Applications."Outbound Item Entry No.") then
                    if SameType then begin
                        if (ItemEntry."Entry Type" = OriginalEntry."Entry Type") or
                           (ItemEntry."Applies-to Entry" <> 0)
                        then
                            Quantity := Quantity + Applications.Quantity
                    end else
                        Quantity := Quantity + Applications.Quantity;
            until Applications.Next() = 0;
        exit(Quantity);
    end;

    procedure Returned(EntryNo: Integer): Decimal
    begin
        exit(-OutboundApplied(EntryNo, true) - InboundApplied(EntryNo, true));
    end;

    procedure ExistsBetween(ILE1: Integer; ILE2: Integer): Boolean
    var
        Applications: Record "Item Application Entry";
    begin
        Applications.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        Applications.SetRange("Inbound Item Entry No.", ILE1);
        Applications.SetRange("Outbound Item Entry No.", ILE2);
        if not Applications.IsEmpty() then
            exit(true);
        Applications.SetRange("Inbound Item Entry No.", ILE2);
        Applications.SetRange("Outbound Item Entry No.", ILE1);
        exit(not Applications.IsEmpty);
    end;

    local procedure IsItemEverOutput(ItemNo: Code[20]): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        exit(not ItemLedgEntry.IsEmpty());
    end;

    procedure SetOutboundsNotUpdated(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if not (ItemLedgEntry."Applied Entry to Adjust" or ItemLedgEntry.Open) then
            exit;

        if ItemLedgEntry.Quantity < 0 then
            exit;

        ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.");
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry."Entry No.");
        ItemApplnEntry.ModifyAll("Outbound Entry is Updated", false);
    end;

    procedure SetInboundToUpdated(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin

        ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.");
        ItemApplnEntry.SetRange("Outbound Item Entry No.", ItemLedgEntry."Entry No.");
        OnSetInboundToUpdatedOnAfterSetFilters(ItemApplnEntry);
        if ItemLedgEntry."Completely Invoiced" then
            if ItemApplnEntry.Count = 1 then begin
                ItemApplnEntry.FindFirst();
                ItemApplnEntry."Outbound Entry is Updated" := true;
                ItemApplnEntry.Modify();
            end;
    end;

    procedure IsAppliedFromIncrease(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetRange("Item Ledger Entry No.", InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        SetRange("Cost Application", true);
        exit(FindFirst());
    end;

    procedure IsOutbndItemApplEntryCostApplication(OutboundItemLedgEntryNo: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", OutboundItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", OutboundItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Cost Application", false);
        exit(ItemApplicationEntry.IsEmpty);
    end;

    local procedure CheckLatestItemLedgEntryValuationDate(ItemLedgerEntryNo: Integer; MaxDate: Date): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        if MaxDate = 0D then
            exit(true);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.SetLoadFields("Valuation Date");
        ValueEntry.FindLast();
        exit(ValueEntry."Valuation Date" <= MaxDate);
    end;

    procedure SetSearchedItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        SearchedItemLedgerEntry.Copy(ItemLedgerEntry);
    end;

    local procedure SearchedItemLedgerEntryFound(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        if SearchedItemLedgerEntry.GetFilters() = '' then
            exit(false);

        TempItemLedgerEntry := ItemLedgerEntry;
        TempItemLedgerEntry.Insert();
        TempItemLedgerEntry.CopyFilters(SearchedItemLedgerEntry);
        exit(not TempItemLedgerEntry.IsEmpty())
    end;

    local procedure ItemLedgerEntryTypeIsUsed(ItemLedgerEntryType: Enum "Item Ledger Entry Type"): Boolean
    begin
        if not ItemLedgerEntryTypesUsed.ContainsKey(ItemLedgerEntryType) then
            exit(true);

        exit(ItemLedgerEntryTypesUsed.Get(ItemLedgerEntryType));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFixed(ItemApplicationEntry: Record "Item Application Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetInboundToUpdatedOnAfterSetFilters(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCyclicProdCyclicalLoop(var ItemApplicationEntry: Record "Item Application Entry"; CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

