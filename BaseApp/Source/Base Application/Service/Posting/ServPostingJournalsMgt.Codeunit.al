﻿namespace Microsoft.Service.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Customer;
#if not CLEAN23
using Microsoft.Sales.Receivables;
#endif
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Pricing;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;

codeunit 5987 "Serv-Posting Journals Mgt."
{
#if not CLEAN23
    Permissions = TableData "Invoice Post. Buffer" = rimd;
#endif

    trigger OnRun()
    begin
    end;

    var
        ServiceHeader: Record "Service Header";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesSetup: Record "Sales & Receivables Setup";
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        ServITRMgt: Codeunit "Serv-Item Tracking Rsrv. Mgt.";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        ServLedgEntryPostSale: Codeunit "ServLedgEntries-Post";
        ServTimeSheetMgt: Codeunit "Serv. Time Sheet Mgt.";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        Consume: Boolean;
        Invoice: Boolean;
        ItemJnlRollRndg: Boolean;
        ServiceLinePostingDate: Date;

    procedure Initialize(var TempServHeader: Record "Service Header"; TmpConsume: Boolean; TmpInvoice: Boolean)
    var
        SrcCodeSetup: Record "Source Code Setup";
    begin
        ServiceHeader := TempServHeader;
        SetPostingOptions(TmpConsume, TmpInvoice);
        SrcCodeSetup.Get();
        SalesSetup.Get();
        SrcCode := SrcCodeSetup."Service Management";
        Currency.Initialize(ServiceHeader."Currency Code");
        ItemJnlRollRndg := false;
        GenJnlLineDocNo := '';
        GenJnlLineExtDocNo := '';
    end;

    procedure Finalize()
    begin
        Clear(GenJnlPostLine);
        Clear(ResJnlPostLine);
        Clear(ItemJnlPostLine);
        Clear(ServLedgEntryPostSale);
    end;

    procedure SetPostingOptions(PassedConsume: Boolean; PassedInvoice: Boolean)
    begin
        Consume := PassedConsume;
        Invoice := PassedInvoice;
    end;

    procedure SetItemJnlRollRndg(PassedItemJnlRollRndg: Boolean)
    begin
        ItemJnlRollRndg := PassedItemJnlRollRndg;
    end;

    procedure SetGenJnlLineDocNos(DocNo: Code[20]; ExtDocNo: Code[35])
    begin
        GenJnlLineDocNo := DocNo;
        GenJnlLineExtDocNo := ExtDocNo;
    end;

    local procedure IsWarehouseShipment(ServiceLine: Record "Service Line"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", 1);
        WarehouseShipmentLine.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseShipmentLine.SetRange("Source Line No.", ServiceLine."Line No.");
        exit(not WarehouseShipmentLine.IsEmpty());
    end;

    local procedure GetLocation(LocationCode: Code[10]; var Location: Record Location)
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure PostItemJnlLine(var ServiceLine: Record "Service Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal; QtyToBeConsumed: Decimal; QtyToBeConsumedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecificationInv: Record "Tracking Specification"; var TempHandlingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var ServShptHeader: Record "Service Shipment Header"; ServShptLineDocNo: Code[20]): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        RemAmt: Decimal;
        RemDiscAmt: Decimal;
        WhsePosting: Boolean;
        CheckApplFromItemEntry: Boolean;
        ShouldCreateWhseJnlLine: Boolean;
    begin
        Clear(ItemJnlPostLine);
        if not ItemJnlRollRndg then begin
            RemAmt := 0;
            RemDiscAmt := 0;
        end;

        ItemJnlLine.Init();
        ServiceHeader.CopyToItemJnlLine(ItemJnlLine);
        ServiceLine.CopyToItemJnlLine(ItemJnlLine);
        ItemJnlLine.CopyTrackingFromSpec(TrackingSpecification);

        if GenJnlLineExtDocNo = '' then
            GenJnlLineExtDocNo := ServiceHeader."External Document No.";

        if QtyToBeShipped = 0 then begin
            if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Credit Memo"
            else
                ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Invoice";
            if QtyToBeConsumed <> 0 then begin
                ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
                ItemJnlLine."Document No." := ServShptLineDocNo;
                ItemJnlLine."External Document No." := '';
                ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Shipment";
            end else begin
                ItemJnlLine."Document No." := GenJnlLineDocNo;
                ItemJnlLine."External Document No." := GenJnlLineExtDocNo;
            end;
            ItemJnlLine."Posting No. Series" := ServiceHeader."Posting No. Series";
        end else begin
            if ServiceLine."Document Type" <> ServiceLine."Document Type"::"Credit Memo" then begin
                CheckItemBlocked(ItemJnlLine);
                ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Shipment";
                ItemJnlLine."Document No." := ServShptHeader."No.";
                ItemJnlLine."Posting No. Series" := ServShptHeader."No. Series";
            end;
            if (QtyToBeInvoiced <> 0) or (QtyToBeConsumed <> 0) then begin
                if QtyToBeConsumed <> 0 then
                    ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
                ItemJnlLine."Invoice No." := GenJnlLineDocNo;
                ItemJnlLine."External Document No." := GenJnlLineExtDocNo;
                if ItemJnlLine."Document No." = '' then begin
                    if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Credit Memo"
                    else
                        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Invoice";
                    ItemJnlLine."Document No." := GenJnlLineDocNo;
                end;
                ItemJnlLine."Posting No. Series" := ServiceHeader."Posting No. Series";
            end;
            if (QtyToBeConsumed <> 0) and (ItemJnlLine."Document No." = '') then
                ItemJnlLine."Document No." := ServShptLineDocNo;
        end;

        ItemJnlLine."Document Line No." := ServiceLine."Line No.";
        ItemJnlLine.Quantity := -QtyToBeShipped;
        ItemJnlLine."Quantity (Base)" := -QtyToBeShippedBase;
        if QtyToBeInvoiced <> 0 then begin
            ItemJnlLine."Invoiced Quantity" := -QtyToBeInvoiced;
            ItemJnlLine."Invoiced Qty. (Base)" := -QtyToBeInvoicedBase;
        end else
            if QtyToBeConsumed <> 0 then begin
                ItemJnlLine."Invoiced Quantity" := -QtyToBeConsumed;
                ItemJnlLine."Invoiced Qty. (Base)" := -QtyToBeConsumedBase;
            end;
        ItemJnlLine."Unit Cost" := ServiceLine."Unit Cost (LCY)";
        ItemJnlLine."Source Currency Code" := ServiceHeader."Currency Code";
        ItemJnlLine."Unit Cost (ACY)" := ServiceLine."Unit Cost";
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";
        ItemJnlLine."Applies-from Entry" := ServiceLine."Appl.-from Item Entry";

        if Invoice and (QtyToBeInvoiced <> 0) then begin
            ItemJnlLine.Amount := -(ServiceLine.Amount * (QtyToBeInvoiced / ServiceLine."Qty. to Invoice") - RemAmt);
            if ServiceHeader."Prices Including VAT" then
                ItemJnlLine."Discount Amount" :=
                  -((ServiceLine."Line Discount Amount" + ServiceLine."Inv. Discount Amount") / (1 + ServiceLine."VAT %" / 100) *
                    (QtyToBeInvoiced / ServiceLine."Qty. to Invoice") - RemDiscAmt)
            else
                ItemJnlLine."Discount Amount" :=
                  -((ServiceLine."Line Discount Amount" + ServiceLine."Inv. Discount Amount") *
                    (QtyToBeInvoiced / ServiceLine."Qty. to Invoice") - RemDiscAmt);
        end else
            if Consume and (QtyToBeConsumed <> 0) then begin
                ItemJnlLine.Amount := -(ServiceLine.Amount * QtyToBeConsumed - RemAmt);
                ItemJnlLine."Discount Amount" :=
                  -(ServiceLine."Line Discount Amount" * QtyToBeConsumed - RemDiscAmt);
            end;

        if (QtyToBeInvoiced <> 0) or (QtyToBeConsumed <> 0) then begin
            RemAmt := ItemJnlLine.Amount - Round(ItemJnlLine.Amount);
            RemDiscAmt := ItemJnlLine."Discount Amount" - Round(ItemJnlLine."Discount Amount");
            ItemJnlLine.Amount := Round(ItemJnlLine.Amount);
            ItemJnlLine."Discount Amount" := Round(ItemJnlLine."Discount Amount");
        end else begin
            if ServiceHeader."Prices Including VAT" then
                ItemJnlLine.Amount :=
                  -((QtyToBeShipped *
                     ServiceLine."Unit Price" * (1 - ServiceLine."Line Discount %" / 100) / (1 + ServiceLine."VAT %" / 100)) - RemAmt)
            else
                ItemJnlLine.Amount :=
                  -((QtyToBeShipped * ServiceLine."Unit Price" * (1 - ServiceLine."Line Discount %" / 100)) - RemAmt);
            RemAmt := ItemJnlLine.Amount - Round(ItemJnlLine.Amount);
            if ServiceHeader."Currency Code" <> '' then
                ItemJnlLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      ServiceLine."Posting Date", ServiceHeader."Currency Code",
                      ItemJnlLine.Amount, ServiceHeader."Currency Factor"))
            else
                ItemJnlLine.Amount := Round(ItemJnlLine.Amount);
        end;

        ItemJnlLine."Source Code" := SrcCode;
        ItemJnlLine."Item Shpt. Entry No." := ItemLedgShptEntryNo;
        ItemJnlLine."Invoice-to Source No." := ServiceLine."Bill-to Customer No.";

        if SalesSetup."Exact Cost Reversing Mandatory" and (ServiceLine.Type = ServiceLine.Type::Item) then
            if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                CheckApplFromItemEntry := ServiceLine.Quantity > 0
            else
                CheckApplFromItemEntry := ServiceLine.Quantity < 0;

        ShouldCreateWhseJnlLine := true;
        OnPostItemJnlLineOnBeforeCreateWhseJnlLine(ItemJnlLine, ServiceHeader, ShouldCreateWhseJnlLine, ServShptHeader, ServiceLine, TempWhseJnlLine, WhsePosting);

        if ShouldCreateWhseJnlLine and (ServiceLine."Location Code" <> '') and (ServiceLine.Type = ServiceLine.Type::Item) and ServiceLine.IsInventoriableItem() and (ItemJnlLine.Quantity <> 0) then begin
            GetLocation(ServiceLine."Location Code", Location);
            if ((ServiceLine."Document Type" in [ServiceLine."Document Type"::Invoice, ServiceLine."Document Type"::"Credit Memo"]) and
                Location."Directed Put-away and Pick") or
               (Location."Bin Mandatory" and not IsWarehouseShipment(ServiceLine))
            then begin
                CreateWhseJnlLine(ItemJnlLine, ServiceLine, TempWhseJnlLine, Location);
                WhsePosting := true;
            end;
        end;

        if QtyToBeShippedBase <> 0 then
            if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                ServITRMgt.TransServLineToItemJnlLine(ServiceLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
            else
                ServITRMgt.TransferReservToItemJnlLine(
                  ServiceLine, ItemJnlLine, -QtyToBeShippedBase, CheckApplFromItemEntry);

        if CheckApplFromItemEntry then
            ServiceLine.TestField("Appl.-from Item Entry");

        OnBeforePostItemJnlLine(
          ItemJnlLine, ServShptHeader, ServiceLine, GenJnlLineDocNo,
          QtyToBeShipped, QtyToBeShippedBase, QtyToBeInvoiced, QtyToBeInvoicedBase);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, '');

        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then
            ServITRMgt.InsertTempHandlngSpecification(DATABASE::"Service Line",
              ServiceLine, TempHandlingSpecification,
              TempTrackingSpecification, TempTrackingSpecificationInv,
              QtyToBeInvoiced <> 0);

        if WhsePosting then
            PostWhseJnlLines(TempWhseJnlLine, TempTrackingSpecification);

        OnAfterPostItemJnlLine(ServiceHeader, ItemJnlLine, TempHandlingSpecification);

        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure CheckItemBlocked(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if ItemJournalLine."Item No." = '' then
            exit;
        Item.SetLoadFields(Blocked, "Service Blocked");
        Item.Get(ItemJournalLine."Item No.");
        ItemJournalLine.DisplayErrorIfItemIsBlocked(Item);
        if ItemJournalLine."Variant Code" <> '' then begin
            ItemVariant.SetLoadFields(Blocked, "Service Blocked");
            ItemVariant.Get(ItemJournalLine."Item No.", ItemJournalLine."Variant Code");
            ItemJournalLine.DisplayErrorIfItemVariantIsBlocked(ItemVariant);
        end;
    end;

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; ServLine: Record "Service Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; Location: Record Location)
    var
        WMSMgmt: Codeunit "WMS Management";
        WhseMgt: Codeunit "Whse. Management";
    begin
        WMSMgmt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
        WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, false);
        TempWhseJnlLine."Source Type" := DATABASE::"Service Line";
        TempWhseJnlLine."Source Subtype" := ServLine."Document Type".AsInteger();
        TempWhseJnlLine."Source Code" := SrcCode;
        TempWhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
        TempWhseJnlLine."Source No." := ServLine."Document No.";
        TempWhseJnlLine."Source Line No." := ServLine."Line No.";
        case ServLine."Document Type" of
            ServLine."Document Type"::Order:
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted Shipment";
            ServLine."Document Type"::Invoice:
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted S. Inv.";
            ServLine."Document Type"::"Credit Memo":
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted S. Cr. Memo";
        end;
        TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
    end;

    local procedure PostWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
    begin
        ServITRMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
        if TempWhseJnlLine2.Find('-') then
            repeat
                WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next() = 0;
    end;

    procedure PostLines(ServiceHeader: Record "Service Header"; var InvoicePostingInterface: Interface "Invoice Posting"; var Window: Dialog; var TotalAmount: Decimal)
    begin
        InvoicePostingInterface.PostLines(ServiceHeader, GenJnlPostLine, Window, TotalAmount);
    end;

    procedure PostLedgerEntry(ServiceHeader: Record "Service Header"; var InvoicePostingInterface: Interface "Invoice Posting")
    begin
        InvoicePostingInterface.PostLedgerEntry(ServiceHeader, GenJnlPostLine);
    end;

    procedure PostBalancingEntry(ServiceHeader: Record "Service Header"; var InvoicePostingInterface: Interface "Invoice Posting")
    begin
        InvoicePostingInterface.PostBalancingEntry(ServiceHeader, GenJnlPostLine);
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    procedure PostInvoicePostBufferLine(var InvoicePostBuffer: Record "Invoice Post. Buffer"; DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntryNo: Integer;
    begin
        GenJnlLine.InitNewLine(
            ServiceLinePostingDate, ServiceHeader."Document Date", ServiceHeader."VAT Reporting Date", InvoicePostBuffer."Entry Description",
            InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code",
            InvoicePostBuffer."Dimension Set ID", ServiceHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(Enum::"Gen. Journal Document Type".FromInteger(DocType), DocNo, ExtDocNo, SrcCode, '');

        GenJnlLine.CopyFromServiceHeader(ServiceHeader);
        InvoicePostBuffer.CopyToGenJnlLine(GenJnlLine);
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;

        OnBeforePostInvoicePostBuffer(GenJnlLine, InvoicePostBuffer, ServiceHeader, GenJnlPostLine);
        GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostInvoicePostBuffer(GenJnlLine, InvoicePostBuffer, ServiceHeader, GLEntryNo, GenJnlPostLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    procedure PostCustomerEntry(var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
            ServiceLinePostingDate, ServiceHeader."Document Date", ServiceHeader."VAT Reporting Date", ServiceHeader."Posting Description",
            ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
            ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(Enum::"Gen. Journal Document Type".FromInteger(DocType), DocNo, ExtDocNo, SrcCode, '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := ServiceHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromServiceHeader(ServiceHeader);
        GenJnlLine.SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

        GenJnlLine.CopyFromServiceHeaderApplyTo(ServiceHeader);
        GenJnlLine.CopyFromServiceHeaderPayment(ServiceHeader);

        GenJnlLine.Amount := -TotalServiceLine."Amount Including VAT";
        GenJnlLine."Source Currency Amount" := -TotalServiceLine."Amount Including VAT";
        GenJnlLine."Amount (LCY)" := -TotalServiceLineLCY."Amount Including VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalServiceLineLCY.Amount;
        GenJnlLine."Profit (LCY)" := -(TotalServiceLineLCY.Amount - TotalServiceLineLCY."Unit Cost (LCY)");
        GenJnlLine."Inv. Discount (LCY)" := -TotalServiceLineLCY."Inv. Discount Amount";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalServiceLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            ServiceHeader."Posting Date", ServiceHeader."Currency Code", -TotalServiceLine."Pmt. Discount Amount", ServiceHeader."Currency Factor");

        OnBeforePostCustomerEntry(GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, GenJnlPostLine, GenJnlLineDocNo);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostCustomerEntry(GenJnlLine, ServiceHeader, GenJnlPostLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    procedure PostBalancingEntry(var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostBalancingEntryOnBeforeFindCustLedgerEntry(ServiceHeader, CustLedgEntry, IsHandled);
        if not IsHandled then
            FindCustLedgEntry(Enum::"Gen. Journal Document Type".FromInteger(DocType), DocNo, CustLedgEntry);

        GenJnlLine.InitNewLine(
            ServiceLinePostingDate, ServiceHeader."Document Date", ServiceHeader."VAT Reporting Date", ServiceHeader."Posting Description",
            ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
            ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Refund, DocNo, ExtDocNo, SrcCode, '')
        else
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Payment, DocNo, ExtDocNo, SrcCode, '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := ServiceHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromServiceHeader(ServiceHeader);
        GenJnlLine.SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

        SetApplyToDocNo(ServiceHeader, GenJnlLine, Enum::"Gen. Journal Document Type".FromInteger(DocType), DocNo);

        GenJnlLine.Amount := TotalServiceLine."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        CustLedgEntry.CalcFields(Amount);
        if CustLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalServiceLineLCY."Amount Including VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalServiceLineLCY."Amount Including VAT" +
              Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");
        GenJnlLine."Allow Zero-Amount Posting" := true;

        OnBeforePostBalancingEntry(GenJnlLine, ServiceHeader, TotalServiceLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostBalancingEntry(GenJnlLine, ServiceHeader, GenJnlPostLine);
    end;

    local procedure FindCustLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Document Type", DocType);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.FindLast();
    end;
#endif

#if not CLEAN23
    local procedure SetApplyToDocNo(ServiceHeader: Record "Service Header"; var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        if ServiceHeader."Bal. Account Type" = ServiceHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := ServiceHeader."Bal. Account No.";
        GenJnlLine."Applies-to Doc. Type" := DocType;
        GenJnlLine."Applies-to Doc. No." := DocNo;
    end;
#endif

    procedure PostResJnlLineShip(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        ResJnlLine: Record "Res. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResJnlLineShip(ServiceLine, DocNo, ExtDocNo, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."Time Sheet No." <> '' then
            ServTimeSheetMgt.CheckServiceLine(ServiceLine);

        PostResJnlLine(
          ServiceHeader, ServiceLine,
          DocNo, ExtDocNo, SrcCode, ServiceHeader."Posting No. Series",
          ResJnlLine."Entry Type"::Usage, -ServiceLine."Qty. to Ship",
          ServiceLine.Amount / ServiceLine."Qty. to Ship", -ServiceLine.Amount);

        ServTimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, GenJnlLineDocNo, true);
    end;

    procedure PostResJnlLineUndoUsage(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        PostResJnlLine(
          ServiceHeader, ServiceLine,
          DocNo, ExtDocNo, SrcCode, ServiceHeader."Posting No. Series",
          ResJnlLine."Entry Type"::Usage, -ServiceLine."Qty. to Invoice",
          ServiceLine.Amount / ServiceLine."Qty. to Invoice", -ServiceLine.Amount);
    end;

    procedure PostResJnlLineSale(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        PostResJnlLine(
          ServiceHeader, ServiceLine, DocNo, ExtDocNo, SrcCode, ServiceHeader."Posting No. Series",
          ResJnlLine."Entry Type"::Sale, -ServiceLine."Qty. to Invoice",
          -ServiceLine.Amount / ServiceLine.Quantity, -ServiceLine.Amount);
    end;

    procedure PostResJnlLineConsume(var ServiceLine: Record "Service Line"; var ServShptHeader: Record "Service Shipment Header")
    var
        ResJnlLine: Record "Res. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResJnlLineConsume(ServiceLine, ServShptHeader, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."Time Sheet No." <> '' then
            ServTimeSheetMgt.CheckServiceLine(ServiceLine);

        PostResJnlLine(
          ServiceHeader, ServiceLine,
          ServShptHeader."No.", '', SrcCode, ServShptHeader."No. Series",
          ResJnlLine."Entry Type"::Usage, -ServiceLine."Qty. to Consume", 0, 0);

        ServTimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, GenJnlLineDocNo, false);
    end;

    local procedure PostResJnlLine(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[35]; SrcCode: Code[10]; PostingNoSeries: Code[20]; EntryType: Enum "Res. Journal Line Entry Type"; Qty: Decimal; UnitPrice: Decimal; TotalPrice: Decimal)
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        ResJnlLine.Init();
        OnPostResJnlLineOnAfterResJnlLineInit(ResJnlLine, EntryType, Qty);
        ResJnlLine.CopyDocumentFields(DocNo, ExtDocNo, SrcCode, PostingNoSeries);
        ServiceHeader.CopyToResJournalLine(ResJnlLine);
        ServiceLine.CopyToResJournalLine(ResJnlLine);

        ResJnlLine."Entry Type" := EntryType;
        ResJnlLine.Quantity := Qty;
        ResJnlLine."Unit Cost" := ServiceLine."Unit Cost (LCY)";
        ResJnlLine."Total Cost" := ServiceLine."Unit Cost (LCY)" * ResJnlLine.Quantity;
        ResJnlLine."Unit Price" := UnitPrice;
        ResJnlLine."Total Price" := TotalPrice;

        OnBeforeResJnlPostLine(ResJnlLine, ServiceHeader, ServiceLine);
        ResJnlPostLine.RunWithCheck(ResJnlLine);
        OnAfterPostResJnlLine(ServiceHeader, ResJnlLine);
    end;

    procedure InitServiceRegister(var NextServLedgerEntryNo: Integer; var NextWarrantyLedgerEntryNo: Integer)
    begin
        ServLedgEntryPostSale.InitServiceRegister(NextServLedgerEntryNo, NextWarrantyLedgerEntryNo);
    end;

    procedure FinishServiceRegister(var nextServEntryNo: Integer; var nextWarrantyEntryNo: Integer)
    begin
        ServLedgEntryPostSale.FinishServiceRegister(nextServEntryNo, nextWarrantyEntryNo);
    end;

    procedure InsertServLedgerEntry(var NextEntryNo: Integer; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; Qty: Decimal; DocNo: Code[20]): Integer
    begin
        exit(
          ServLedgEntryPostSale.InsertServLedgerEntry(NextEntryNo, ServiceHeader, ServiceLine, ServItemLine, Qty, DocNo));
    end;

    procedure InsertServLedgerEntrySale(var passedNextEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; Qty: Decimal; QtyToCharge: Decimal; GenJnlLineDocNo: Code[20]; DocLineNo: Integer)
    begin
        ServLedgEntryPostSale.InsertServLedgerEntrySale(
          passedNextEntryNo, ServHeader, ServLine, ServItemLine, Qty, QtyToCharge, GenJnlLineDocNo, DocLineNo);
    end;

    procedure CreateCreditEntry(var passedNextEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; GenJnlLineDocNo: Code[20])
    begin
        ServLedgEntryPostSale.CreateCreditEntry(passedNextEntryNo, ServHeader, ServLine, GenJnlLineDocNo);
    end;

    procedure InsertWarrantyLedgerEntry(var NextWarrantyEntryNo: Integer; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; Qty: Decimal; GenJnlLineDocNo: Code[20]): Integer
    begin
        exit(
          ServLedgEntryPostSale.InsertWarrantyLedgerEntry(
            NextWarrantyEntryNo, ServiceHeader, ServiceLine, ServItemLine, Qty, GenJnlLineDocNo));
    end;

    procedure CalcSLEDivideAmount(Qty: Decimal; var passedServHeader: Record "Service Header"; var passedTempServLine: Record "Service Line"; var passedVATAmountLine: Record "VAT Amount Line")
    begin
        ServLedgEntryPostSale.CalcDivideAmount(Qty, passedServHeader, passedTempServLine, passedVATAmountLine);
    end;

    procedure TestSrvCostDirectPost(ServLineNo: Code[20])
    var
        ServCost: Record "Service Cost";
        GLAcc: Record "G/L Account";
    begin
        ServCost.Get(ServLineNo);
        GLAcc.Get(ServCost."Account No.");
        GLAcc.TestField("Direct Posting", true);
    end;

    procedure TestGLAccDirectPost(ServLineNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get(ServLineNo);
        GLAcc.TestField("Direct Posting", true);
    end;

    procedure CollectValueEntryRelation(var PassedValueEntryRelation: Record "Value Entry Relation"; RowId: Text[100])
    begin
        TempValueEntryRelation.Reset();
        PassedValueEntryRelation.Reset();

        if TempValueEntryRelation.FindSet() then
            repeat
                PassedValueEntryRelation := TempValueEntryRelation;
                PassedValueEntryRelation."Source RowId" := RowId;
                PassedValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0;

        TempValueEntryRelation.DeleteAll();
    end;

    procedure PostJobJnlLine(var ServHeader: Record "Service Header"; ServLine: Record "Service Line"; QtyToBeConsumed: Decimal): Boolean
    var
        JobJnlLine: Record "Job Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        ServiceCost: Record "Service Cost";
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: Record Item;
        Customer: Record Customer;
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        CurrencyFactor: Decimal;
        UnitPriceLCY: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePostJobJnlLine(ServHeader, ServLine, QtyToBeConsumed, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (ServLine."Job No." = '') or (QtyToBeConsumed = 0) then
            exit(false);

        ServLine.TestField(ServLine."Job Task No.");
        Job.LockTable();
        JobTask.LockTable();
        Job.Get(ServLine."Job No.");
        JobTask.Get(ServLine."Job No.", ServLine."Job Task No.");

        JobJnlLine.Init();
        JobJnlLine.DontCheckStdCost();
        JobJnlLine.Validate("Job No.", ServLine."Job No.");
        JobJnlLine.Validate("Job Task No.", ServLine."Job Task No.");
        JobJnlLine.Validate("Line Type", ServLine."Job Line Type");
        JobJnlLine.Validate("Posting Date", ServLine."Posting Date");
        JobJnlLine."Job Posting Only" := true;
        JobJnlLine."No." := ServLine."No.";

        case ServLine.Type of
            ServLine.Type::"G/L Account":
                JobJnlLine.Type := JobJnlLine.Type::"G/L Account";
            ServLine.Type::Item:
                JobJnlLine.Type := JobJnlLine.Type::Item;
            ServLine.Type::Resource:
                JobJnlLine.Type := JobJnlLine.Type::Resource;
            ServLine.Type::Cost:
                begin
                    ServiceCost.SetRange(Code, ServLine."No.");
                    ServiceCost.FindFirst();
                    JobJnlLine.Type := JobJnlLine.Type::"G/L Account";
                    JobJnlLine."No." := ServiceCost."Account No.";
                end;
        end;
        // Case Type
        OnPostJobJnlLineOnBeforeValidateNo(JobJnlLine, ServLine);

        JobJnlLine.Validate("No.");
        JobJnlLine.Description := ServLine.Description;
        JobJnlLine."Description 2" := ServLine."Description 2";
        JobJnlLine."Variant Code" := ServLine."Variant Code";
        JobJnlLine."Unit of Measure Code" := ServLine."Unit of Measure Code";
        JobJnlLine."Qty. per Unit of Measure" := ServLine."Qty. per Unit of Measure";
        JobJnlLine.Validate(Quantity, -QtyToBeConsumed);
        JobJnlLine."Document No." := ServHeader."Shipping No.";
        JobJnlLine."Service Order No." := ServLine."Document No.";
        JobJnlLine."External Document No." := ServHeader."Shipping No.";
        JobJnlLine."Posted Service Shipment No." := ServHeader."Shipping No.";
        if ServLine.Type = ServLine.Type::Item then begin
            Item.Get(ServLine."No.");
            if Item."Costing Method" = Item."Costing Method"::Standard then
                JobJnlLine.Validate("Unit Cost (LCY)", Item."Standard Cost")
            else
                JobJnlLine.Validate("Unit Cost (LCY)", ServLine."Unit Cost (LCY)")
        end else
            JobJnlLine.Validate("Unit Cost (LCY)", ServLine."Unit Cost (LCY)");

        Currency.Initialize(ServLine."Currency Code");
        Customer.Get(ServLine."Customer No.");
        if Customer."Prices Including VAT" then
            ServLine.Validate(ServLine."Unit Price", Round(ServLine."Unit Price" / (1 + (ServLine."VAT %" / 100)), Currency."Unit-Amount Rounding Precision"));

        if ServLine."Currency Code" = Job."Currency Code" then
            JobJnlLine.Validate("Unit Price", ServLine."Unit Price");
        if ServLine."Currency Code" <> '' then begin
            OnPostJobJnlLineOnBeforeCalcCurrencyFactor(ServLine, CurrExchRate);
            CurrencyFactor := CurrExchRate.ExchangeRate(ServLine."Posting Date", ServLine."Currency Code");
            UnitPriceLCY :=
              Round(CurrExchRate.ExchangeAmtFCYToLCY(ServLine."Posting Date", ServLine."Currency Code", ServLine."Unit Price", CurrencyFactor),
                Currency."Amount Rounding Precision");
            JobJnlLine.Validate("Unit Price (LCY)", UnitPriceLCY);
        end else
            JobJnlLine.Validate("Unit Price (LCY)", ServLine."Unit Price");

        JobJnlLine.Validate("Line Discount %", ServLine."Line Discount %");
        JobJnlLine."Job Planning Line No." := ServLine."Job Planning Line No.";
        JobJnlLine."Remaining Qty." := ServLine."Job Remaining Qty.";
        JobJnlLine."Remaining Qty. (Base)" := ServLine."Job Remaining Qty. (Base)";
        JobJnlLine."Location Code" := ServLine."Location Code";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine."Posting Group" := ServLine."Posting Group";
        JobJnlLine."Gen. Bus. Posting Group" := ServLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := ServLine."Gen. Prod. Posting Group";
        JobJnlLine."Customer Price Group" := ServLine."Customer Price Group";
        SourceCodeSetup.Get();
        JobJnlLine."Source Code" := SourceCodeSetup."Service Management";
        JobJnlLine."Work Type Code" := ServLine."Work Type Code";
        JobJnlLine."Shortcut Dimension 1 Code" := ServLine."Shortcut Dimension 1 Code";
        JobJnlLine."Shortcut Dimension 2 Code" := ServLine."Shortcut Dimension 2 Code";
        JobJnlLine."Dimension Set ID" := ServLine."Dimension Set ID";
        OnAfterTransferValuesToJobJnlLine(JobJnlLine, ServLine);

        JobJnlPostLine.RunWithCheck(JobJnlLine);
        exit(true);
    end;

    procedure SetPostingDate(PostingDate: Date)
    begin
        ServiceLinePostingDate := PostingDate;
    end;

    internal procedure PostSalesTaxToGL(var TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary; var TotalServiceLineLCY: Record "Service Line"; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; SalesTaxCountry: Option US,CA,,,,,,,,,,,,NoTax)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        GenJnlLine: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        TaxLineCount: Integer;
        RemSalesTaxAmt: Decimal;
        RemSalesTaxSrcAmt: Decimal;
        UseDate: Date;
    begin
        TaxLineCount := 0;
        RemSalesTaxAmt := 0;
        RemSalesTaxSrcAmt := 0;
        GLSetup.Get();

        if ServiceHeader."Currency Code" <> '' then
            TotalServiceLineLCY."Amount Including VAT" := TotalServiceLineLCY.Amount;
        if TempSalesTaxAmtLine.Find('-') then
            repeat
                TaxLineCount := TaxLineCount + 1;
                if ((TempSalesTaxAmtLine."Tax Base Amount" <> 0) and
                    (TempSalesTaxAmtLine."Tax Type" = TempSalesTaxAmtLine."Tax Type"::"Sales and Use Tax")) or
                   ((TempSalesTaxAmtLine.Quantity <> 0) and
                    (TempSalesTaxAmtLine."Tax Type" = TempSalesTaxAmtLine."Tax Type"::"Excise Tax"))
                then begin
                    GenJnlLine.Init();
                    GenJnlLine."Posting Date" := ServiceHeader."Posting Date";
                    GenJnlLine."Document Date" := ServiceHeader."Document Date";
                    GenJnlLine."VAT Reporting Date" := ServiceHeader."VAT Reporting Date";
                    GenJnlLine.Description := ServiceHeader."Posting Description";
                    GenJnlLine."Reason Code" := ServiceHeader."Reason Code";
                    GenJnlLine."Document Type" := GenJnlLineDocType;
                    GenJnlLine."Document No." := GenJnlLineDocNo;
                    GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                    GenJnlLine."System-Created Entry" := true;
                    GenJnlLine.Amount := 0;
                    GenJnlLine."Source Currency Code" := ServiceHeader."Currency Code";
                    GenJnlLine."Source Currency Amount" := 0;
                    GenJnlLine.Correction := ServiceHeader.Correction;
                    GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
                    GenJnlLine."Tax Area Code" := TempSalesTaxAmtLine."Tax Area Code";
                    GenJnlLine."Tax Type" := TempSalesTaxAmtLine."Tax Type";
                    GenJnlLine."Tax Exemption No." := ServiceHeader."Tax Exemption No.";
                    GenJnlLine."Tax Group Code" := TempSalesTaxAmtLine."Tax Group Code";
                    GenJnlLine."Tax Liable" := TempSalesTaxAmtLine."Tax Liable";
                    GenJnlLine.Quantity := TempSalesTaxAmtLine.Quantity;
                    GenJnlLine."VAT Calculation Type" := GenJnlLine."VAT Calculation Type"::"Sales Tax";
                    GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                    GenJnlLine."Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := ServiceHeader."Dimension Set ID";
                    GenJnlLine."Source Code" := SrcCode;
                    GenJnlLine."EU 3-Party Trade" := ServiceHeader."EU 3-Party Trade";
                    GenJnlLine."Bill-to/Pay-to No." := ServiceHeader."Bill-to Customer No.";
                    GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                    GenJnlLine."Source No." := ServiceHeader."Bill-to Customer No.";
                    GenJnlLine."Posting No. Series" := ServiceHeader."Posting No. Series";
                    GenJnlLine."STE Transaction ID" := ServiceHeader."STE Transaction ID";
                    GenJnlLine."Source Curr. VAT Base Amount" := TempSalesTaxAmtLine."Tax Base Amount";
                    GenJnlLine."VAT Base Amount (LCY)" :=
                      Round(TempSalesTaxAmtLine."Tax Base Amount");
                    GenJnlLine."VAT Base Amount" := GenJnlLine."VAT Base Amount (LCY)";

                    if TaxJurisdiction.Code <> TempSalesTaxAmtLine."Tax Jurisdiction Code" then begin
                        TaxJurisdiction.Get(TempSalesTaxAmtLine."Tax Jurisdiction Code");
                        if SalesTaxCountry = SalesTaxCountry::CA then begin
                            RemSalesTaxAmt := 0;
                            RemSalesTaxSrcAmt := 0;
                        end;
                    end;
                    if ServiceHeader."Currency Code" <> '' then
                        if (ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Quote]) and
                           (ServiceHeader."Posting Date" = 0D)
                        then
                            UseDate := WorkDate()
                        else
                            UseDate := ServiceHeader."Posting Date";
                    if TaxJurisdiction."Unrealized VAT Type" > 0 then begin
                        TaxJurisdiction.TestField("Unreal. Tax Acc. (Sales)");
                        GenJnlLine."Account No." := TaxJurisdiction."Unreal. Tax Acc. (Sales)";
                    end else begin
                        TaxJurisdiction.TestField("Tax Account (Sales)");
                        GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Sales)";
                    end;
                    GenJnlLine."Tax Jurisdiction Code" := TempSalesTaxAmtLine."Tax Jurisdiction Code";
                    if TempSalesTaxAmtLine."Tax Amount" <> 0 then begin
                        RemSalesTaxSrcAmt := RemSalesTaxSrcAmt +
                          CurrExchRate.ExchangeAmtLCYToFCY(
                            UseDate, ServiceHeader."Currency Code", TempSalesTaxAmtLine."Tax Amount", ServiceHeader."Currency Factor");
                        GenJnlLine."Source Curr. VAT Amount" := Round(RemSalesTaxSrcAmt, Currency."Amount Rounding Precision");
                        RemSalesTaxSrcAmt := RemSalesTaxSrcAmt - GenJnlLine."Source Curr. VAT Amount";
                        RemSalesTaxAmt := RemSalesTaxAmt + TempSalesTaxAmtLine."Tax Amount";
                        GenJnlLine."VAT Amount (LCY)" := Round(RemSalesTaxAmt, GLSetup."Amount Rounding Precision");
                        RemSalesTaxAmt := RemSalesTaxAmt - GenJnlLine."VAT Amount (LCY)";
                        GenJnlLine."VAT Amount" := GenJnlLine."VAT Amount (LCY)";
                    end;
                    GenJnlLine."VAT Difference" := TempSalesTaxAmtLine."Tax Difference";

                    if not
                      (ServiceHeader."Document Type" in
                        [ServiceHeader."Document Type"::"Credit Memo"])
                    then begin
                        GenJnlLine."Source Curr. VAT Base Amount" := -GenJnlLine."Source Curr. VAT Base Amount";
                        GenJnlLine."VAT Base Amount (LCY)" := -GenJnlLine."VAT Base Amount (LCY)";
                        GenJnlLine."VAT Base Amount" := -GenJnlLine."VAT Base Amount";
                        GenJnlLine."Source Curr. VAT Amount" := -GenJnlLine."Source Curr. VAT Amount";
                        GenJnlLine."VAT Amount (LCY)" := -GenJnlLine."VAT Amount (LCY)";
                        GenJnlLine."VAT Amount" := -GenJnlLine."VAT Amount";
                        GenJnlLine.Quantity := -GenJnlLine.Quantity;
                        GenJnlLine."VAT Difference" := -GenJnlLine."VAT Difference";
                    end;

                    if ServiceHeader."Currency Code" <> '' then
                        TotalServiceLineLCY."Amount Including VAT" :=
                          TotalServiceLineLCY."Amount Including VAT" + GenJnlLine."VAT Amount (LCY)";

                    OnPostSalesTaxToGLOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, ServiceHeader, TempSalesTaxAmtLine);
                    GenJnlPostLine.RunWithCheck(GenJnlLine);
                end;
            until TempSalesTaxAmtLine.Next() = 0;
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJournalLine: Record "Gen. Journal Line"; var ServiceHeader: Record "Service Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJournalLine: Record "Gen. Journal Line"; var ServiceHeader: Record "Service Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvoicePostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceHeader: Record "Service Header"; GLEntryNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValuesToJobJnlLine(var JobJournalLine: Record "Job Journal Line"; ServiceLine: Record "Service Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; GenJnlLineDocNo: Code[20])
    begin
    end;

    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJournalLine: Record "Gen. Journal Line"; var ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line")
    begin
    end;

    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoicePostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceHeader: Record "Service Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceLine: Record "Service Line"; GenJnlLineDocNo: Code[20]; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJobJnlLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; QtyToBeConsumed: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResJnlPostLine(var ResJnlLine: Record "Res. Journal Line"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceHeader: Record "Service Header"; var ShouldCreateWhseJnlLine: Boolean; ServiceShipmentHeader: Record "Service Shipment Header"; var ServiceLine: Record "Service Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; var WhsePosting: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostJobJnlLineOnBeforeCalcCurrencyFactor(ServLine: Record "Service Line"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostJobJnlLineOnBeforeValidateNo(var JobJournalLine: Record "Job Journal Line"; ServiceLine: Record "Service Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostResJnlLineOnAfterResJnlLineInit(var ResJnlLine: Record "Res. Journal Line"; EntryType: Enum "Res. Journal Line Entry Type"; Qty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesTaxToGLOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

#if not CLEAN23
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '23.0')]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(ServiceHeader: Record "Service Header"; var ItemJournalLine: Record "Item Journal Line"; var TempHandlingTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostResJnlLine(ServiceHeader: Record "Service Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLineShip(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[35]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLineConsume(var ServiceLine: Record "Service Line"; var ServiceShipmentHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}

