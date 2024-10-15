namespace Microsoft.Service.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.TimeSheet;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using System.Utilities;

codeunit 5818 "Undo Service Shipment Line"
{
    Permissions = TableData "Item Application Entry" = rmd,
                  TableData "Service Line" = rimd,
                  TableData "Service Ledger Entry" = ri,
                  TableData "Warranty Ledger Entry" = rim,
                  TableData "Service Shipment Line" = rimd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Service Shipment Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        ConfMessage: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Rec.Find('-') then
            exit;

        ConfMessage := Text000;

        if CheckComponentsAdjusted(Rec) then
            ConfMessage :=
              StrSubstNo(Text004, Rec.FieldCaption("Service Item No."), Format(Rec."Service Item No.")) +
              Text000;

        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(ConfMessage, true) then
                exit;

        Rec.LockTable();
        ServShptLine.Copy(Rec);
        Code();
        Rec := ServShptLine;
    end;

    var
        ServShptLine: Record "Service Shipment Line";
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Text000: Label 'Do you want to undo the selected shipment line(s)?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
        NextLineNo: Integer;
        HideDialog: Boolean;
        Text004: Label 'The component list for %1 %2 was changed. You may need to adjust the list manually.\';
        Text005: Label 'Some shipment lines may have unused service items. Do you want to delete them?';
        AlreadyReversedErr: Label 'This service shipment has already been reversed.';

    local procedure CheckComponentsAdjusted(var ServiceShptLine: Record "Service Shipment Line"): Boolean
    var
        LocalServShptLine: Record "Service Shipment Line";
    begin
        LocalServShptLine.Copy(ServiceShptLine);
        with LocalServShptLine do begin
            SetFilter("Spare Part Action", '%1|%2',
              "Spare Part Action"::"Component Replaced", "Spare Part Action"::"Component Installed");
            SetFilter("Service Item No.", '<>%1', '');
            OnCheckComponentsAdjustedOnAfterLocalServShptLineSetFilters(LocalServShptLine);
            exit(not IsEmpty);
        end;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        ServiceLine: Record "Service Line";
        ServItem: Record "Service Item";
        ServLedgEntriesPost: Codeunit "ServLedgEntries-Post";
        ConfirmManagement: Codeunit "Confirm Management";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        ServLedgEntryNo: Integer;
        WarrantyLedgEntryNo: Integer;
        DeleteServItems: Boolean;
        PostedWhseShptLineFound: Boolean;
    begin
        with ServShptLine do begin
            Clear(ItemJnlPostLine);
            SetRange(Correction, false);
            FindFirst();
            repeat
                if not HideDialog then
                    Window.Open(Text003);
                CheckServShptLine(ServShptLine);
            until Next() = 0;

            ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.");
            ServItem.SetRange("Sales/Serv. Shpt. Document No.", "Document No.");
            ServItem.SetRange("Sales/Serv. Shpt. Line No.", "Line No.");
            ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Service);

            if ServItem.FindFirst() then
                if not HideDialog then
                    DeleteServItems := ConfirmManagement.GetResponseOrDefault(Text005, true)
                else
                    DeleteServItems := true;

            ServLedgEntriesPost.InitServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);
            Find('-');
            repeat
                TempGlobalItemLedgEntry.Reset();
                if not TempGlobalItemLedgEntry.IsEmpty() then
                    TempGlobalItemLedgEntry.DeleteAll();
                TempGlobalItemEntryRelation.Reset();
                if not TempGlobalItemEntryRelation.IsEmpty() then
                    TempGlobalItemEntryRelation.DeleteAll();

                if not HideDialog then
                    Window.Open(Text001);

                PostedWhseShptLineFound :=
                    WhseUndoQty.FindPostedWhseShptLine(
                        PostedWhseShptLine, DATABASE::"Service Shipment Line", "Document No.",
                        DATABASE::"Service Line", ServiceLine."Document Type"::Order.AsInteger(), "Order No.", "Order Line No.");

                if Type = Type::Item then
                    ItemShptEntryNo := PostItemJnlLine(ServShptLine)
                else
                    ItemShptEntryNo := GetCorrectionLineNo(ServShptLine);

                if Type = Type::Resource then
                    PostResJnlLine(ServShptLine);

                InsertNewShipmentLine(ServShptLine, ItemShptEntryNo);
                OnAfterInsertNewShipmentLine(ServShptLine, PostedWhseShptLine, PostedWhseShptLineFound);

                if PostedWhseShptLineFound then
                    WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

                ServLedgEntriesPost.ReverseServLedgEntry(ServShptLine);
                if Type in [Type::Item, Type::Resource] then
                    ServLedgEntriesPost.ReverseWarrantyEntry(ServShptLine);

                UpdateOrderLine(ServShptLine);
                if PostedWhseShptLineFound then
                    WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

                if DeleteServItems then
                    DeleteServShptLineServItems(ServShptLine);

                "Quantity Invoiced" := Quantity;
                "Qty. Invoiced (Base)" := "Quantity (Base)";
                "Qty. Shipped Not Invoiced" := 0;
                "Qty. Shipped Not Invd. (Base)" := 0;
                Correction := true;
                OnCodeOnBeforeServShptLineModify(ServShptLine, TempWhseJnlLine);
                Modify();
                OnCodeOnAfterServShptLineModify(ServShptLine, TempWhseJnlLine);
            until Next() = 0;
            ServLedgEntriesPost.FinishServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);

            MakeInventoryAdjustment();

            WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);
        end;

        OnAfterCode(ServShptLine);
    end;

    local procedure GetCorrectiveShptLineNoStep(DocumentNo: Code[20]; LineNo: Integer) LineSpacing: Integer
    var
        TestServShptLine: Record "Service Shipment Line";
    begin
        TestServShptLine.SetRange("Document No.", DocumentNo);
        TestServShptLine."Document No." := DocumentNo;
        TestServShptLine."Line No." := LineNo;
        TestServShptLine.Find('=');

        if TestServShptLine.Find('>') then begin
            LineSpacing := (TestServShptLine."Line No." - LineNo) div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;
    end;

    local procedure CheckServShptLine(var ServShptLine: Record "Service Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServShptLine(ServShptLine, IsHandled);
        if IsHandled then
            exit;

        with ServShptLine do begin
            TestField(Quantity);
            TestField("Qty. Shipped Not Invoiced", Quantity);
            if Correction then
                Error(AlreadyReversedErr);
            UndoPostingMgt.TestServShptLine(ServShptLine);
            if Type = Type::Item then begin
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Service Shipment Line",
                  "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, "Line No.");
            end;
        end;
    end;

    procedure GetCorrectionLineNo(ServiceShipmentLine2: Record "Service Shipment Line") Result: Integer;
    var
        ServiceShipmentLine3: Record "Service Shipment Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(ServiceShipmentLine2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with ServiceShipmentLine2 do begin
            ServiceShipmentLine3.SetRange("Document No.", "Document No.");
            ServiceShipmentLine3."Document No." := "Document No.";
            ServiceShipmentLine3."Line No." := "Line No.";
            ServiceShipmentLine3.Find('=');
            if ServiceShipmentLine3.Next() <> 0 then begin
                LineSpacing := (ServiceShipmentLine3."Line No." - "Line No.") div 2;
                if LineSpacing = 0 then
                    Error(Text002);
            end else
                LineSpacing := 10000;

            Result := "Line No." + LineSpacing;
        end;
        OnAfterGetCorrectionLineNo(ServiceShipmentLine2, Result);
    end;

    local procedure PostItemJnlLine(ServShptLine: Record "Service Shipment Line"): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        ServLine: Record "Service Line";
        ServShptHeader: Record "Service Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
    begin
        with ServShptLine do begin
            SourceCodeSetup.Get();
            ServShptHeader.Get("Document No.");
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Shipment";
            ItemJnlLine."Document No." := ServShptHeader."No.";
            ItemJnlLine."Document Line No." := "Line No." + GetCorrectiveShptLineNoStep("Document No.", "Line No.");
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Posting Date" := "Posting Date";
            ItemJnlLine."Document No." := "Document No.";
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Source Posting Group" := ServShptHeader."Customer Posting Group";
            ItemJnlLine."Salespers./Purch. Code" := ServShptHeader."Salesperson Code";
            ItemJnlLine."Country/Region Code" := ServShptHeader."Country/Region Code";
            ItemJnlLine."Posting No. Series" := ServShptHeader."No. Series";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Source Code" := SourceCodeSetup.Sales;
            ItemJnlLine."Applies-to Entry" := "Item Shpt. Entry No.";
            ItemJnlLine.Correction := true;
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine.Quantity := -"Quantity (Base)";
            ItemJnlLine."Quantity (Base)" := -"Quantity (Base)";
            ItemJnlLine."Document Date" := ServShptHeader."Document Date";

            OnAfterCopyItemJnlLineFromServShpt(ItemJnlLine, ServShptHeader, ServShptLine);

            WhseUndoQty.InsertTempWhseJnlLine(
                ItemJnlLine,
                DATABASE::"Service Line", ServLine."Document Type"::Order.AsInteger(), "Order No.", "Order Line No.",
                TempWhseJnlLine."Reference Document"::"Posted Shipment".AsInteger(), TempWhseJnlLine, NextLineNo);

            if "Item Shpt. Entry No." <> 0 then begin
                ItemJnlPostLine.Run(ItemJnlLine);
                OnItemJnlPostLineOnAfterItemShptEntryNoOnBeforeExit(ItemJnlLine, ServShptLine);
                exit(ItemJnlLine."Item Shpt. Entry No.");
            end;
            UndoPostingMgt.CollectItemLedgEntries(TempApplyToEntryList, DATABASE::"Service Shipment Line",
              "Document No.", "Line No.", "Quantity (Base)", "Item Shpt. Entry No.");

            UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToEntryList,
              Quantity, "Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

            OnAfterPostItemJnlLine(ItemJnlLine, ServShptLine);
            exit(0); // "Item Shpt. Entry No."
        end;
    end;

    local procedure InsertNewShipmentLine(OldServShptLine: Record "Service Shipment Line"; ItemShptEntryNo: Integer)
    var
        NewServShptLine: Record "Service Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewShipmentLine(OldServShptLine, ItemShptEntryNo, TempGlobalItemEntryRelation, IsHandled);
        if IsHandled then
            exit;

        with OldServShptLine do begin
            NewServShptLine.Reset();
            NewServShptLine.Init();
            NewServShptLine.Copy(OldServShptLine);
            NewServShptLine."Line No." := "Line No." + GetCorrectiveShptLineNoStep("Document No.", "Line No.");
            NewServShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
            NewServShptLine."Appl.-to Service Entry" := "Appl.-to Service Entry";
            NewServShptLine.Quantity := -Quantity;
            NewServShptLine."Qty. Shipped Not Invoiced" := 0;
            NewServShptLine."Qty. Shipped Not Invd. (Base)" := 0;
            NewServShptLine."Quantity (Base)" := -"Quantity (Base)";
            NewServShptLine."Quantity Invoiced" := NewServShptLine.Quantity;
            NewServShptLine."Qty. Invoiced (Base)" := NewServShptLine."Quantity (Base)";
            NewServShptLine.Correction := true;
            NewServShptLine."Dimension Set ID" := "Dimension Set ID";
            OnBeforeNewServiceShptLineInsert(NewServShptLine, OldServShptLine);
            NewServShptLine.Insert();

            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewServShptLine);
        end;
    end;

    local procedure UpdateOrderLine(ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
    begin
        with ServShptLine do begin
            ServLine.Get(ServLine."Document Type"::Order, "Order No.", "Order Line No.");
            UndoPostingMgt.UpdateServLine(ServLine, Quantity, "Quantity (Base)", TempGlobalItemLedgEntry);
            OnAfterUpdateOrderLine(ServLine, ServShptLine);
        end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewServShptLine: Record "Service Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsServShptLine(NewServShptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure PostResJnlLine(var ServiceShptLine: Record "Service Shipment Line")
    var
        ResJnlLine: Record "Res. Journal Line";
        SrcCodeSetup: Record "Source Code Setup";
        ServiceShptHeader: Record "Service Shipment Header";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        IsHandled: Boolean;
    begin
        ResJnlLine.Init();
        SrcCodeSetup.Get();
        with ResJnlLine do begin
            ServiceShptHeader.Get(ServiceShptLine."Document No.");
            "Entry Type" := "Entry Type"::Usage;
            "Document No." := ServiceShptLine."Document No.";
            "Posting Date" := ServiceShptLine."Posting Date";
            "Document Date" := ServiceShptHeader."Document Date";
            "Resource No." := ServiceShptLine."No.";
            Description := ServiceShptLine.Description;
            "Work Type Code" := ServiceShptLine."Work Type Code";
            Quantity := -ServiceShptLine."Qty. Shipped Not Invoiced";
            "Unit Cost" := ServiceShptLine."Unit Cost (LCY)";
            "Total Cost" := ServiceShptLine."Unit Cost (LCY)" * Quantity;
            "Unit Price" := ServiceShptLine."Unit Price";
            "Total Price" := "Unit Price" * Quantity;
            "Shortcut Dimension 1 Code" := ServiceShptHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServiceShptHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := ServiceShptLine."Dimension Set ID";
            "Unit of Measure Code" := ServiceShptLine."Unit of Measure Code";
            "Qty. per Unit of Measure" := ServiceShptLine."Qty. per Unit of Measure";
            "Source Code" := SrcCodeSetup."Service Management";
            "Gen. Bus. Posting Group" := ServiceShptLine."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := ServiceShptLine."Gen. Prod. Posting Group";
            "Posting No. Series" := ServiceShptHeader."No. Series";
            "Reason Code" := ServiceShptHeader."Reason Code";
            "Source Type" := "Source Type"::Customer;
            "Source No." := ServiceShptLine."Bill-to Customer No.";
            "Qty. per Unit of Measure" := ServiceShptLine."Qty. per Unit of Measure";
            IsHandled := false;
            OnBeforePostResJnlLine(ResJnlLine, ServiceShptLine, IsHandled);
            if not IsHandled then
                ResJnlPostLine.RunWithCheck(ResJnlLine);
            OnPostResJnlLineOnAfterRunWithCheck(ResJnlLine, ServiceShptLine);
        end;

        TimeSheetMgt.CreateTSLineFromServiceShptLine(ServiceShptLine);
    end;

    local procedure DeleteServShptLineServItems(ServShptLine: Record "Service Shipment Line")
    var
        ServItem: Record "Service Item";
    begin
        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", ServShptLine."Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Line No.", ServShptLine."Line No.");
        ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Service);
        if ServItem.Find('-') then
            repeat
                if ServItem.CheckIfCanBeDeleted() = '' then
                    if ServItem.Delete(true) then;
            until ServItem.Next() = 0;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then begin
            InvtAdjmtHandler.SetJobUpdateProperties(true);
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShpt(var ItemJournalLine: Record "Item Journal Line"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line"; PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCorrectionLineNo(ServiceShipmentLine: Record "Service Shipment Line"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderLine(var ServiceLine: Record "Service Line"; var ServiceShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServShptLine(var ServiceShptLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(ServiceShipmentLine: Record "Service Shipment Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewShipmentLine(var ServiceShptLine: Record "Service Shipment Line"; ItemShptEntryNo: Integer; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewServiceShptLineInsert(var NewServiceShipmentLine: Record "Service Shipment Line"; OldServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLine(var ResJournalLine: Record "Res. Journal Line"; var ServiceShptLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterServShptLineModify(var ServShptLine: Record "Service Shipment Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeServShptLineModify(var ServShptLine: Record "Service Shipment Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckComponentsAdjustedOnAfterLocalServShptLineSetFilters(var ServiceShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostLineOnAfterItemShptEntryNoOnBeforeExit(var ItemJournalLine: Record "Item Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostResJnlLineOnAfterRunWithCheck(var ResJournalLine: Record "Res. Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;
}

