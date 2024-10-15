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
        TempVisitedItemApplicationEntry: Record "Item Application Entry" temporary;
        TempItemLedgerEntryInChainNo: Record "Integer" temporary;
        SearchedItemLedgerEntry: Record "Item Ledger Entry";
        TrackChain: Boolean;
        MaxValuationDate: Date;
        AppliedFromEntryToAdjustErr: Label 'You have to run the %1 batch job, before you can revalue %2 %3.', Comment = '%1 = Report::"Adjust Cost - Item Entries", %2 = Item Ledger Entry table caption, %3 = Inbound Item Ledger Entry No.';

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
        SetRange("Cost Application", IsCostApplication, true);
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
        OutbndItemLedgerEntry: Record "Item Ledger Entry";
        ObjTransl: Record "Object Translation";
    begin
        if AppliedFromEntryExists(InbndItemLedgEntryNo) then
            repeat
                OutbndItemLedgerEntry.SetLoadFields("Applied Entry to Adjust");
                OutbndItemLedgerEntry.Get("Outbound Item Entry No.");
                if OutbndItemLedgerEntry."Applied Entry to Adjust" then
                    Error(
                      AppliedFromEntryToAdjustErr,
                      ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, Report::"Adjust Cost - Item Entries"),
                      OutbndItemLedgerEntry.TableCaption(), InbndItemLedgEntryNo);
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
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        EntryNo: Integer;
    begin
        ItemApplicationEntryHistory.SetCurrentKey("Primary Entry No.");
        if not ItemApplicationEntryHistory.FindLast() then
            EntryNo := 1;
        EntryNo := ItemApplicationEntryHistory."Primary Entry No.";
        ItemApplicationEntryHistory.TransferFields(Rec, true);
        ItemApplicationEntryHistory."Deleted Date" := CurrentDateTime();
        ItemApplicationEntryHistory."Deleted By User" := CopyStr(UserId(), 1, MaxStrLen(ItemApplicationEntryHistory."Deleted By User"));
        ItemApplicationEntryHistory."Primary Entry No." := EntryNo + 1;
        ItemApplicationEntryHistory.Insert();
        exit(ItemApplicationEntryHistory."Primary Entry No.");
    end;

    procedure CostApplication(): Boolean
    begin
        exit((Quantity > 0) and ("Item Ledger Entry No." = "Inbound Item Entry No."))
    end;

    procedure CheckIsCyclicalLoop(CheckItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        if CheckItemLedgEntry."Entry No." = FromItemLedgEntry."Entry No." then
            exit(true);
        TempVisitedItemApplicationEntry.DeleteAll();
        TempItemLedgerEntryInChainNo.DeleteAll();

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

    local procedure CheckCyclicProdCyclicalLoop(CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckCyclicProdCyclicalLoop(Rec, CheckItemLedgerEntry, ItemLedgerEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsItemEverOutput(ItemLedgerEntry."Item No.") then
            exit(false);

        if ItemLedgerEntry."Order Type" <> ItemLedgerEntry."Order Type"::Production then
            exit(false);
        if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Output then
            exit(false);
        if ItemLedgerEntry.Positive then
            exit(false);
        if (CheckItemLedgerEntry."Entry Type" = CheckItemLedgerEntry."Entry Type"::Output) and
           (ItemLedgerEntry."Order Type" = CheckItemLedgerEntry."Order Type") and
           (ItemLedgerEntry."Order No." = CheckItemLedgerEntry."Order No.") and
           (ItemLedgerEntry."Order Line No." = CheckItemLedgerEntry."Order Line No.")
        then
            exit(true);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type");
        ItemLedgerEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        if MaxValuationDate <> 0D then
            ItemLedgerEntry.SetRange("Posting Date", 0D, MaxValuationDate);
        ItemLedgerEntry.SetLoadFields(Positive);
        if ItemLedgerEntry.FindSet() then
            repeat
                if TrackChain then begin
                    TempItemLedgerEntryInChainNo.Number := ItemLedgerEntry."Entry No.";
                    if TempItemLedgerEntryInChainNo.Insert() then;

                    if SearchedItemLedgerEntryFound(ItemLedgerEntry) then
                        exit(true);
                end;

                if ItemLedgerEntry."Entry No." = CheckItemLedgerEntry."Entry No." then
                    exit(true);

                if ItemLedgerEntry.Positive then
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry, ItemLedgerEntry."Entry No.") then
                        exit(true);
            until ItemLedgerEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckCyclicAsmCyclicalLoop(CheckItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    begin
        if ItemLedgerEntry."Order Type" <> ItemLedgerEntry."Order Type"::Assembly then
            exit(false);
        if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::"Assembly Output" then
            exit(false);
        if ItemLedgerEntry.Positive then
            exit(false);
        if (CheckItemLedgerEntry."Entry Type" = CheckItemLedgerEntry."Entry Type"::"Assembly Output") and
           (ItemLedgerEntry."Order Type" = CheckItemLedgerEntry."Order Type") and
           (ItemLedgerEntry."Order No." = CheckItemLedgerEntry."Order No.")
        then
            exit(true);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type");
        ItemLedgerEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Output");
        if MaxValuationDate <> 0D then
            ItemLedgerEntry.SetRange("Posting Date", 0D, MaxValuationDate);
        ItemLedgerEntry.SetLoadFields(Positive);
        if ItemLedgerEntry.FindSet() then
            repeat
                if TrackChain then begin
                    TempItemLedgerEntryInChainNo.Number := ItemLedgerEntry."Entry No.";
                    if TempItemLedgerEntryInChainNo.Insert() then;

                    if SearchedItemLedgerEntryFound(ItemLedgerEntry) then
                        exit(true);
                end;

                if ItemLedgerEntry."Entry No." = CheckItemLedgerEntry."Entry No." then
                    exit(true);

                if ItemLedgerEntry.Positive then
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry, ItemLedgerEntry."Entry No.") then
                        exit(true);
            until ItemLedgerEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemApplicationEntry.AppliedOutbndEntryExists(EntryNo, false, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry, ItemApplicationEntry, EntryNo, true));
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedInbnds(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemApplicationEntry.AppliedInbndEntryExists(EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry, ItemApplicationEntry, EntryNo, false));
        exit(false);
    end;

    local procedure CheckCyclicFwdToInbndTransfers(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemApplicationEntry.AppliedInbndTransEntryExists(EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry, ItemApplicationEntry, EntryNo, false));
        exit(false);
    end;

    local procedure CheckCyclicFwdToProdOutput(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgerEntry.Get(EntryNo) then
            exit(false);
        exit(CheckCyclicProdCyclicalLoop(CheckItemLedgerEntry, ItemLedgerEntry));
    end;

    local procedure CheckCyclicFwdToAsmOutput(CheckItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgerEntry.Get(EntryNo) then
            exit(false);
        exit(CheckCyclicAsmCyclicalLoop(CheckItemLedgerEntry, ItemLedgerEntry));
    end;

    local procedure CheckCyclicFwdToAppliedEntries(CheckItemLedgerEntry: Record "Item Ledger Entry"; var ItemApplicationEntry: Record "Item Application Entry"; FromEntryNo: Integer; IsPositiveToNegativeFlow: Boolean): Boolean
    var
        ToEntryNo: Integer;
    begin
        if EntryIsVisited(FromEntryNo) then
            exit(false);

        repeat
            if IsPositiveToNegativeFlow then
                ToEntryNo := ItemApplicationEntry."Outbound Item Entry No."
            else
                ToEntryNo := ItemApplicationEntry."Inbound Item Entry No.";

            if CheckLatestItemLedgerEntryValuationDate(ItemApplicationEntry."Item Ledger Entry No.", MaxValuationDate) then begin
                if TrackChain then begin
                    TempItemLedgerEntryInChainNo.Number := ToEntryNo;
                    if TempItemLedgerEntryInChainNo.Insert() then;
                end;

                if ToEntryNo = CheckItemLedgerEntry."Entry No." then
                    exit(true);

                if not IsPositiveToNegativeFlow then begin
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                end else begin
                    if CheckCyclicFwdToAppliedInbnds(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                    if CheckCyclicFwdToProdOutput(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                    if CheckCyclicFwdToAsmOutput(CheckItemLedgerEntry, ToEntryNo) then
                        exit(true);
                end;
            end;
        until ItemApplicationEntry.Next() = 0;

        if IsPositiveToNegativeFlow then
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgerEntry, FromEntryNo));
        exit(false);
    end;

    local procedure EntryIsVisited(EntryNo: Integer): Boolean
    begin
        if TempVisitedItemApplicationEntry.Get(EntryNo) then begin
            // This is to take into account quantity flows from an inbound entry to an inbound transfer
            if TempVisitedItemApplicationEntry.Quantity = 2 then
                exit(true);
            TempVisitedItemApplicationEntry.Quantity := TempVisitedItemApplicationEntry.Quantity + 1;
            TempVisitedItemApplicationEntry.Modify();
            exit(false);
        end;
        TempVisitedItemApplicationEntry.Init();
        TempVisitedItemApplicationEntry."Entry No." := EntryNo;
        TempVisitedItemApplicationEntry.Quantity := TempVisitedItemApplicationEntry.Quantity + 1;
        TempVisitedItemApplicationEntry.Insert();
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
        ToItemLedgerEntry: Record "Item Ledger Entry";
        DummyItemLedgerEntry: Record "Item Ledger Entry";
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
        DummyItemLedgerEntry.Init();
        DummyItemLedgerEntry."Entry No." := -1;
        CheckIsCyclicalLoop(DummyItemLedgerEntry, FromItemLedgEntry);
        if TempItemLedgerEntryInChainNo.FindSet() then
            repeat
                ToItemLedgerEntry.Get(TempItemLedgerEntryInChainNo.Number);
                ItemLedgEntryInChain := ToItemLedgerEntry;
                ItemLedgEntryInChain.Insert();
            until TempItemLedgerEntryInChainNo.Next() = 0;
    end;

    procedure OutboundApplied(EntryNo: Integer; SameType: Boolean): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OriginalItemLedgerEntry: Record "Item Ledger Entry";
        CalcQuantity: Decimal;
    begin
        OriginalItemLedgerEntry.SetLoadFields("Entry Type");
        if not OriginalItemLedgerEntry.Get(EntryNo) then
            exit(0);
        if OriginalItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type"::Transfer then
            exit(0);

        ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.");
        ItemApplicationEntry.SetLoadFields("Inbound Item Entry No.", Quantity);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", EntryNo);
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", EntryNo);
        CalcQuantity := 0;
        if ItemApplicationEntry.FindSet() then
            repeat
                ItemLedgerEntry.SetLoadFields("Entry Type");
                if ItemLedgerEntry.Get(ItemApplicationEntry."Inbound Item Entry No.") then
                    if SameType then begin
                        if ItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type" then
                            CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity
                    end else
                        CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity;
            until ItemApplicationEntry.Next() <= 0;
        exit(CalcQuantity);
    end;

    procedure InboundApplied(EntryNo: Integer; SameType: Boolean): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OriginalItemLedgerEntry: Record "Item Ledger Entry";
        CalcQuantity: Decimal;
    begin
        OriginalItemLedgerEntry.SetLoadFields("Entry Type", Positive);
        if not OriginalItemLedgerEntry.Get(EntryNo) then
            exit(0);
        if OriginalItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type"::Transfer then
            exit(0);

        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        ItemApplicationEntry.SetLoadFields("Outbound Item Entry No.", Quantity);
        ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", EntryNo);
        if not OriginalItemLedgerEntry.Positive then
            ItemApplicationEntry.SetRange("Item Ledger Entry No.", EntryNo);
        CalcQuantity := 0;
        if ItemApplicationEntry.FindSet() then
            repeat
                ItemLedgerEntry.SetLoadFields("Entry Type", "Applies-to Entry");
                if ItemLedgerEntry.Get(ItemApplicationEntry."Outbound Item Entry No.") then
                    if SameType then begin
                        if (ItemLedgerEntry."Entry Type" = OriginalItemLedgerEntry."Entry Type") or
                           (ItemLedgerEntry."Applies-to Entry" <> 0)
                        then
                            CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity
                    end else
                        CalcQuantity := CalcQuantity + ItemApplicationEntry.Quantity;
            until ItemApplicationEntry.Next() = 0;
        exit(CalcQuantity);
    end;

    procedure Returned(EntryNo: Integer): Decimal
    begin
        exit(-OutboundApplied(EntryNo, true) - InboundApplied(EntryNo, true));
    end;

    procedure ExistsBetween(ILE1: Integer; ILE2: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ILE1);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ILE2);
        if not ItemApplicationEntry.IsEmpty() then
            exit(true);

        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ILE2);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ILE1);
        exit(not ItemApplicationEntry.IsEmpty());
    end;

    local procedure IsItemEverOutput(ItemNo: Code[20]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        exit(not ItemLedgerEntry.IsEmpty());
    end;

    procedure SetOutboundsNotUpdated(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if not (ItemLedgEntry."Applied Entry to Adjust" or ItemLedgEntry.Open) then
            exit;

        if ItemLedgEntry.Quantity < 0 then
            exit;

        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry."Entry No.");
        OnSetOutboundsNotUpdatedOnAfterSetFilters(ItemApplicationEntry);
        ItemApplicationEntry.ModifyAll("Outbound Entry is Updated", false);
    end;

    procedure SetInboundToUpdated(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgEntry."Entry No.");
        OnSetInboundToUpdatedOnAfterSetFilters(ItemApplicationEntry);
        if ItemLedgEntry."Completely Invoiced" then
            if ItemApplicationEntry.Count() = 1 then begin
                ItemApplicationEntry.FindFirst();
                ItemApplicationEntry."Outbound Entry is Updated" := true;
                ItemApplicationEntry.Modify();
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
        exit(ItemApplicationEntry.IsEmpty());
    end;

    local procedure CheckLatestItemLedgerEntryValuationDate(ItemLedgerEntryNo: Integer; MaxDate: Date): Boolean
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

    [IntegrationEvent(false, false)]
    local procedure OnSetOutboundsNotUpdatedOnAfterSetFilters(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;
}

