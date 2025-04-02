// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000843 "Undo Prod. Posting Mgmt."
{
    var
        SourceCodeSetup: Record "Source Code Setup";
        ReverseEntriesMsg: Label 'To reverse these entries, correcting entries will be posted.';
        ReverseEntriesQst: Label 'Do you want to reverse the entries?';
        PostedSuccessfullyMsg: Label 'The journal lines were successfully posted.';
        CannotHandleEntryTypeErr: Label 'Cannot handle entry type %1 for correction posting of production.', Comment = '%1 - Entry Type';
        InvalidEntryTypeErr: Label 'Entry Type must be either Consumption or Output.';
        SubContractingErr: Label 'Entry cannot be reversed as it is linked to the subcontracting work center.';
        QuantityMustBeGreaterThanZeroErr: Label 'Quantity must be greater than 0 on %1 No. %2 to reverse the entry.', Comment = '%1 = Table Caption , %2 = Entry No.';
        QuantityMustBeLessThanZeroErr: Label 'Quantity must be less than 0 on %1 No. %2 to reverse the entry. ', Comment = '%1 = Table Caption , %2 = Entry No.';
        MissingReleasedProductionErr: Label 'Production Order %1 is already Finished, you cannot reverse this entry.', Comment = '%1 = Production Order No.';

    procedure ReverseProdItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Processed: Boolean;
    begin
        if not CanPostReversal() then
            Error('');

        ItemLedgerEntry.SetBaseLoadFields();
        if ItemLedgerEntry.FindSet() then
            repeat
                ProcessItemLedgEntry(ItemLedgerEntry);
                Processed := true;
            until ItemLedgerEntry.Next() = 0;

        if Processed then
            Message(PostedSuccessfullyMsg);
    end;

    procedure ReverseCapacityLedgerEntry(var CapacityLedgEntry: Record "Capacity Ledger Entry")
    var
        Processed: Boolean;
    begin
        if not CanPostReversal() then
            Error('');

        CapacityLedgEntry.SetBaseLoadFields();
        if CapacityLedgEntry.FindSet() then
            repeat
                ReverseOutputCapacityLedgerEntry(CapacityLedgEntry);
                Processed := true;
            until CapacityLedgEntry.Next() = 0;

        if Processed then
            Message(PostedSuccessfullyMsg);
    end;

    local procedure ProcessItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        SourceCodeSetup.Get();

        case ItemLedgerEntry."Entry Type" of
            Enum::"Item Ledger Entry Type"::Output:
                ReverseOutputItemLedgerEntry(ItemLedgerEntry);
            Enum::"Item Ledger Entry Type"::Consumption:
                ReverseConsumptionItemLedgerEntry(ItemLedgerEntry);
            else
                Error(CannotHandleEntryTypeErr, ItemLedgerEntry."Entry Type");
        end;
    end;

    local procedure ReverseOutputItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ProductionOrder.SetLoadFields(Status, "No.");
        if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
            Error(MissingReleasedProductionErr, ItemLedgerEntry."Order No.");

        ValidateProdOrder(ItemLedgerEntry);

        ItemJnlLine.Init();
        ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
        ItemJnlLine.Validate("Posting Date", ItemLedgerEntry."Posting Date");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ItemLedgerEntry."Order No.");
        ItemJnlLine.Validate("Order Line No.", ItemLedgerEntry."Order Line No.");
        ItemJnlLine.Validate("Item No.", ItemLedgerEntry."Item No.");
        ItemJnlLine.Validate("Variant Code", ItemLedgerEntry."Variant Code");
        ItemJnlLine.Validate("Document No.", ItemLedgerEntry."Document No.");
        ItemJnlLine.Validate(Description, ItemLedgerEntry.Description);
        ItemJnlLine.Validate("Location Code", ItemLedgerEntry."Location Code");
        ItemJnlLine.Validate("Unit of Measure Code", ItemLedgerEntry."Unit of Measure Code");
        ItemJnlLine."Dimension Set ID" := ItemLedgerEntry."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        ItemJnlLine.Validate("Operation No.", GetLastOperationNo(ItemLedgerEntry));

        ItemJnlLine.Validate("Output Quantity", -Abs(ItemLedgerEntry.Quantity));
        if ItemLedgerEntry.TrackingExists() then
            CreateOutputReservationEntry(ItemJnlLine, ItemLedgerEntry)
        else
            ItemJnlLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure ReverseOutputCapacityLedgerEntry(CapacityLedgEntry: Record "Capacity Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        if CapacityLedgEntry."Order Type" <> CapacityLedgEntry."Order Type"::Production then
            exit;

        ValidateProdOrder(CapacityLedgEntry);

        ItemJnlLine.Init();
        ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
        ItemJnlLine.Validate("Posting Date", CapacityLedgEntry."Posting Date");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", CapacityLedgEntry."Order No.");
        ItemJnlLine.Validate("Order Line No.", CapacityLedgEntry."Order Line No.");
        ItemJnlLine.Validate("Routing No.", CapacityLedgEntry."Routing No.");
        ItemJnlLine.Validate("Routing Reference No.", CapacityLedgEntry."Routing Reference No.");
        ItemJnlLine.Validate("Item No.", CapacityLedgEntry."Item No.");
        ItemJnlLine.Validate("Variant Code", CapacityLedgEntry."Variant Code");
        ItemJnlLine.Validate("Document No.", CapacityLedgEntry."Document No.");
        ItemJnlLine.Validate(Description, CapacityLedgEntry.Description);
        ItemJnlLine.Validate("Operation No.", CapacityLedgEntry."Operation No.");
        ItemJnlLine.Validate(Type, CapacityLedgEntry.Type);
        ItemJnlLine.Validate("No.", CapacityLedgEntry."No.");
        ItemJnlLine.Validate("Unit of Measure Code", CapacityLedgEntry."Unit of Measure Code");
        ItemJnlLine."Dimension Set ID" := CapacityLedgEntry."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := CapacityLedgEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := CapacityLedgEntry."Global Dimension 2 Code";

        ItemJnlLine.Validate("Setup Time", -Abs(CapacityLedgEntry."Setup Time"));
        ItemJnlLine.Validate("Run Time", -Abs(CapacityLedgEntry."Run Time"));
        ItemJnlLine.Validate(Quantity, -Abs(CapacityLedgEntry.Quantity));
        ItemJnlLine.Validate("Scrap Code", CapacityLedgEntry."Scrap Code");
        ItemJnlLine.Validate("Scrap Quantity", -Abs(CapacityLedgEntry."Scrap Quantity"));

        if IsLastOperation(CapacityLedgEntry) then
            ItemJnlLine.Validate("Applies-to Entry", GetRelatedItemLedgEntryNo(CapacityLedgEntry));

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure IsLastOperation(CapacityLedgerEntry: Record "Capacity Ledger Entry"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderLine.Get(ProdOrderLine.Status::Released, CapacityLedgerEntry."Order No.", CapacityLedgerEntry."Order Line No.");

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange(Type, CapacityLedgerEntry.Type);
        ProdOrderRoutingLine.SetRange("Operation No.", CapacityLedgerEntry."Operation No.");
        ProdOrderRoutingLine.SetFilter("Next Operation No.", '%1', '');
        exit(not ProdOrderRoutingLine.IsEmpty());
    end;

    local procedure GetRelatedItemLedgEntryNo(CapacityLedgerEntry: Record "Capacity Ledger Entry"): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetLoadFields("Item Ledger Entry No.");
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapacityLedgerEntry."Entry No.");
        if ValueEntry.FindFirst() then
            exit(ValueEntry."Item Ledger Entry No.");
    end;

    local procedure GetLastOperationNo(ItemLedgEntry: Record "Item Ledger Entry"): Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemLedgEntry."Order No.", ItemLedgEntry."Order Line No.");

        ProdOrderRoutingLine.SetLoadFields("Operation No.");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetFilter("Next Operation No.", '%1', '');
        if ProdOrderRoutingLine.FindFirst() then
            exit(ProdOrderRoutingLine."Operation No.");
    end;

    local procedure ReverseConsumptionItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ProductionOrder.SetLoadFields(Status, "No.");
        if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
            Error(MissingReleasedProductionErr, ItemLedgerEntry."Order No.");

        ValidateProdOrder(ItemLedgerEntry);

        ItemJnlLine.Init();
        ItemJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
        ItemJnlLine.Validate("Posting Date", ItemLedgerEntry."Posting Date");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ItemLedgerEntry."Order No.");
        ItemJnlLine.Validate("Order Line No.", ItemLedgerEntry."Order Line No.");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ItemLedgerEntry."Prod. Order Comp. Line No.");
        ItemJnlLine.Validate("Item No.", ItemLedgerEntry."Item No.");
        ItemJnlLine.Validate("Variant Code", ItemLedgerEntry."Variant Code");
        ItemJnlLine.Validate("Document No.", ItemLedgerEntry."Document No.");
        ItemJnlLine.Validate(Description, ItemLedgerEntry.Description);
        ItemJnlLine.Validate("Location Code", ItemLedgerEntry."Location Code");
        ItemJnlLine.Validate("Unit of Measure Code", ItemLedgerEntry."Unit of Measure Code");
        ItemJnlLine."Dimension Set ID" := ItemLedgerEntry."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        ItemJnlLine.Validate(Quantity, -Abs(ItemLedgerEntry.Quantity));

        if ItemLedgerEntry.TrackingExists() then
            CreateConsumptionReservationEntry(ItemJnlLine, ItemLedgerEntry)
        else
            ItemJnlLine.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure CanPostReversal(): Boolean
    var
        QuestionTxt: Text;
    begin
        if not GuiAllowed() then
            exit(true);

        QuestionTxt := ReverseEntriesMsg + '\' + ReverseEntriesQst;
        exit(Confirm(QuestionTxt));
    end;

    local procedure ValidateProdOrder(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not (ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Output, ItemLedgEntry."Entry Type"::Consumption]) then
            Error(InvalidEntryTypeErr);

        ProdOrderLine.SetBaseLoadFields();
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemLedgEntry."Order No.", ItemLedgEntry."Order Line No.");

        if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Output then
            ItemLedgEntry.TestField("Remaining Quantity", ItemLedgEntry.Quantity);

        ItemLedgEntry.CalcFields("Reserved Quantity");
        ItemLedgEntry.TestField("Reserved Quantity", 0);
        ItemLedgEntry.TestField(Correction, false);

        case ItemLedgEntry."Entry Type" of
            Enum::"Item Ledger Entry Type"::Consumption:
                if ItemLedgEntry.Quantity > 0 then
                    Error(QuantityMustBeLessThanZeroErr, ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.");
            Enum::"Item Ledger Entry Type"::Output:
                if ItemLedgEntry.Quantity < 0 then
                    Error(QuantityMustBeGreaterThanZeroErr, ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.");
        end;

        ValidateSubcontracting(ProdOrderLine);
    end;

    local procedure ValidateSubcontracting(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetLoadFields(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", Type, "No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.SetFilter("No.", '<>%1', '');
        if ProdOrderRoutingLine.FindSet() then
            repeat
                ValidateSubcontractingLink(ProdOrderRoutingLine);
            until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure ValidateSubcontractingLink(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("No.", "Subcontractor No.");
        WorkCenter.Get(ProdOrderRoutingLine."No.");
        if WorkCenter."Subcontractor No." <> '' then
            Error(SubContractingErr);
    end;

    local procedure ValidateProdOrder(CapacityLedgerEntry: Record "Capacity Ledger Entry")
    var
        ProductionOrder: Record "Production Order";
    begin
        CapacityLedgerEntry.TestField("Order Type", CapacityLedgerEntry."Order Type"::Production);
        if CapacityLedgerEntry.Quantity < 0 then
            Error(QuantityMustBeGreaterThanZeroErr, CapacityLedgerEntry.TableCaption, CapacityLedgerEntry."Entry No.");

        ProductionOrder.SetLoadFields(Status, "No.");
        ProductionOrder.Get(ProductionOrder.Status::Released, CapacityLedgerEntry."Order No.");

        if CapacityLedgerEntry.Subcontracting then
            Error(SubContractingErr);
    end;

    local procedure CreateOutputReservationEntry(ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Item No." := ItemLedgerEntry."Item No.";
        ReservationEntry."Variant Code" := ItemLedgerEntry."Variant Code";
        ReservationEntry."Location Code" := ItemLedgerEntry."Location Code";
        ReservationEntry.Quantity := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Quantity (Base)" := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry."Creation Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Source Type" := Database::"Item Journal Line";
        ReservationEntry."Source Subtype" := ItemJnlLine."Entry Type".AsInteger();
        ReservationEntry."Source ID" := ItemJnlLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJnlLine."Journal Batch Name";
        ReservationEntry."Expected Receipt Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Created By" := UserId();
        ReservationEntry."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
        ReservationEntry."Qty. to Handle (Base)" := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Qty. to Invoice (Base)" := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Lot No." := ItemLedgerEntry."Lot No.";
        ReservationEntry."Serial No." := ItemLedgerEntry."Serial No.";
        ReservationEntry."Item Tracking" := ItemLedgerEntry."Item Tracking";
        ReservationEntry."Expiration Date" := ItemLedgerEntry."Expiration Date";
        ReservationEntry."Package No." := ItemLedgerEntry."Package No.";
        ReservationEntry.Insert();
    end;

    local procedure CreateConsumptionReservationEntry(ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Item No." := ItemLedgerEntry."Item No.";
        ReservationEntry."Variant Code" := ItemLedgerEntry."Variant Code";
        ReservationEntry."Location Code" := ItemLedgerEntry."Location Code";
        ReservationEntry.Quantity := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Quantity (Base)" := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry."Creation Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Source Type" := Database::"Item Journal Line";
        ReservationEntry."Source Subtype" := ItemJnlLine."Entry Type".AsInteger();
        ReservationEntry."Source ID" := ItemJnlLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJnlLine."Journal Batch Name";
        ReservationEntry."Shipment Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Created By" := UserId();
        ReservationEntry."Qty. per Unit of Measure" := Abs(ItemLedgerEntry."Qty. per Unit of Measure");
        ReservationEntry."Qty. to Handle (Base)" := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Qty. to Invoice (Base)" := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Lot No." := ItemLedgerEntry."Lot No.";
        ReservationEntry."Serial No." := ItemLedgerEntry."Serial No.";
        ReservationEntry."Item Tracking" := ItemLedgerEntry."Item Tracking";
        ReservationEntry."Expiration Date" := ItemLedgerEntry."Expiration Date";
        ReservationEntry."Package No." := ItemLedgerEntry."Package No.";
        ReservationEntry.Insert();
    end;
}