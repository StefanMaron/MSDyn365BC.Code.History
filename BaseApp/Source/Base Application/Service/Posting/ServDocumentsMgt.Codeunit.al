﻿namespace Microsoft.Service.Posting;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Utilities;

codeunit 5988 "Serv-Documents Mgt."
{
    Permissions = TableData "Service Header" = rimd,
                  TableData "Service Item Line" = rimd,
                  TableData "Service Line" = rimd,
                  TableData "Service Ledger Entry" = rm,
                  TableData "Warranty Ledger Entry" = rm,
#if not CLEAN23                  
                  TableData "Invoice Post. Buffer" = rimd,
#endif                  
                  TableData "Service Shipment Item Line" = rimd,
                  TableData "Service Shipment Header" = rimd,
                  TableData "Service Shipment Line" = rimd,
                  TableData "Service Invoice Header" = rimd,
                  TableData "Service Invoice Line" = rimd,
                  TableData "Service Cr.Memo Header" = rimd,
                  TableData "Service Cr.Memo Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ServHeader: Record "Service Header" temporary;
        ServLine: Record "Service Line" temporary;
        TempServiceLine: Record "Service Line" temporary;
        ServItemLine: Record "Service Item Line" temporary;
        ServShptHeader: Record "Service Shipment Header" temporary;
        ServShptItemLine: Record "Service Shipment Item Line" temporary;
        ServShptLine: Record "Service Shipment Line" temporary;
        ServInvHeader: Record "Service Invoice Header" temporary;
        ServInvLine: Record "Service Invoice Line" temporary;
        ServCrMemoHeader: Record "Service Cr.Memo Header" temporary;
        ServCrMemoLine: Record "Service Cr.Memo Line" temporary;
        PServLine: Record "Service Line";
        PServItemLine: Record "Service Item Line";
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempInvoicingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationInv: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        SalesSetup: Record "Sales & Receivables Setup";
        ServMgtSetup: Record "Service Mgt. Setup";
        ServDocReg: Record "Service Document Register";
        ServiceCommentLine: Record "Service Comment Line";
        TempWarrantyLedgerEntry: Record "Warranty Ledger Entry" temporary;
        ServPostingJnlsMgt: Codeunit "Serv-Posting Journals Mgt.";
        ServAmountsMgt: Codeunit "Serv-Amounts Mgt.";
        ServITRMgt: Codeunit "Serv-Item Tracking Rsrv. Mgt.";
        ServCalcDisc: Codeunit "Service-Calc. Discount";
        ServOrderMgt: Codeunit ServOrderManagement;
        ServLogMgt: Codeunit ServLogManagement;
        DimMgt: Codeunit DimensionManagement;
        ServAllocMgt: Codeunit ServAllocationManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        InvoicePostingInterface: Interface "Invoice Posting";
        IsInterfaceInitialized: Boolean;
        GenJnlLineExtDocNo: Code[35];
        GenJnlLineDocNo: Code[20];
        SrcCode: Code[10];
        GenJnlLineDocType: Enum "Gen. Journal Document Type";
        ItemLedgShptEntryNo: Integer;
        NextServLedgerEntryNo: Integer;
        NextWarrantyLedgerEntryNo: Integer;
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
        Text007: Label '%1 %2 -> Invoice %3';
        Text008: Label '%1 %2 -> Credit Memo %3';
        Text011: Label 'must have the same sign as the shipment.';
        Text013: Label 'The shipment lines have been deleted.';
        Text014: Label 'You cannot invoice more than you have shipped for order %1.';
        Text015: Label 'The %1 you are going to invoice has a %2 entered.\You may need to run price adjustment. Do you want to continue posting? ';
        Text023: Label 'This order must be a complete Shipment.';
        Text026: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text027: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.';
        Text028: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text029: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. %4';
        Text030: Label 'The dimensions used in %1 %2 are invalid. %3';
        Text031: Label 'The dimensions used in %1 %2, line no. %3 are invalid. %4';
        CloseCondition: Boolean;
        ServLinesPassed: Boolean;
        Text035: Label 'The %1 %2 relates to the same %3 as %1 %4.';
        Text039: Label '%1 %2 on %3 %4 relates to a %5 that has already been invoiced.';
        Text041: Label 'Old %1 service ledger entries have been found for service contract %2.\You must close them by posting the old service invoices.';
        TrackingSpecificationExists: Boolean;
        ServLineInvoicedConsumedQty: Decimal;
        ServLedgEntryNo: Integer;

    procedure Initialize(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line")
    var
        SrcCodeSetup: Record "Source Code Setup";
    begin
        CloseCondition := true;
        OnBeforeInitialize(PassedServiceHeader, PassedServiceLine, CloseCondition);

        Clear(ServPostingJnlsMgt);
        Clear(ServAmountsMgt);
        CheckServiceDocument(PassedServiceHeader, PassedServiceLine);
        ServMgtSetup.Get();
        GetInvoicePostingSetup();
        SalesSetup.Get();
        SrcCodeSetup.Get();
        SrcCode := SrcCodeSetup."Service Management";
        ServPostingJnlsMgt.Initialize(ServHeader, Consume, Invoice);
        ServAmountsMgt.Initialize(ServHeader."Currency Code"); // roundingLineInserted is set to FALSE;
        TrackingSpecificationExists := false;

        OnAfterInitialize(PassedServiceHeader, PassedServiceLine, CloseCondition, Ship, Consume, Invoice);
    end;

    procedure CheckServiceDocument(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line")
    begin
        PrepareDocument(PassedServiceHeader, PassedServiceLine);
        PassedServiceHeader.ValidateSalesPersonOnServiceHeader(PassedServiceHeader, true, true);
        CheckSysCreatedEntry();
        CheckShippingAdvice();
        CheckDimensions();
        GetAndCheckCustomer();


        CheckVATDate(PassedServiceHeader);
    end;

    local procedure GetInvoicePostingSetup()
    var
        IsHandled: Boolean;
    begin
#if not CLEAN23
        if UseLegacyInvoicePosting() then
            exit;
#endif
        if IsInterfaceInitialized then
            exit;

        IsHandled := false;
        OnBeforeGetInvoicePostingSetup(InvoicePostingInterface, IsHandled);
        if not IsHandled then
            InvoicePostingInterface := "Service Invoice Posting"::"Invoice Posting (v.19)";

        InvoicePostingInterface.Check(Database::"Service Header");
        IsInterfaceInitialized := true;
    end;

    local procedure GetInvoicePostingParameters()
    begin
        Clear(InvoicePostingParameters);
        InvoicePostingParameters."Document Type" := GenJnlLineDocType;
        InvoicePostingParameters."Document No." := GenJnlLineDocNo;
        InvoicePostingParameters."External Document No." := GenJnlLineExtDocNo;
        InvoicePostingParameters."Source Code" := SrcCode;
        InvoicePostingParameters."Auto Document No." := '';
    end;

    procedure CalcInvDiscount()
    begin
        if SalesSetup."Calc. Inv. Discount" then begin
            ServLine.Find('-');
            ServCalcDisc.CalculateWithServHeader(ServHeader, PServLine, ServLine);
        end;
    end;

    procedure PostDocumentLines(var Window: Dialog)
    var
        ServiceLineACY: Record "Service Line";
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ServLineOld: Record "Service Line";
        TempServLine2: Record "Service Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineForSLE: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
#if not CLEAN23
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
#endif        
        DummyTrackingSpecification: Record "Tracking Specification";
        Item: Record Item;
        ServItemMgt: Codeunit ServItemManagement;
        ErrorContextElementProcessLine: Codeunit "Error Context Element";
        ErrorContextElementPostLine: Codeunit "Error Context Element";
        ZeroServiceLineRecID: RecordId;
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal;
        RemQtyToBeConsumed: Decimal;
        RemQtyToBeConsumedBase: Decimal;
        TotalAmount: Decimal;
        LineCount: Integer;
        ApplToServEntryNo: Integer;
        WarrantyNo: Integer;
        BiggestLineNo: Integer;
        LastLineRetrieved: Boolean;
        ShouldPostShipmentServiceEntry: Boolean;
        IsHandled: Boolean;
        PostDocumentLinesMsg: Label 'Post document lines.';
    begin
        LineCount := 0;

        // init cu for posting SLE type Usage
        ServPostingJnlsMgt.InitServiceRegister(NextServLedgerEntryNo, NextWarrantyLedgerEntryNo);
        OnPostDocumentLinesOnBeforeFilterServiceLine(ServHeader, ServLine);
        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then begin
            ServLine.CalcVATAmountLines(1, ServHeader, ServLine, TempVATAmountLine, Ship);
            ServLine.CalcVATAmountLines(2, ServHeader, ServLine, TempVATAmountLineForSLE, Ship);
        end;

        GetZeroServiceLineRecID(ServHeader, ZeroServiceLineRecID);
        ErrorMessageMgt.PushContext(ErrorContextElementProcessLine, ZeroServiceLineRecID, 0, PostDocumentLinesMsg);

        ServLine.Reset();
        SortLines(ServLine);
        OnPostDocumentLinesOnAfterSortLines(ServHeader, ServLine);
        ServLedgEntryNo := FindFirstServLedgEntry(ServLine);
        if ServLine.Find('-') then
            repeat
                ErrorMessageMgt.PushContext(ErrorContextElementPostLine, ServLine.RecordId, 0, PostDocumentLinesMsg);
                ServPostingJnlsMgt.SetItemJnlRollRndg(false);
                if ServLine.Type = ServLine.Type::Item then
                    DummyTrackingSpecification.CheckItemTrackingQuantity(
                      Database::"Service Line", ServLine."Document Type", ServLine."Document No.", ServLine."Line No.",
                      ServLine."Qty. to Ship (Base)", ServLine."Qty. to Invoice (Base)", Ship, Invoice);
                LineCount += 1;
                Window.Update(2, LineCount);

                with ServLine do begin
                    IsHandled := false;
                    OnPostDocumentLinesOnBeforeCheckServLine(ServHeader, ServLine, Ship, Invoice, ServItemLine, IsHandled);
                    if not IsHandled then
                        if Ship and ("Qty. to Ship" <> 0) or Invoice and ("Qty. to Invoice" <> 0) then
                            ServOrderMgt.CheckServItemRepairStatus(ServHeader, ServItemLine, ServLine);

                    ServLineOld := ServLine;
                    if "Spare Part Action" in
                       ["Spare Part Action"::"Component Replaced",
                        "Spare Part Action"::Permanent,
                        "Spare Part Action"::"Temporary"]
                    then begin
                        "Spare Part Action" := "Spare Part Action"::"Component Installed";
                        Modify();
                    end;

                    // post Service Ledger Entry of type Usage, on shipment
                    ShouldPostShipmentServiceEntry :=
                        (Ship and ("Document Type" = "Document Type"::Order) or
                        ("Document Type" = "Document Type"::Invoice)) and
                       ("Qty. to Ship" <> 0) and not ServAmountsMgt.RoundingLineInserted();
                    OnPostDocumentLinesOnAfterCalcShouldPostShipmentServiceEntry(ServHeader, ServLine, Ship, ApplToServEntryNo, NextServLedgerEntryNo, ShouldPostShipmentServiceEntry);
                    if ShouldPostShipmentServiceEntry then begin
                        TempServLine2 := ServLine;
                        ServPostingJnlsMgt.CalcSLEDivideAmount("Qty. to Ship", ServHeader, TempServLine2, TempVATAmountLineForSLE);

                        ApplToServEntryNo :=
                          ServPostingJnlsMgt.InsertServLedgerEntry(
                            NextServLedgerEntryNo, ServHeader, TempServLine2, ServItemLine, "Qty. to Ship", ServHeader."Shipping No.");
                        OnPostDocumentLinesOnAfterAssignApplToServEntryNo(ServHeader, ApplToServEntryNo);

                        if "Appl.-to Service Entry" = 0 then
                            "Appl.-to Service Entry" := ApplToServEntryNo;
                    end;

                    if (Type = Type::Item) and ("No." <> '') then begin
                        GetServLineItem(ServLine, Item);
                        if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment() then
                            GetUnitCost();
                        if Item.IsVariantMandatory() then
                            ServLine.TestField("Variant Code");
                    end;

                    if CheckCloseCondition(
                         Quantity, "Qty. to Invoice", "Qty. to Consume", "Quantity Invoiced", "Quantity Consumed") = false
                    then
                        CloseCondition := false;

                    OnPostDocumentLinesOnAfterCheckCloseCondition(ServHeader, ServLine, ServItemLine);

                    if Quantity = 0 then
                        TestField("Line Amount", 0)
                    else begin
                        TestBinCode();
                        TestField("No.");
                        TestField(Type);
                        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then begin
                            TestField("Gen. Bus. Posting Group");
                            TestField("Gen. Prod. Posting Group");
                        end;
                        ServAmountsMgt.DivideAmount(1, "Qty. to Invoice", ServHeader, ServLine,
                          TempVATAmountLine, TempVATAmountLineRemainder);
                    end;

                    OnPostDocumentLinesOnBeforeRoundAmount(ServLine);

                    ServAmountsMgt.RoundAmount("Qty. to Invoice", ServHeader, ServLine,
                      TempServiceLine, TotalServiceLine, TotalServiceLineLCY, ServiceLineACY);

                    if "Document Type" <> "Document Type"::"Credit Memo" then begin
                        ServAmountsMgt.ReverseAmount(ServLine);
                        ServAmountsMgt.ReverseAmount(ServiceLineACY);
                    end;

                    // post Service Ledger Entry of type Sale, on invoice
                    if "Document Type" = "Document Type"::"Credit Memo" then begin
                        CheckIfServDuplicateLine(ServLine);
                        IsHandled := false;
                        OnPostDocumentLinesOnBeforeCreateCreditEntry(ServHeader, ServLine, GenJnlLineDocNo, IsHandled);
                        if not IsHandled then
                            ServPostingJnlsMgt.CreateCreditEntry(NextServLedgerEntryNo,
                              ServHeader, ServLine, GenJnlLineDocNo);
                        OnPostDocumentLinesOnAfterServPostingJnlsMgtCreateCreditEntry(NextServLedgerEntryNo, ApplToServEntryNo, ServHeader, ServLine);
                    end else
                        if (Invoice or ("Document Type" = "Document Type"::Invoice)) and
                           ("Qty. to Invoice" <> 0) and not ServAmountsMgt.RoundingLineInserted()
                        then begin
                            CheckIfServDuplicateLine(ServLine);
                            ServPostingJnlsMgt.InsertServLedgerEntrySale(NextServLedgerEntryNo,
                              ServHeader, ServLine, ServItemLine, "Qty. to Invoice", "Qty. to Invoice", GenJnlLineDocNo, "Line No.");
                            OnPostDocumentLinesOnAfterServPostingJnlsMgtInsertServLedgerEntrySaleInvoice(NextServLedgerEntryNo);
                        end;

                    InsertServLedgerEntrySaleConsume();

                    RemQtyToBeInvoiced := "Qty. to Invoice";
                    RemQtyToBeConsumed := "Qty. to Consume";
                    RemQtyToBeInvoicedBase := "Qty. to Invoice (Base)";
                    RemQtyToBeConsumedBase := "Qty. to Consume (Base)";

                    if Invoice then
                        if "Qty. to Invoice" = 0 then
                            TrackingSpecificationExists := false
                        else
                            TrackingSpecificationExists :=
                              ServITRMgt.RetrieveInvoiceSpecification(ServLine, TempInvoicingSpecification, false);

                    if Consume then
                        if "Qty. to Consume" = 0 then
                            TrackingSpecificationExists := false
                        else
                            TrackingSpecificationExists :=
                              ServITRMgt.RetrieveInvoiceSpecification(ServLine, TempInvoicingSpecification, true);

                    // update previously shipped lines with invoicing information.
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        UpdateRcptLinesOnInv()
                    else // Order or Invoice
                        UpdateShptLinesOnInv(ServLine,
                          RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                          RemQtyToBeConsumed, RemQtyToBeConsumedBase);

                    if TrackingSpecificationExists then
                        ServITRMgt.SaveInvoiceSpecification(TempInvoicingSpecification, TempTrackingSpecification);

                    // post service line via journals
                    case Type of
                        Type::Item:
                            PostServiceItemLine(
                              ServHeader, ServLine, RemQtyToBeInvoicedBase, RemQtyToBeInvoiced, RemQtyToBeConsumedBase, RemQtyToBeConsumed,
                              WarrantyNo);
                        Type::Resource:
                            PostServiceResourceLine(ServLine, WarrantyNo);
                    end;

                    if Consume and ("Document Type" = "Document Type"::Order) then begin
                        OnPostDocumentLinesOnBeforePostRemQtyToBeConsumed(ServHeader, ServLine);
                        if ServPostingJnlsMgt.PostJobJnlLine(ServHeader, ServLine, RemQtyToBeConsumed) then
                            UpdateServiceLedgerEntry(NextServLedgerEntryNo - 1)
                        else
                            if (Type = Type::Resource) and (RemQtyToBeConsumed <> 0) then
                                ServPostingJnlsMgt.PostResJnlLineConsume(ServLine, ServShptHeader);
                    end;

                    if Ship and ("Document Type" = "Document Type"::Order) then begin
                        // component spare part action
                        ServItemMgt.AddOrReplaceSIComponent(ServLineOld, ServHeader,
                          ServHeader."Shipping No.", ServLineOld."Line No.", TempTrackingSpecification);
                        // allocations
                        ServAllocMgt.SetServLineAllocStatus(TempServiceLine);
                    end;

                    if (Type <> Type::" ") and ("Qty. to Invoice" <> 0) then
#if not CLEAN23
                        if UseLegacyInvoicePosting() then
                            ServAmountsMgt.FillInvoicePostBuffer(TempInvoicePostBuffer, ServLine, ServiceLineACY, ServHeader)
                        else
#endif
                            InvoicePostingInterface.PrepareLine(ServHeader, ServLine, ServiceLineACY);

                    OnPostDocumentLinesOnAfterFillInvPostingBuffer(ServHeader, ServLine, ServiceLineACY, ServInvHeader, ServCrMemoHeader, ServShptHeader);

                    // prepare posted document lines
                    if Ship then
                        PrepareShipmentLine(TempServiceLine, WarrantyNo);
                    if Invoice then
                        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                            PrepareInvoiceLine(TempServiceLine)
                        else
                            PrepareCrMemoLine(TempServiceLine);
                    OnPostDocumentLinesOnAfterPrepareLine(ServHeader, ServLine, ServInvHeader, ServCrMemoHeader, ServShptHeader);

                    if Invoice or Consume then
                        CollectValueEntryRelation();

                    if ServAmountsMgt.RoundingLineInserted() then
                        LastLineRetrieved := true
                    else begin
                        BiggestLineNo := ServAmountsMgt.MAX(ServAmountsMgt.GetLastLineNo(ServLine), "Line No.");
                        LastLineRetrieved := Next() = 0; // ServLine
                        if LastLineRetrieved and SalesSetup."Invoice Rounding" then
                            ServAmountsMgt.InvoiceRounding(ServHeader, ServLine, TotalServiceLine,
                              LastLineRetrieved, false, BiggestLineNo);
                    end;
                end; // With ServLine
                ErrorMessageMgt.PopContext(ErrorContextElementPostLine);
            until LastLineRetrieved;

        ErrorMessageMgt.PopContext(ErrorContextElementProcessLine);
        ErrorMessageMgt.Finish(ZeroServiceLineRecID);

        with ServHeader do begin
            // again reverse amount
            if "Document Type" <> "Document Type"::"Credit Memo" then begin
                ServAmountsMgt.ReverseAmount(TotalServiceLine);
                ServAmountsMgt.ReverseAmount(TotalServiceLineLCY);
                TotalServiceLineLCY."Unit Cost (LCY)" := -TotalServiceLineLCY."Unit Cost (LCY)";
            end;

            ServPostingJnlsMgt.FinishServiceRegister(NextServLedgerEntryNo, NextWarrantyLedgerEntryNo);
            OnPostDocumentLinesOnAfterFinishServiceRegister(ServLine);

            if Invoice or ("Document Type" = "Document Type"::Invoice) then begin
                Clear(ServDocReg);
                // fake service register entry to be used in the following PostServSalesDocument()
                if Invoice and ("Document Type" = "Document Type"::Order) and (ServLine."Contract No." <> '') then
                    ServDocReg.InsertServiceSalesDocument(
                      ServDocReg."Source Document Type"::Contract, ServLine."Contract No.",
                      ServDocReg."Destination Document Type"::Invoice, ServLine."Document No.");
                ServDocReg.PostServiceSalesDocument(
                  ServDocReg."Destination Document Type"::Invoice,
                  ServLine."Document No.", ServInvHeader."No.");
            end;
            if Invoice or ("Document Type" = "Document Type"::"Credit Memo") then begin
                Clear(ServDocReg);
                ServDocReg.PostServiceSalesDocument(
                  ServDocReg."Destination Document Type"::"Credit Memo",
                  ServLine."Document No.", ServCrMemoHeader."No.");
            end;

            // Post sales and VAT to G/L entries from posting buffer
            if Invoice then begin
#if not CLEAN23
                if UseLegacyInvoicePosting() then begin
                    OnPostDocumentLinesOnBeforePostInvoicePostBuffer(
                        ServHeader, TempInvoicePostBuffer, TotalServiceLine, TotalServiceLineLCY);
                    LineCount := 0;
                    if TempInvoicePostBuffer.Find('+') then
                        repeat
                            LineCount += 1;
                            Window.Update(3, LineCount);
                            ServPostingJnlsMgt.SetPostingDate("Posting Date");
                            ServPostingJnlsMgt.PostInvoicePostBufferLine(
                                TempInvoicePostBuffer, GenJnlLineDocType.AsInteger(), GenJnlLineDocNo, GenJnlLineExtDocNo);
                        until TempInvoicePostBuffer.Next(-1) = 0;
                end else begin
#endif
                    GetInvoicePostingParameters();
                    InvoicePostingInterface.SetParameters(InvoicePostingParameters);
                    InvoicePostingInterface.SetTotalLines(TotalServiceLine, TotalServiceLineLCY);
                    ServPostingJnlsMgt.PostLines(ServHeader, InvoicePostingInterface, Window, TotalAmount);
#if not CLEAN23
                end;
#endif

                // Post customer entry
                Window.Update(4, 1);
#if not CLEAN23
                if UseLegacyInvoicePosting() then begin
                    ServPostingJnlsMgt.SetPostingDate("Posting Date");
                    ServPostingJnlsMgt.PostCustomerEntry(
                        TotalServiceLine, TotalServiceLineLCY, GenJnlLineDocType.AsInteger(), GenJnlLineDocNo, GenJnlLineExtDocNo);
                end else begin
#endif
                    GetInvoicePostingParameters();
                    InvoicePostingInterface.SetParameters(InvoicePostingParameters);
                    InvoicePostingInterface.SetTotalLines(TotalServiceLine, TotalServiceLineLCY);
                    ServPostingJnlsMgt.PostLedgerEntry(ServHeader, InvoicePostingInterface);
#if not CLEAN23
                end;
#endif

                // post Balancing account
                if "Bal. Account No." <> '' then begin
                    Window.Update(5, 1);
#if not CLEAN23
                    if UseLegacyInvoicePosting() then begin
                        ServPostingJnlsMgt.SetPostingDate("Posting Date");
                        ServPostingJnlsMgt.PostBalancingEntry(
                            TotalServiceLine, TotalServiceLineLCY, GenJnlLineDocType.AsInteger(), GenJnlLineDocNo, GenJnlLineExtDocNo);
                    end else begin
#endif
                        InvoicePostingInterface.SetParameters(InvoicePostingParameters);
                        InvoicePostingInterface.SetTotalLines(TotalServiceLine, TotalServiceLineLCY);
                        ServPostingJnlsMgt.PostBalancingEntry(ServHeader, InvoicePostingInterface);
#if not CLEAN23
                    end;
#endif
                end;

                MakeInvtAdjustment();
                ServPostingJnlsMgt.CreateBills(TotalServiceLine, Window, GenJnlLineDocNo, GenJnlLineExtDocNo);
            end;

            MakeInvtAdjustment();
            if Ship then begin
                "Last Shipping No." := "Shipping No.";
                "Shipping No." := '';
            end;

            if Invoice then begin
                "Last Posting No." := "Posting No.";
                "Posting No." := '';
            end;

            Modify();
        end;// with header

        OnAfterPostDocumentLines(ServHeader, ServInvHeader, ServInvLine, ServCrMemoHeader, ServCrMemoLine, GenJnlLineDocType, GenJnlLineDocNo);
    end;

    local procedure InsertServLedgerEntrySaleConsume()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServLedgerEntrySaleConsume(ServHeader, ServLine, ServItemLine, ServMgtSetup, NextServLedgerEntryNo, GenJnlLineDocNo, Consume, IsHandled);
        if not IsHandled then
            with ServLine do
                if Consume and ("Document Type" = "Document Type"::Order) and
                   ("Qty. to Consume" <> 0)
                then
                    ServPostingJnlsMgt.InsertServLedgerEntrySale(NextServLedgerEntryNo,
                      ServHeader, ServLine, ServItemLine, "Qty. to Consume", 0, ServHeader."Shipping No.", "Line No.");

        OnAfterInsertServLedgerEntrySaleConsume(NextServLedgerEntryNo);
    end;

    local procedure PostServiceItemLine(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; RemQtyToBeInvoicedBase: Decimal; RemQtyToBeInvoiced: Decimal; RemQtyToBeConsumedBase: Decimal; RemQtyToBeConsumed: Decimal; var WarrantyNo: Integer)
    var
        TempServLine: Record "Service Line" temporary;
        TempVATAmountLineForSLE: Record "VAT Amount Line" temporary;
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        OnBeforePostServiceItemLine(ServLine);
        with ServLine do begin
            if Ship and ("Document Type" = "Document Type"::Order) then begin
                TempServLine := ServLine;
                ServPostingJnlsMgt.CalcSLEDivideAmount("Qty. to Ship", ServHeader, TempServLine, TempVATAmountLineForSLE);
                WarrantyNo :=
                  ServPostingJnlsMgt.InsertWarrantyLedgerEntry(
                    NextWarrantyLedgerEntryNo, ServHeader, TempServLine, ServItemLine, "Qty. to Ship", ServHeader."Shipping No.");
            end;

            if Invoice and (RemQtyToBeInvoiced <> 0) then
                ItemLedgShptEntryNo :=
                  ServPostingJnlsMgt.PostItemJnlLine(
                    ServLine,
                    RemQtyToBeInvoiced, RemQtyToBeInvoicedBase, 0, 0, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase, 0,
                    DummyTrackingSpecification, TempTrackingSpecificationInv, TempHandlingSpecification, TempTrackingSpecification,
                    ServShptHeader, '');

            if Consume and (RemQtyToBeConsumed <> 0) then
                ItemLedgShptEntryNo :=
                  ServPostingJnlsMgt.PostItemJnlLine(
                    ServLine,
                    RemQtyToBeConsumed, RemQtyToBeConsumedBase, RemQtyToBeConsumed, RemQtyToBeConsumedBase, 0, 0, 0,
                    DummyTrackingSpecification, TempTrackingSpecificationInv, TempHandlingSpecification, TempTrackingSpecification,
                    ServShptHeader, '');

            if not ("Document Type" in ["Document Type"::"Credit Memo"]) then
                if ((Abs("Qty. to Ship") - Abs("Qty. to Consume") - Abs("Qty. to Invoice")) > Abs(RemQtyToBeConsumed)) or
                   ((Abs("Qty. to Ship") - Abs("Qty. to Consume") - Abs("Qty. to Invoice")) > Abs(RemQtyToBeInvoiced))
                then
                    ItemLedgShptEntryNo :=
                      ServPostingJnlsMgt.PostItemJnlLine(
                        ServLine,
                        "Qty. to Ship" - RemQtyToBeInvoiced - RemQtyToBeConsumed,
                        "Qty. to Ship (Base)" - RemQtyToBeInvoicedBase - RemQtyToBeConsumedBase,
                        0, 0, 0, 0, 0, DummyTrackingSpecification, TempTrackingSpecificationInv,
                        TempHandlingSpecification, TempTrackingSpecification, ServShptHeader, '');
        end;
    end;

    local procedure PostServiceResourceLine(var ServLine: Record "Service Line"; var WarrantyNo: Integer)
    var
        TempServLine: Record "Service Line" temporary;
        TempVATAmountLineForSLE: Record "VAT Amount Line" temporary;
    begin
        with ServLine do begin
            TempServLine := ServLine;
            OnPostServiceResourceLineOnBeforeCalcSLEDivideAmount(ServLine);
            ServPostingJnlsMgt.CalcSLEDivideAmount("Qty. to Ship", ServHeader, TempServLine, TempVATAmountLineForSLE);

            if Ship and ("Document Type" = "Document Type"::Order) then
                WarrantyNo :=
                  ServPostingJnlsMgt.InsertWarrantyLedgerEntry(
                    NextWarrantyLedgerEntryNo, ServHeader, TempServLine, ServItemLine, "Qty. to Ship", ServHeader."Shipping No.");

            if "Document Type" = "Document Type"::"Credit Memo" then
                ServPostingJnlsMgt.PostResJnlLineUndoUsage(ServLine, GenJnlLineDocNo, GenJnlLineExtDocNo)
            else
                PostResourceUsage(TempServLine);

            if "Qty. to Invoice" <> 0 then
                ServPostingJnlsMgt.PostResJnlLineSale(ServLine, GenJnlLineDocNo, GenJnlLineExtDocNo);
        end;

        OnAfterPostServiceResourceLine(ServHeader, ServLine, ServMgtSetup, TempServLine, GenJnlLineDocNo, GenJnlLineExtDocNo, Ship, Invoice, Consume);
    end;

    local procedure MakeInvtAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");

        OnAfterMakeInvtAdjustment(InvtSetup, ServHeader);
    end;

    procedure UpdateDocumentLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocumentLines(ServHeader, CloseCondition, ServLinesPassed, IsHandled);
        if IsHandled then
            exit;

        with ServHeader do begin
            Modify();
            if ("Document Type" = "Document Type"::Order) and not CloseCondition then begin
                ServITRMgt.InsertTrackingSpecification(ServHeader, TempTrackingSpecification);

                // update service line quantities according to posted values
                UpdateServLinesOnPostOrder();
            end else begin
                // close condition met for order, or we post Invoice or CrMemo

                if ServLinesPassed then
                    UpdateServLinesOnPostOrder();

                case "Document Type" of
                    "Document Type"::Invoice:
                        UpdateServLinesOnPostInvoice();
                    "Document Type"::"Credit Memo":
                        UpdateServLinesOnPostCrMemo();
                end;// case

                ServAllocMgt.SetServOrderAllocStatus(ServHeader);
            end; // End CloseConditionMet
        end;
    end;

    local procedure PrepareDocument(var ServiceHeader2: Record "Service Header"; var ServiceLine2: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        // fill ServiceHeader we will work with (tempTable)
        ServHeader.DeleteAll();
        ServHeader.Copy(ServiceHeader2);
        ServHeader.Insert(); // temporary table

        // Fetch persistent Service Lines and Service Item Lines bound to Service Header.
        // Copy persistent records to temporary.
        with ServHeader do begin
            ServLine.DeleteAll();
            ServiceLine2.Reset();
            // collect passed lines
            OnPrepareDocumentOnBeforePassedServLineFind(ServiceLine2, ServHeader);
            if ServiceLine2.Find('-') then begin
                repeat
                    IsHandled := false;
                    OnPrepareDocumentOnServLineInsert(ServiceHeader2, ServLine, ServiceLine2, IsHandled);
                    if not IsHandled then begin
                        ServLine.Copy(ServiceLine2);
                        ServLine.Insert();
                    end;
                until ServiceLine2.Next() = 0;
                ServLinesPassed := true; // indicate either we collect passed or all SLs.
            end else begin
                // collect persistent lines related to ServHeader
                PServLine.Reset();
                PServLine.SetRange("Document Type", "Document Type");
                PServLine.SetRange("Document No.", "No.");
                OnPrepareDocumentOnAfterSetPServLineFilters(PServLine);
                if PServLine.Find('-') then
                    repeat
                        ServLine.Copy(PServLine);
                        ServLine."Posting Date" := "Posting Date";
                        OnPrepareDocumentOnPServLineLoopOnBeforeServLineInsert(ServLine, PServLine);
                        ServLine.Insert(); // temptable
                    until PServLine.Next() = 0;
                ServLinesPassed := false;
            end;

            RemoveLinesNotSatisfyPosting();

            ServItemLine.DeleteAll();
            PServItemLine.Reset();
            PServItemLine.SetRange("Document Type", "Document Type");
            PServItemLine.SetRange("Document No.", "No.");
            OnPrepareDocumentOnAfterSetPServItemLineFilters(PServItemLine);
            if PServItemLine.Find('-') then
                repeat
                    ServItemLine.Copy(PServItemLine);
                    ServItemLine.Insert(); // temptable
                until PServItemLine.Next() = 0;
        end;

        OnAfterPrepareDocument(ServiceHeader2, ServiceLine2);
    end;

    procedure PrepareShipmentHeader(): Code[20]
    var
        ServiceShipmentHeader2: Record "Service Shipment Header";
        ServiceShipmentLine2: Record "Service Shipment Line";
        ServItemManagement: Codeunit ServItemManagement;
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        with ServHeader do begin
            if ("Document Type" = "Document Type"::Order) or
               (("Document Type" = "Document Type"::Invoice) and ServMgtSetup."Shipment on Invoice")
            then begin
                ServiceShipmentHeader2.LockTable();
                ServiceShipmentLine2.LockTable();

                ServShptHeader.Init();
                ServShptHeader.TransferFields(ServHeader);
                ServShptHeader."No." := "Shipping No.";
                if "Document Type" = "Document Type"::Order then begin
                    ServShptHeader."Order No. Series" := "No. Series";
                    ServShptHeader."Order No." := "No.";
                end;
                if ServMgtSetup."Copy Comments Order to Shpt." then
                    RecordLinkManagement.CopyLinks(ServHeader, ServShptHeader);
                ServShptHeader."Source Code" := SrcCode;
                ServShptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServShptHeader."User ID"));
                ServShptHeader."No. Printed" := 0;
                OnBeforeServShptHeaderInsert(ServShptHeader, ServHeader);
                ServShptHeader.Insert();
                OnAfterServShptHeaderInsert(ServShptHeader, ServHeader);

                Clear(ServLogMgt);
                ServLogMgt.ServOrderShipmentPost("No.", ServShptHeader."No.");

                if ("Document Type" = "Document Type"::Order) and ServMgtSetup."Copy Comments Order to Shpt." then
                    ServOrderMgt.CopyCommentLines(
                      "Service Comment Table Name"::"Service Header".AsInteger(),
                      "Service Comment Table Name"::"Service Shipment Header".AsInteger(),
                      "No.", ServShptHeader."No.");

                // create Service Shipment Item Lines
                ServItemLine.Reset();
                if ServItemLine.Find('-') then
                    repeat
                        IsHandled := false;
                        OnPrepareShipmentHeaderOnBeforeCreateServiceShipmentItemLine(ServHeader, ServItemLine, IsHandled);
                        if not IsHandled then begin // create SSIL
                            ServShptItemLine.TransferFields(ServItemLine);
                            ServShptItemLine."No." := ServShptHeader."No.";
                            OnBeforeServShptItemLineInsert(ServShptItemLine, ServItemLine);
                            ServShptItemLine.Insert();
                            OnAfterServShptItemLineInsert(ServShptItemLine, ServItemLine);
                        end;

                        // set mgt. date and service dates
                        CalcContractDates();

                        IsHandled := false;
                        OnPrepareShipmentHeaderOnBeforeCalcServItemDates(ServHeader, ServItemLine, IsHandled);
                        if not IsHandled then
                            ServOrderMgt.CalcServItemDates(ServHeader, ServItemLine."Service Item No.");
                    until ServItemLine.Next() = 0
                else begin
                    ServShptItemLine.Init();
                    ServShptItemLine."No." := ServShptHeader."No.";
                    ServShptItemLine."Line No." := 10000;
                    ServShptItemLine.Description := Format("Document Type") + ' ' + "No.";
                    ServShptItemLine.Insert();
                end;
            end;

            ServItemManagement.CopyReservationEntryService(ServHeader);

            OnAfterPrepareShipmentHeader(ServShptHeader, ServHeader);
            exit(ServShptHeader."No.");
        end;
    end;

    local procedure CalcContractDates()
    var
        ServLineLocal: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcContractDates(ServItemLine, IsHandled);
        if IsHandled then
            exit;

        with ServHeader do
            if (ServItemLine."Contract No." <> '') and (ServItemLine."Contract Line No." <> 0) and
               ("Contract No." <> '')
            then begin
                ServLineLocal.SetRange("Document Type", "Document Type");
                ServLineLocal.SetRange("Document No.", "No.");
                ServLineLocal.SetFilter("Quantity Shipped", '>%1', 0);
                if ServLineLocal.IsEmpty() then
                    ServOrderMgt.CalcContractDates(ServHeader, ServItemLine);
            end;
    end;

    local procedure PrepareShipmentLine(var passedServLine: Record "Service Line"; passedWarrantyNo: Integer)
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        with passedServLine do begin
            if (ServShptHeader."No." <> '') and ("Shipment No." = '') and not ServAmountsMgt.RoundingLineInserted() then begin
                // Insert shipment line
                ServShptLine.Init();
                ServShptLine.TransferFields(passedServLine);
                ServShptLine."Document No." := ServShptHeader."No.";
                ServShptLine.Quantity := "Qty. to Ship";
                ServShptLine."Quantity (Base)" := "Qty. to Ship (Base)";
                ServShptLine."Appl.-to Warranty Entry" := passedWarrantyNo;
                if Abs("Qty. to Consume") > Abs("Qty. to Ship" - "Qty. to Invoice") then begin
                    ServShptLine."Quantity Consumed" := "Qty. to Ship" - "Qty. to Invoice";
                    ServShptLine."Qty. Consumed (Base)" := "Qty. to Ship (Base)" - "Qty. to Invoice (Base)";
                end else begin
                    ServShptLine."Quantity Consumed" := "Qty. to Consume";
                    ServShptLine."Qty. Consumed (Base)" := "Qty. to Consume (Base)";
                end;
                if Abs("Qty. to Invoice") > Abs("Qty. to Ship" - "Qty. to Consume") then begin
                    ServShptLine."Quantity Invoiced" := "Qty. to Ship" - "Qty. to Consume";
                    ServShptLine."Qty. Invoiced (Base)" := "Qty. to Ship (Base)" - "Qty. to Consume (Base)";
                end else begin
                    ServShptLine."Quantity Invoiced" := "Qty. to Invoice";
                    ServShptLine."Qty. Invoiced (Base)" := "Qty. to Invoice (Base)";
                end;
                ServShptLine."Qty. Shipped Not Invoiced" := ServShptLine.Quantity -
                  ServShptLine."Quantity Invoiced" - ServShptLine."Quantity Consumed";
                ServShptLine."Qty. Shipped Not Invd. (Base)" := ServShptLine."Quantity (Base)" -
                  ServShptLine."Qty. Invoiced (Base)" - ServShptLine."Qty. Consumed (Base)";
                if "Document Type" = "Document Type"::Order then begin
                    ServShptLine."Order No." := "Document No.";
                    ServShptLine."Order Line No." := "Line No.";
                end;

                if (Type = Type::Item) and ("Qty. to Ship" <> 0) then
                    ServShptLine."Item Shpt. Entry No." :=
                      ServITRMgt.InsertShptEntryRelation(ServShptLine,
                        TempHandlingSpecification, TempTrackingSpecificationInv, ItemLedgShptEntryNo);

                CalcFields("Service Item Line Description");
                ServShptLine."Service Item Line Description" := "Service Item Line Description";
                OnBeforeServShptLineInsert(ServShptLine, ServLine, ServShptHeader);
                ServShptLine.Insert();
                OnAfterServShptLineInsert(ServShptLine, ServLine, ServShptHeader, ServInvHeader, passedServLine);
                CheckCertificateOfSupplyStatus(ServShptHeader, ServShptLine);
            end;
            // end inserting Service Shipment Line

            if Invoice and Ship then begin
                WarrantyLedgerEntry.Reset();
                WarrantyLedgerEntry.SetCurrentKey("Service Order No.", "Posting Date", "Document No.");
                WarrantyLedgerEntry.SetRange("Service Order No.", ServShptLine."Order No.");
                WarrantyLedgerEntry.SetRange("Document No.", ServShptLine."Document No.");
                WarrantyLedgerEntry.SetRange(Type, ServShptLine.Type);
                WarrantyLedgerEntry.SetRange("No.", ServShptLine."No.");
                WarrantyLedgerEntry.SetRange(Open, true);
                WarrantyLedgerEntry.ModifyAll(Open, false);
            end;
        end;
    end;

    procedure PrepareInvoiceHeader(var Window: Dialog): Code[20]
    var
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with ServHeader do begin
            ServInvHeader.Init();
            ServInvHeader.TransferFields(ServHeader);
            OnPrepareInvoiceHeaderOnAfterServInvHeaderTransferFields(ServHeader, ServInvHeader);
            if "Document Type" = "Document Type"::Order then begin
                ServInvHeader."No." := "Posting No.";
                ServInvHeader."Pre-Assigned No. Series" := '';
                ServInvHeader."Order No. Series" := "No. Series";
                ServInvHeader."Order No." := "No.";
                Window.Update(1, StrSubstNo(Text007, "Document Type", "No.", ServInvHeader."No."));
            end else begin
                ServInvHeader."Pre-Assigned No. Series" := "No. Series";
                ServInvHeader."Pre-Assigned No." := "No.";
                OnPrepareInvoiceHeaderOnBeforeCheckPostingNo(ServHeader, ServInvHeader);
                if "Posting No." <> '' then begin
                    ServInvHeader."No." := "Posting No.";
                    Window.Update(1, StrSubstNo(Text007, "Document Type", "No.", ServInvHeader."No."));
                end;
            end;
            if ServMgtSetup."Copy Comments Order to Invoice" then
                RecordLinkManagement.CopyLinks(ServHeader, ServInvHeader);
            ServInvHeader."Source Code" := SrcCode;
            ServInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServInvHeader."User ID"));
            ServInvHeader."No. Printed" := 0;
            OnBeforeServInvHeaderInsert(ServInvHeader, ServHeader);
            ServInvHeader.Insert();
            OnAfterServInvHeaderInsert(ServInvHeader, ServHeader);

            Clear(ServLogMgt);
            case "Document Type" of
                "Document Type"::Invoice:
                    ServLogMgt.ServInvoicePost("No.", ServInvHeader."No.");
                "Document Type"::Order:
                    ServLogMgt.ServOrderInvoicePost("No.", ServInvHeader."No.");
            end;

            SetGenJnlLineDocNos(GenJnlLineDocType::Invoice, ServInvHeader."No.", "No.");

            if ("Document Type" = "Document Type"::Invoice) or
               ("Document Type" = "Document Type"::Order) and ServMgtSetup."Copy Comments Order to Invoice"
            then
                ServOrderMgt.CopyCommentLinesWithSubType(
                  "Service Comment Table Name"::"Service Header".AsInteger(),
                  "Service Comment Table Name"::"Service Invoice Header".AsInteger(),
                  "No.", ServInvHeader."No.", "Document Type".AsInteger());

            OnAfterPrepareInvoiceHeader(ServInvHeader, ServHeader, ServItemLine);
            exit(ServInvHeader."No.");
        end;
    end;

    local procedure PrepareInvoiceLine(var passedServLine: Record "Service Line")
    begin
        with passedServLine do begin
            ServInvLine.Init();
            ServInvLine.TransferFields(passedServLine);
            ServInvLine."Document No." := ServInvHeader."No.";
            ServInvLine.Quantity := "Qty. to Invoice";
            ServInvLine."Quantity (Base)" := "Qty. to Invoice (Base)";
            CalcFields("Service Item Line Description");
            ServInvLine."Service Item Line Description" := "Service Item Line Description";

            if passedServLine."Document Type" = passedServLine."Document Type"::Order then
                ServInvLine."Order No." := passedServLine."Document No.";

            OnBeforeServInvLineInsert(ServInvLine, passedServLine);
            ServInvLine.Insert();
            OnAfterServInvLineInsert(ServInvLine, passedServLine);
        end;
    end;

    procedure PrepareCrMemoHeader(var Window: Dialog): Code[20]
    var
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with ServHeader do begin
            ServCrMemoHeader.Init();
            ServCrMemoHeader.TransferFields(ServHeader);
            ServCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
            ServCrMemoHeader."Pre-Assigned No." := "No.";
            if "Posting No." <> '' then begin
                ServCrMemoHeader."No." := "Posting No.";
                Window.Update(1, StrSubstNo(Text008, "Document Type", "No.", ServCrMemoHeader."No."));
            end;
            RecordLinkManagement.CopyLinks(ServHeader, ServCrMemoHeader);
            ServCrMemoHeader."Source Code" := SrcCode;
            ServCrMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServCrMemoHeader."User ID"));
            ServCrMemoHeader."No. Printed" := 0;
            OnBeforeServCrMemoHeaderInsert(ServCrMemoHeader, ServHeader);
            ServCrMemoHeader.Insert();
            OnAfterServCrMemoHeaderInsert(ServCrMemoHeader, ServHeader);

            Clear(ServLogMgt);
            ServLogMgt.ServCrMemoPost("No.", ServCrMemoHeader."No.");

            SetGenJnlLineDocNos(GenJnlLineDocType::"Credit Memo", ServCrMemoHeader."No.", "No.");

            ServOrderMgt.CopyCommentLines(
              "Service Comment Table Name"::"Service Header".AsInteger(),
              "Service Comment Table Name"::"Service Cr.Memo Header".AsInteger(),
              "No.", ServCrMemoHeader."No.");

            OnAfterPrepareCrMemoHeader(ServCrMemoHeader, ServHeader);
            exit(ServCrMemoHeader."No.");
        end;
    end;

    local procedure PrepareCrMemoLine(var passedServLine: Record "Service Line")
    begin
        with passedServLine do begin
            // TempSrvLine is initialized (in Sales module) in RoundAmount
            // procedure, and likely does not differ from initial ServLine.

            ServCrMemoLine.Init();
            ServCrMemoLine.TransferFields(passedServLine);
            ServCrMemoLine."Document No." := ServCrMemoHeader."No.";
            ServCrMemoLine.Quantity := "Qty. to Invoice";
            ServCrMemoLine."Quantity (Base)" := "Qty. to Invoice (Base)";
            CalcFields("Service Item Line Description");
            ServCrMemoLine."Service Item Line Description" := "Service Item Line Description";
            OnBeforeServCrMemoLineInsert(ServCrMemoLine, passedServLine);
            ServCrMemoLine.Insert();
            OnAfterServCrMemoLineInsert(ServCrMemoLine, passedServLine);
        end;
    end;

    procedure Finalize(var PassedServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeFinalize(PassedServHeader, CloseCondition);

        // finalize codeunits calls
        ServPostingJnlsMgt.Finalize();

        // finalize posted documents
        FinalizeShipmentDocument();
        FinalizeInvoiceDocument(PassedServHeader);
        FinalizeCrMemoDocument(PassedServHeader);
        FinalizeWarrantyLedgerEntries(PassedServHeader, CloseCondition);

        IsHandled := false;
        OnFinalizeOnBeforeFinalizeHeaderAndLines(PassedServHeader, IsHandled, CloseCondition);
        if not IsHandled then
            if ((ServHeader."Document Type" = ServHeader."Document Type"::Order) and CloseCondition) or
               (ServHeader."Document Type" <> ServHeader."Document Type"::Order)
            then begin
                // Service Lines, Service Item Lines, Service Header
                FinalizeDeleteLines();
                FinalizeDeleteServOrdAllocat();
                FinalizeDeleteItemLines();
                FinalizeDeleteComments(PassedServHeader."Document Type");
                OnFinalizeOnBeforeFinalizeDeleteHeader(PassedServHeader);
                FinalizeDeleteHeader(PassedServHeader);
            end else begin
                // Service Lines, Service Item Lines, Service Header
                FinalizeLines();
                FinalizeItemLines();
                OnFinalizeOnBeforeFinalizeHeader(PassedServHeader);
                FinalizeHeader(PassedServHeader);
            end;

        OnAfterFinalize(PassedServHeader, CloseCondition);
    end;

    local procedure FinalizeHeader(var PassedServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeHeader(PassedServHeader, IsHandled);
        if not IsHandled then begin
            PassedServHeader.Copy(ServHeader);
            ServHeader.DeleteAll();
        end;
        OnAfterFinalizeHeader(PassedServHeader);
    end;

    local procedure FinalizeLines()
    begin
        // copy Service Lines to persistent from temporary
        PServLine.Reset();
        ServLine.Reset();
        ServLine.SetFilter(Quantity, '<>0');
        OnFinalizeLinesOnAfterSetFilters(ServLine);
        if ServLine.Find('-') then
            repeat
                with ServLine do
                    if PServLine.Get("Document Type", "Document No.", "Line No.") then begin
                        PServLine.Copy(ServLine);
                        PServLine.Modify();
                    end else
                        // invoice discount lines only
                        if (Type = Type::"G/L Account") and "System-Created Entry" then begin
                            PServLine.Init();
                            PServLine.Copy(ServLine);
                            PServLine.Insert();
                        end;
            until ServLine.Next() = 0;
        ServLine.Reset();
        ServLine.DeleteAll(); // just temp records
    end;

    local procedure FinalizeItemLines()
    begin
        // copy Service Item Lines to persistent from temporary
        ServItemLine.Reset();
        OnFinalizeItemLinesOnAfterSetFilters(ServItemLine);
        if ServItemLine.Find('-') then
            repeat
                with ServItemLine do begin
                    PServItemLine.Get("Document Type", "Document No.", "Line No.");
                    PServItemLine.Copy(ServItemLine);
                    PServItemLine.Modify();
                end;
            until ServItemLine.Next() = 0;
        ServItemLine.DeleteAll(); // just temp records
    end;

    local procedure FinalizeDeleteHeader(var PassedServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeDeleteHeader(PassedServHeader, ServHeader, IsHandled);
        if IsHandled then
            exit;

        with PassedServHeader do begin
            Delete();
            ServITRMgt.DeleteInvoiceSpecFromHeader(ServHeader);
            OnFinalizeDeleteHeaderOnAfterDeleteInvoiceSpecFromHeader(ServHeader);
        end;

        ServHeader.DeleteAll();
    end;

    local procedure FinalizeDeleteLines()
    begin
        // delete Service Lines persistent and temporary
        PServLine.Reset();
        PServLine.SetRange("Document Type", ServHeader."Document Type");
        PServLine.SetRange("Document No.", ServHeader."No.");
        OnFinalizeDeleteLinesOnAfterSetPServLineFilters(PServLine);
        PServLine.DeleteAll();

        ServLine.Reset();
        ServLine.DeleteAll();
    end;

    local procedure FinalizeDeleteItemLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeDeleteItemLines(PServItemLine, ServHeader, ServItemLine, IsHandled);
        if IsHandled then
            exit;

        // delete Service Item Lines persistent and temporary
        PServItemLine.Reset();
        PServItemLine.SetRange("Document Type", ServHeader."Document Type");
        PServItemLine.SetRange("Document No.", ServHeader."No.");
        OnFinalizeDeleteLinesOnAfterSetPServItemLineFilters(PServItemLine);
        PServItemLine.DeleteAll();

        ServItemLine.Reset();
        ServItemLine.DeleteAll();
    end;

    local procedure FinalizeShipmentDocument()
    var
        ServiceShipmentHeader2: Record "Service Shipment Header";
        ServiceShipmentItemLine2: Record "Service Shipment Item Line";
        ServiceShipmentLine2: Record "Service Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeShipmentDocument(ServShptHeader, ServHeader, IsHandled);
        if not IsHandled then begin
            ServShptHeader.Reset();
            if ServShptHeader.FindFirst() then begin
                ServiceShipmentHeader2.Init();
                ServiceShipmentHeader2.Copy(ServShptHeader);
                ServiceShipmentHeader2.Insert();
            end;
            ServShptHeader.DeleteAll();

            ServShptItemLine.Reset();
            if ServShptItemLine.Find('-') then
                repeat
                    ServiceShipmentItemLine2.Init();
                    ServiceShipmentItemLine2.Copy(ServShptItemLine);
                    ServiceShipmentItemLine2.Insert();
                until ServShptItemLine.Next() = 0;
            ServShptItemLine.DeleteAll();

            ServShptLine.Reset();
            if ServShptLine.Find('-') then
                repeat
                    ServiceShipmentLine2.Init();
                    ServiceShipmentLine2.Copy(ServShptLine);
                    ServiceShipmentLine2.Insert();
                    OnFinalizeShipmentDocumentOnAfterInserServiceShipmentLine(ServiceShipmentLine2);
                until ServShptLine.Next() = 0;
            ServShptLine.DeleteAll();
        end;

        OnAfterFinalizeShipmentDocument(ServShptHeader, ServHeader, ServiceShipmentHeader2);
    end;

    local procedure FinalizeInvoiceDocument(var PassedServHeader: Record "Service Header")
    var
        ServiceInvoiceHeader2: Record "Service Invoice Header";
        ServiceInvoiceLine2: Record "Service Invoice Line";
        IsHandled: Boolean;
            begin
        IsHandled := false;
        OnBeforeFinalizeInvoiceDocument(ServInvHeader, ServHeader, IsHandled);
        if not IsHandled then begin
            ServInvHeader.Reset();
            if ServInvHeader.FindFirst() then begin
                ServiceInvoiceHeader2.Init();
                ServiceInvoiceHeader2.Copy(ServInvHeader);
                ServiceInvoiceHeader2.SetSIIFirstSummaryDocNo(PassedServHeader.GetSIIFirstSummaryDocNo());
                ServiceInvoiceHeader2.SetSIILastSummaryDocNo(PassedServHeader.GetSIILastSummaryDocNo());
                ServiceInvoiceHeader2.Insert();
            end;
            ServInvHeader.DeleteAll();

            ServInvLine.Reset();
            if ServInvLine.Find('-') then
                repeat
                    ServiceInvoiceLine2.Init();
                    ServiceInvoiceLine2.Copy(ServInvLine);
                    ServiceInvoiceLine2.Insert();
                until ServInvLine.Next() = 0;
            ServInvLine.DeleteAll();
            PostUpdateOrderNo(ServiceInvoiceHeader2);
        end;

        OnAfterFinalizeInvoiceDocument(ServInvHeader, ServHeader, ServiceInvoiceHeader2);
    end;

    local procedure PostUpdateOrderNo(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        if ServiceInvoiceHeader."No." = '' then
            exit;

        // Do not change 'Order No.' if already set 
        if ServiceInvoiceHeader."Order No." <> '' then
            exit;

        // Get a line where 'Order No.' is set
        ServiceInvoiceLine.SetLoadFields("Order No.");

        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" "); // Ignore comment lines
        ServiceInvoiceLine.SetFilter("Order No.", '<>%1', '');
        if not ServiceInvoiceLine.FindFirst() then
            exit;

        // If all the lines have the same 'Order No.' then set 'Order No.' field on the header
        ServiceInvoiceLine.SetFilter("Order No.", '<>%1', ServiceInvoiceLine."Order No.");
        if ServiceInvoiceLine.IsEmpty() then begin
            ServiceInvoiceHeader.Validate("Order No.", ServiceInvoiceLine."Order No.");
            ServiceInvoiceHeader.Modify(true);
        end;
    end;


    local procedure FinalizeCrMemoDocument(var PassedServHeader: Record "Service Header")
    var
        PServCrMemoHeader: Record "Service Cr.Memo Header";
        PServCrMemoLine: Record "Service Cr.Memo Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeCrMemoDocument(ServCrMemoHeader, ServHeader, IsHandled);
        if not IsHandled then begin
            ServCrMemoHeader.Reset();
            if ServCrMemoHeader.FindFirst() then begin
                PServCrMemoHeader.Init();
                PServCrMemoHeader.Copy(ServCrMemoHeader);
                PServCrMemoHeader.SetSIIFirstSummaryDocNo(PassedServHeader.GetSIIFirstSummaryDocNo());
                PServCrMemoHeader.SetSIILastSummaryDocNo(PassedServHeader.GetSIILastSummaryDocNo());
                PServCrMemoHeader.Insert();
            end;
            ServCrMemoHeader.DeleteAll();

            ServCrMemoLine.Reset();
            if ServCrMemoLine.Find('-') then
                repeat
                    PServCrMemoLine.Init();
                    PServCrMemoLine.Copy(ServCrMemoLine);
                    PServCrMemoLine.Insert();
                until ServCrMemoLine.Next() = 0;
            ServCrMemoLine.DeleteAll();
        end;

        OnAfterFinalizeCrMemoDocument(ServCrMemoHeader, ServHeader, PServCrMemoHeader);
    end;

    local procedure GetAndCheckCustomer()
    var
        Cust: Record Customer;
        IsHandled: Boolean;
        Text1100000: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        Text1100001: Label 'The posting process has been cancelled by the user.';
        Text1100002: Label 'Corrective Invoice';
    begin
        IsHandled := false;
        OnBeforeGetAndCheckCustomer(ServHeader, IsHandled);
        if IsHandled then
            exit;

        with ServHeader do begin
            Cust.Get("Customer No.");

            if Ship or ServMgtSetup."Shipment on Invoice" and
               ("Document Type" = "Document Type"::Invoice)
            then begin
                ServLine.Reset();
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "No.");
                ServLine.SetFilter("Qty. to Ship", '<>0');
                ServLine.SetRange("Shipment No.", '');
                if not ServLine.IsEmpty() then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", true, true);
            end else
                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, true);

            if "Document Type" = "Document Type"::"Credit Memo" then begin
                SalesSetup.Get();
                if SalesSetup."Correct. Doc. No. Mandatory" then
                    TestField("Corrected Invoice No.")
                else begin
                    if "Corrected Invoice No." = '' then
                        if not
                           Confirm(
                             Text1100000, false)
                        then
                            Error(Text1100001);
                end;
                if ("Corrected Invoice No." <> '') and ("Posting Description" = '') then
                    "Posting Description" := Format(Text1100002) + ' ' + "No."
            end;

            if "Bill-to Customer No." <> "Customer No." then begin
                Cust.Get("Bill-to Customer No.");
                if Ship or ServMgtSetup."Shipment on Invoice" and
                   ("Document Type" = "Document Type"::Invoice)
                then begin
                    ServLine.Reset();
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter("Qty. to Ship", '<>0');
                    if not ServLine.IsEmpty() then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", true, true);
                end else
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, true);
            end;

            if Cust."Application Method" = Cust."Application Method"::"Apply to Oldest" then
                TestSalesEfects(ServHeader, Cust);

            ServLine.Reset();
        end;
    end;

    local procedure GetServLineItem(ServLine: Record "Service Line"; var Item: Record Item)
    begin
        with ServLine do begin
            TestField(Type, Type::Item);
            TestField("No.");
            if "No." <> Item."No." then
                Item.Get("No.");
        end;
    end;

    local procedure CheckDimensions()
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2."Line No." := 0;
        CheckDimComb(ServiceLine2);
        CheckDimValuePosting(ServiceLine2);

        ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
        OnCheckDimensionsAnAfterSetServLineFilters(ServLine);
        if ServLine.Find('-') then
            repeat
                if (Invoice and (ServLine."Qty. to Invoice" <> 0)) or
                   (Ship and (ServLine."Qty. to Ship" <> 0))
                then begin
                    CheckDimComb(ServLine);
                    CheckDimValuePosting(ServLine);
                end;
            until ServLine.Next() = 0;
        ServLine.Reset();
    end;

    local procedure CollectValueEntryRelation()
    begin
        with ServHeader do begin
            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                ServPostingJnlsMgt.CollectValueEntryRelation(TempValueEntryRelation, ServInvLine.RowID1())
            else
                ServPostingJnlsMgt.CollectValueEntryRelation(TempValueEntryRelation, ServCrMemoLine.RowID1());
        end;
    end;

    procedure InsertValueEntryRelation()
    begin
        ServITRMgt.InsertValueEntryRelation(TempValueEntryRelation);
    end;

    local procedure CheckIfServDuplicateLine(var CurrentServLine: Record "Service Line")
    var
        ServLine2: Record "Service Line";
        ServLedgEntry: Record "Service Ledger Entry";
    begin
        if CurrentServLine."Appl.-to Service Entry" = 0 then
            exit;
        ServLine2.Reset();
        ServLine2.SetRange("Document Type", CurrentServLine."Document Type");
        ServLine2.SetRange("Document No.", CurrentServLine."Document No.");
        ServLine2.SetFilter("Line No.", '<>%1', CurrentServLine."Line No.");
        ServLine2.SetRange("Appl.-to Service Entry", CurrentServLine."Appl.-to Service Entry");
        if ServLine2.FindFirst() then
            Error(
              Text035, ServLine2.FieldCaption("Line No."),
              ServLine2."Line No.", ServLedgEntry.TableCaption(), CurrentServLine."Line No.");

        if CurrentServLine."Document Type" = CurrentServLine."Document Type"::Invoice then
            if ServLedgEntry.Get(CurrentServLine."Appl.-to Service Entry") and
               (ServLedgEntry.Open = false) and
               ((ServLedgEntry."Document Type" = ServLedgEntry."Document Type"::Invoice) or
                (ServLedgEntry."Document Type" = ServLedgEntry."Document Type"::"Credit Memo"))
            then
                Error(
                  Text039, ServLine2.FieldCaption("Line No."), CurrentServLine."Line No.",
                  Format(ServLine2."Document Type"), ServHeader."No.",
                  ServLedgEntry.TableCaption());

        if (CurrentServLine."Contract No." <> '') and
           (CurrentServLine."Shipment No." = '') and
           (CurrentServLine."Document Type" <> CurrentServLine."Document Type"::Order)
        then begin
            SetServiceLedgerEntryFilters(ServLedgEntry, CurrentServLine."Contract No.");
            if not ServLedgEntry.IsEmpty() and (ServHeader."Contract No." <> '') then
                Error(Text041, ServLedgEntry.FieldCaption(Open), CurrentServLine."Contract No.");
        end;
    end;

    local procedure FindFirstServLedgEntry(var TempServiceLine: Record "Service Line" temporary): Integer
    var
        ApplServLedgEntryNo: Integer;
    begin
        if not TempServiceLine.Find('-') then
            exit(0);
        ApplServLedgEntryNo := 0;
        with TempServiceLine do
            repeat
                if "Appl.-to Service Entry" <> 0 then
                    if ApplServLedgEntryNo = 0 then
                        ApplServLedgEntryNo := "Appl.-to Service Entry"
                    else
                        if "Appl.-to Service Entry" < ApplServLedgEntryNo then
                            ApplServLedgEntryNo := "Appl.-to Service Entry";
            until Next() = 0;
        exit(ApplServLedgEntryNo);
    end;

    local procedure CheckDimComb(ServiceLine: Record "Service Line")
    begin
        if ServiceLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(ServHeader."Dimension Set ID") then
                Error(Text028,
                  ServHeader."Document Type", ServHeader."No.", DimMgt.GetDimCombErr());

        if ServiceLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(ServiceLine."Dimension Set ID") then
                Error(Text029,
                  ServHeader."Document Type", ServHeader."No.", ServiceLine."Line No.", DimMgt.GetDimCombErr());

        OnAfterCheckDimComb(ServHeader, ServiceLine);
    end;

    local procedure CheckDimValuePosting(var ServiceLine2: Record "Service Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        OnBeforeCheckDimValuePosting(ServiceLine2);

        if ServiceLine2."Line No." = 0 then begin
            TableIDArr[1] := Database::Customer;
            NumberArr[1] := ServHeader."Bill-to Customer No.";
            TableIDArr[2] := Database::"Salesperson/Purchaser";
            NumberArr[2] := ServHeader."Salesperson Code";
            TableIDArr[3] := Database::"Responsibility Center";
            NumberArr[3] := ServHeader."Responsibility Center";
            TableIDArr[4] := Database::"Service Order Type";
            NumberArr[4] := ServHeader."Service Order Type";
            OnCheckDimValuePostingOnAssignDimensionsToNewLine(TableIDArr, NumberArr, ServHeader);
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ServHeader."Dimension Set ID") then
                Error(
                  Text030,
                  ServHeader."Document Type", ServHeader."No.", DimMgt.GetDimValuePostingErr());
        end else begin
            TableIDArr[1] := DimMgt.TypeToTableID5(ServiceLine2.Type);
            NumberArr[1] := ServiceLine2."No.";
            TableIDArr[2] := Database::Job;
            NumberArr[2] := ServiceLine2."Job No.";

            TableIDArr[3] := Database::"Responsibility Center";
            NumberArr[3] := ServiceLine2."Responsibility Center";

            if ServiceLine2."Service Item Line No." <> 0 then begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", ServiceLine2."Document Type");
                ServItemLine.SetRange("Document No.", ServiceLine2."Document No.");
                ServItemLine.SetRange("Line No.", ServiceLine2."Service Item Line No.");
                if ServItemLine.Find('-') then begin
                    TableIDArr[4] := Database::"Service Item";
                    NumberArr[4] := ServItemLine."Service Item No.";
                    TableIDArr[5] := Database::"Service Item Group";
                    NumberArr[5] := ServItemLine."Service Item Group Code";
                end;
                ServItemLine.Reset();
            end;

            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ServiceLine2."Dimension Set ID") then
                Error(Text031,
                  ServHeader."Document Type", ServHeader."No.", ServiceLine2."Line No.", DimMgt.GetDimValuePostingErr());
        end;
    end;

    procedure CheckAndSetPostingConstants(var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
        with ServHeader do begin
            if PassedConsume then begin
                ServLine.Reset();
                ServLine.SetFilter(Quantity, '<>0');
                if "Document Type" = "Document Type"::Order then
                    ServLine.SetFilter("Qty. to Consume", '<>0');
                OnCheckAndSetPostingContantsOnAfterSetFilterForConsume(ServLine);
                PassedConsume := ServLine.Find('-');
                if PassedConsume and ("Document Type" = "Document Type"::Order) and not PassedShip then begin
                    PassedConsume := false;
                    repeat
                        PassedConsume :=
                          (ServLine."Quantity Shipped" - ServLine."Quantity Invoiced" - ServLine."Quantity Consumed" <> 0);
                    until PassedConsume or (ServLine.Next() = 0);
                end;
            end;
            if PassedInvoice then begin
                ServLine.Reset();
                ServLine.SetFilter(Quantity, '<>0');
                if "Document Type" = "Document Type"::Order then
                    ServLine.SetFilter("Qty. to Invoice", '<>0');
                OnCheckAndSetPostingContantsOnAfterSetFilterForInvoice(ServLine);
                PassedInvoice := ServLine.Find('-');
                if PassedInvoice and ("Document Type" = "Document Type"::Order) and not PassedShip then begin
                    PassedInvoice := false;
                    repeat
                        PassedInvoice :=
                          (ServLine."Quantity Shipped" - ServLine."Quantity Invoiced" - ServLine."Quantity Consumed" <> 0);
                    until PassedInvoice or (ServLine.Next() = 0);
                end;
            end;
            if PassedShip then begin
                ServLine.Reset();
                ServLine.SetFilter(Quantity, '<>0');
                if "Document Type" = "Document Type"::Order then
                    ServLine.SetFilter("Qty. to Ship", '<>0');
                ServLine.SetRange("Shipment No.", '');
                OnCheckAndSetPostingContantsOnAfterSetFilterForShip(ServLine);
                PassedShip := ServLine.Find('-');
                if PassedShip then
                    ServITRMgt.CheckTrackingSpecification(ServHeader, ServLine);
            end;
        end;

        SetPostingOptions(PassedShip, PassedConsume, PassedInvoice);
        ServLine.Reset();
    end;

    procedure CheckAndBlankQtys(ServDocType: Integer)
    begin
        ServLine.Reset();
        OnCheckAndBlankQtysOnAfterServLineSetFilters(ServLine);
        if ServLine.Find('-') then
            repeat
                with ServLine do begin
                    OnCheckAndBlankQtysOnBeforeCheckServLine(ServLine);

                    // Service Charge line should not be tested.
                    if (Type <> Type::" ") and not "System-Created Entry" then begin
                        if ServDocType = Database::"Service Contract Header" then
                            TestField("Contract No.");
                        if ServDocType = Database::"Service Header" then
                            TestField("Shipment No.");
                    end;

                    if (Type = Type::Item) and ("No." <> '') and ("Qty. Shipped (Base)" = 0) and ("Qty. Consumed (Base)" = 0) then
                        TestField("Unit of Measure Code");

                    if "Qty. per Unit of Measure" = 0 then
                        "Qty. per Unit of Measure" := 1;
                    case "Document Type" of
                        "Document Type"::Invoice:
                            begin
                                if "Shipment No." = '' then
                                    TestField("Qty. to Ship", Quantity);
                                TestField("Qty. to Invoice", Quantity);
                            end;
                        "Document Type"::"Credit Memo":
                            begin
                                TestField("Qty. to Ship", 0);
                                TestField("Qty. to Invoice", Quantity);
                            end;
                    end;

                    if not (Ship or ServAmountsMgt.RoundingLineInserted()) then begin
                        "Qty. to Ship" := 0;
                        "Qty. to Ship (Base)" := 0;
                    end;

                    if ("Document Type" = "Document Type"::Invoice) and ("Shipment No." <> '') then begin
                        "Quantity Shipped" := Quantity;
                        "Qty. Shipped (Base)" := "Quantity (Base)";
                        "Qty. to Ship" := 0;
                        "Qty. to Ship (Base)" := 0;
                    end;

                    if Invoice then begin
                        if Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice()) then begin
                            "Qty. to Consume" := 0;
                            "Qty. to Consume (Base)" := 0;
                            InitQtyToInvoice();
                        end
                    end else begin
                        "Qty. to Invoice" := 0;
                        "Qty. to Invoice (Base)" := 0;
                    end;

                    if Consume then begin
                        if Abs("Qty. to Consume") > Abs(MaxQtyToConsume()) then begin
                            "Qty. to Consume" := MaxQtyToConsume();
                            "Qty. to Consume (Base)" := MaxQtyToConsumeBase();
                        end;
                    end else begin
                        "Qty. to Consume" := 0;
                        "Qty. to Consume (Base)" := 0;
                    end;

                    Modify();
                end;

            until ServLine.Next() = 0;
    end;

    local procedure CheckCloseCondition(Qty: Decimal; QtytoInv: Decimal; QtyToCsm: Decimal; QtyInvd: Decimal; QtyCsmd: Decimal): Boolean
    var
        ServiceItemLineTemp: Record "Service Item Line";
        ServiceLineTemp: Record "Service Line";
        QtyClosedCondition: Boolean;
        ServiceItemClosedCondition: Boolean;
    begin
        QtyClosedCondition := (Qty = QtyToCsm + QtytoInv + QtyCsmd + QtyInvd);
        ServiceItemClosedCondition := true;
        ServiceItemLineTemp.SetCurrentKey("Document Type", "Document No.", "Line No.");
        ServiceItemLineTemp.SetRange("Document Type", ServItemLine."Document Type");
        ServiceItemLineTemp.SetRange("Document No.", ServItemLine."Document No.");
        ServiceItemLineTemp.SetFilter("Service Item No.", '<>%1', '');
        if ServiceItemLineTemp.FindSet() then
            repeat
                ServiceLineTemp.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                ServiceLineTemp.SetRange("Document Type", ServiceItemLineTemp."Document Type");
                ServiceLineTemp.SetRange("Document No.", ServiceItemLineTemp."Document No.");
                ServiceLineTemp.SetRange("Service Item No.", ServiceItemLineTemp."Service Item No.");
                if not ServiceLineTemp.FindFirst() then
                    ServiceItemClosedCondition := false;
                OnCheckCloseConditionOnAfterServiceLineTempLoop(ServiceItemLineTemp, ServiceLineTemp, Qty, QtytoInv, QtyToCsm, QtyInvd, QtyCsmd, ServiceItemClosedCondition);
            until (ServiceItemLineTemp.Next() = 0) or (not ServiceItemClosedCondition);
        exit(QtyClosedCondition and ServiceItemClosedCondition);
    end;

    local procedure CheckSysCreatedEntry()
    begin
        with ServLine do
            if ServHeader."Document Type" = ServHeader."Document Type"::Invoice then begin
                Reset();
                SetRange("System-Created Entry", false);
                SetFilter(Quantity, '<>0');
                if not Find('-') then
                    Error(ErrorInfo.Create(DocumentErrorsMgt.GetNothingToPostErrorMsg(), true, ServLine));
                Reset();
            end;
    end;

    local procedure CheckShippingAdvice()
    begin
        if ServHeader."Shipping Advice" = ServHeader."Shipping Advice"::Complete then
            with ServLine do
                if FindSet() then
                    repeat
                        if IsShipment() then begin
                            if not GetShippingAdvice() then
                                Error(ErrorInfo.Create(Text023, true, ServLine));
                            exit;
                        end;
                    until Next() = 0;
    end;

    procedure CheckAdjustedLines()
    var
        ServPriceMgt: Codeunit "Service Price Management";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        with ServLine do begin
            if ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.") then
                if ServItemLine."Service Price Group Code" <> '' then
                    if ServPriceMgt.IsLineToAdjustFirstInvoiced(ServLine) then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text015, TableCaption(), FieldCaption("Service Price Group Code")), true)
                        then
                            Error('');
            Reset();
        end;
    end;

    procedure IsCloseConditionMet(): Boolean
    begin
        exit(CloseCondition);
    end;

    procedure SetNoSeries(var PServHeader: Record "Service Header") Result: Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNoSeries(ServHeader, Invoice, Consume, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ModifyHeader := false;
        with ServHeader do begin
            if Ship and ("Shipping No." = '') then
                if ("Document Type" = "Document Type"::Order) or
                   (("Document Type" = "Document Type"::Invoice) and ServMgtSetup."Shipment on Invoice")
                then begin
                    TestField("Shipping No. Series");
                    "Shipping No." := NoSeriesMgt.GetNextNo("Shipping No. Series", "Posting Date", true);
                    ModifyHeader := true;
                end;

            OnSetNoSeriesOnBeforeSetPostingNo(ServHeader, Invoice, ModifyHeader);

            if Invoice and ("Posting No." = '') then begin
                if ("No. Series" <> '') or ("Document Type" = "Document Type"::Order)
                then
                    TestField("Posting No. Series");
                if ("No. Series" <> "Posting No. Series") or ("Document Type" = "Document Type"::Order)
                then begin
                    "Posting No." := NoSeriesMgt.GetNextNo("Posting No. Series", "Posting Date", true);
                    ModifyHeader := true;
                end;
            end;

            OnBeforeModifyServiceDocNoSeries(ServHeader, PServHeader, ModifyHeader);

            if ModifyHeader then begin
                PServHeader."Shipping No." := "Shipping No.";
                PServHeader."Posting No." := "Posting No.";
            end;
        end;
        exit(ModifyHeader);
    end;

    procedure SetLastNos(var PServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLastNos(PServHeader, ServHeader, Ship, Invoice, ServLinesPassed, CloseCondition, IsHandled);
        if IsHandled then
            exit;

        if Ship then begin
            PServHeader."Last Shipping No." := ServHeader."Last Shipping No.";
            PServHeader."Shipping No." := '';
        end;

        if Invoice then begin
            PServHeader."Last Posting No." := ServHeader."Last Posting No.";
            PServHeader."Posting No." := '';
        end;
        if ServLinesPassed and CloseCondition then
            PServHeader.Status := ServHeader.Status::Finished;
    end;

    procedure SetPostingOptions(passedShip: Boolean; passedConsume: Boolean; passedInvoice: Boolean)
    begin
        Ship := passedShip;
        Consume := passedConsume;
        Invoice := passedInvoice;
        ServPostingJnlsMgt.SetPostingOptions(passedConsume, passedInvoice);
    end;

    local procedure SetGenJnlLineDocNos(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Code[35])
    var
        DocTypeInt: Integer;
    begin
        DocTypeInt := DocType.AsInteger();
        OnBeforeSetGenJnlLineDocNumbers(ServHeader, DocTypeInt, DocNo, ExtDocNo);
        DocType := Enum::"Gen. Journal Document Type".FromInteger(DocTypeInt);

        GenJnlLineDocType := DocType;
        GenJnlLineDocNo := DocNo;
        GenJnlLineExtDocNo := ExtDocNo;
        ServPostingJnlsMgt.SetGenJnlLineDocNos(GenJnlLineDocNo, GenJnlLineExtDocNo);
    end;


    local procedure UpdateRcptLinesOnInv()
    begin
    end;

    local procedure UpdateShptLinesOnInv(var ServiceLine: Record "Service Line"; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; var RemQtyToBeConsumed: Decimal; var RemQtyToBeConsumedBase: Decimal)
    var
        ServiceShptLine: Record "Service Shipment Line";
        ItemEntryRelation: Record "Item Entry Relation";
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
        QtyToBeConsumed: Decimal;
        QtyToBeConsumedBase: Decimal;
        EndLoop: Boolean;
    begin
        EndLoop := false;
        if ((Abs(RemQtyToBeInvoiced) > Abs(ServiceLine."Qty. to Ship")) and Invoice) or
           ((Abs(RemQtyToBeConsumed) > Abs(ServiceLine."Qty. to Ship")) and Consume)
        then begin
            ServiceShptLine.Reset();
            case ServHeader."Document Type" of
                ServHeader."Document Type"::Order:
                    begin
                        ServiceShptLine.SetCurrentKey("Order No.", "Order Line No.");
                        ServiceShptLine.SetRange("Order No.", ServiceLine."Document No.");
                        ServiceShptLine.SetRange("Order Line No.", ServiceLine."Line No.");
                    end;
                ServHeader."Document Type"::Invoice:
                    begin
                        ServiceShptLine.SetRange("Document No.", ServiceLine."Shipment No.");
                        ServiceShptLine.SetRange("Line No.", ServiceLine."Shipment Line No.");
                    end;
            end;

            ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
            if ServiceShptLine.Find('-') then begin
                ServPostingJnlsMgt.SetItemJnlRollRndg(true);
                repeat
                    if TrackingSpecificationExists then begin
                        ItemEntryRelation.Get(TempInvoicingSpecification."Item Ledger Entry No.");
                        ServiceShptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                    end else
                        ItemEntryRelation."Item Entry No." := ServiceShptLine."Item Shpt. Entry No.";
                    ServiceShptLine.TestField("Customer No.", ServiceLine."Customer No.");
                    ServiceShptLine.TestField(Type, ServiceLine.Type);
                    ServiceShptLine.TestField("No.", ServiceLine."No.");
                    ServiceShptLine.TestField("Gen. Bus. Posting Group", ServiceLine."Gen. Bus. Posting Group");
                    ServiceShptLine.TestField("Gen. Prod. Posting Group", ServiceLine."Gen. Prod. Posting Group");

                    ServiceShptLine.TestField("Unit of Measure Code", ServiceLine."Unit of Measure Code");
                    ServiceShptLine.TestField("Variant Code", ServiceLine."Variant Code");
                    if -ServiceLine."Qty. to Invoice" * ServiceShptLine.Quantity < 0 then
                        ServiceLine.FieldError("Qty. to Invoice", Text011);

                    if TrackingSpecificationExists then begin
                        if Invoice then begin
                            QtyToBeInvoiced := TempInvoicingSpecification."Qty. to Invoice";
                            QtyToBeInvoicedBase := TempInvoicingSpecification."Qty. to Invoice (Base)";
                        end;
                        if Consume then begin
                            QtyToBeConsumed := TempInvoicingSpecification."Qty. to Invoice";
                            QtyToBeConsumedBase := TempInvoicingSpecification."Qty. to Invoice (Base)";
                        end;
                    end else begin
                        if Invoice then begin
                            QtyToBeInvoiced := RemQtyToBeInvoiced - ServiceLine."Qty. to Ship" - ServiceLine."Qty. to Consume";
                            QtyToBeInvoicedBase :=
                              RemQtyToBeInvoicedBase - ServiceLine."Qty. to Ship (Base)" - ServiceLine."Qty. to Consume (Base)";
                        end;
                        if Consume then begin
                            QtyToBeConsumed := RemQtyToBeConsumed - ServiceLine."Qty. to Ship" - ServiceLine."Qty. to Invoice";
                            QtyToBeConsumedBase :=
                              RemQtyToBeConsumedBase - ServiceLine."Qty. to Ship (Base)" - ServiceLine."Qty. to Invoice (Base)";
                            OnUpdateShptLinesOnInvOnAfterCalcQtyToBeConsumed(ServiceLine, QtyToBeConsumed, QtyToBeConsumedBase, RemQtyToBeConsumed, RemQtyToBeConsumedBase);
                        end;
                    end;

                    if Invoice then begin
                        if Abs(QtyToBeInvoiced) >
                           Abs(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced" - ServiceShptLine."Quantity Consumed")
                        then begin
                            QtyToBeInvoiced :=
                              -(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced" - ServiceShptLine."Quantity Consumed");
                            QtyToBeInvoicedBase :=
                              -(ServiceShptLine."Quantity (Base)" - ServiceShptLine."Qty. Invoiced (Base)" -
                                ServiceShptLine."Qty. Consumed (Base)");
                        end;

                        if TrackingSpecificationExists then
                            ServITRMgt.AdjustQuantityRounding(RemQtyToBeInvoiced, QtyToBeInvoiced, RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                        RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                        RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;

                        ServiceShptLine."Quantity Invoiced" := ServiceShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                        ServiceShptLine."Qty. Invoiced (Base)" := ServiceShptLine."Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
                    end;

                    if Consume then begin
                        if Abs(QtyToBeConsumed) >
                           Abs(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced" - ServiceShptLine."Quantity Consumed")
                        then begin
                            QtyToBeConsumed :=
                              -(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced" - ServiceShptLine."Quantity Consumed");
                            QtyToBeConsumedBase :=
                              -(ServiceShptLine."Quantity (Base)" - ServiceShptLine."Qty. Invoiced (Base)" -
                                ServiceShptLine."Qty. Consumed (Base)");
                        end;

                        if TrackingSpecificationExists then
                            ServITRMgt.AdjustQuantityRounding(RemQtyToBeConsumed, QtyToBeConsumed, RemQtyToBeConsumedBase, QtyToBeConsumedBase);

                        RemQtyToBeConsumed := RemQtyToBeConsumed - QtyToBeConsumed;
                        RemQtyToBeConsumedBase := RemQtyToBeConsumedBase - QtyToBeConsumedBase;

                        ServiceShptLine."Quantity Consumed" :=
                          ServiceShptLine."Quantity Consumed" - QtyToBeConsumed;
                        ServiceShptLine."Qty. Consumed (Base)" :=
                          ServiceShptLine."Qty. Consumed (Base)" - QtyToBeConsumedBase;
                    end;

                    ServiceShptLine."Qty. Shipped Not Invoiced" :=
                      ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced" - ServiceShptLine."Quantity Consumed";
                    ServiceShptLine."Qty. Shipped Not Invd. (Base)" :=
                      ServiceShptLine."Quantity (Base)" - ServiceShptLine."Qty. Invoiced (Base)" - ServiceShptLine."Qty. Consumed (Base)";
                    ServiceShptLine.Modify();

                    OnUpdateShptLinesOnInvOnAfterServiceShptLineModify(
                      ServLine, ServInvHeader, ServShptHeader, ServiceShptLine, TempInvoicingSpecification, TrackingSpecificationExists,
                      QtyToBeInvoiced, QtyToBeInvoicedBase, QtyToBeConsumed, QtyToBeConsumedBase);

                    if ServiceLine.Type = ServiceLine.Type::Item then begin
                        if Consume then
                            ServPostingJnlsMgt.PostItemJnlLine(
                              ServiceLine, 0, 0,
                              QtyToBeConsumed, QtyToBeConsumedBase,
                              QtyToBeInvoiced, QtyToBeInvoicedBase,
                              ItemEntryRelation."Item Entry No.",
                              TempInvoicingSpecification, TempTrackingSpecificationInv,
                              TempHandlingSpecification, TempTrackingSpecification,
                              ServShptHeader, ServiceShptLine."Document No.");

                        if Invoice then
                            ServPostingJnlsMgt.PostItemJnlLine(
                              ServiceLine, 0, 0,
                              QtyToBeConsumed, QtyToBeConsumedBase,
                              QtyToBeInvoiced, QtyToBeInvoicedBase,
                              ItemEntryRelation."Item Entry No.",
                              TempInvoicingSpecification, TempTrackingSpecificationInv,
                              TempHandlingSpecification, TempTrackingSpecification,
                              ServShptHeader, ServiceShptLine."Document No.");
                    end;

                    if TrackingSpecificationExists then
                        EndLoop := (TempInvoicingSpecification.Next() = 0)
                    else
                        EndLoop :=
                          (ServiceShptLine.Next() = 0) or
                          ((Invoice and (Abs(RemQtyToBeInvoiced) <= Abs(ServiceLine."Qty. to Ship"))) or
                           (Consume and (Abs(RemQtyToBeConsumed) <= Abs(ServiceLine."Qty. to Ship"))));
                until EndLoop;
            end else
                if ServiceLine."Shipment Line No." <> 0 then
                    Error(Text026, ServiceLine."Shipment Line No.", ServiceLine."Shipment No.")
                else
                    Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        end;

        if (Invoice and (Abs(RemQtyToBeInvoiced) > Abs(ServiceLine."Qty. to Ship"))) or
           (Consume and (Abs(RemQtyToBeConsumed) > Abs(ServiceLine."Qty. to Ship")))
        then begin
            if ServHeader."Document Type" = ServHeader."Document Type"::Invoice then
                Error(Text027, ServiceShptLine."Document No.");
            Error(Text013);
        end;
    end;

    local procedure UpdateServLinesOnPostOrder()
    var
        CalcInvDiscAmt: Boolean;
        OldInvDiscountAmount: Decimal;
        IsHandled: Boolean;
    begin
        CalcInvDiscAmt := false;
        with ServLine do begin
            if Find('-') then
                repeat
                    IsHandled := false;
                    OnUpdateServLinesOnPostOrderOnBeforeServLineLoop(ServLine, Invoice, IsHandled);
                    if not IsHandled then
                        if Quantity <> 0 then begin
                            OldInvDiscountAmount := "Inv. Discount Amount";
                            OnUpdateServLinesOnPostOrderOnBeforeCalcQuantityShipped(ServLine);
                            if Ship then begin
                                "Quantity Shipped" := "Quantity Shipped" + "Qty. to Ship";
                                "Qty. Shipped (Base)" := "Qty. Shipped (Base)" + "Qty. to Ship (Base)";
                            end;

                            if Consume then begin
                                if Abs("Quantity Consumed" + "Qty. to Consume") >
                                   Abs("Quantity Shipped" - "Quantity Invoiced")
                                then begin
                                    Validate("Qty. to Consume", "Quantity Shipped" - "Quantity Invoiced" - "Quantity Consumed");
                                    "Qty. to Consume (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)" - "Qty. Consumed (Base)";
                                end;
                                "Quantity Consumed" := "Quantity Consumed" + "Qty. to Consume";
                                "Qty. Consumed (Base)" := "Qty. Consumed (Base)" + "Qty. to Consume (Base)";
                                Validate("Qty. to Consume", 0);
                                "Qty. to Consume (Base)" := 0;
                            end;

                            if Invoice then begin
                                if Abs("Quantity Invoiced" + "Qty. to Invoice") >
                                   Abs("Quantity Shipped" - "Quantity Consumed")
                                then begin
                                    Validate("Qty. to Invoice", "Quantity Shipped" - "Quantity Invoiced" - "Quantity Consumed");
                                    "Qty. to Invoice (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)" - "Qty. Consumed (Base)";
                                end;
                                "Quantity Invoiced" := "Quantity Invoiced" + "Qty. to Invoice";
                                "Qty. Invoiced (Base)" := "Qty. Invoiced (Base)" + "Qty. to Invoice (Base)";
                            end;

                            OnUpdateServLinesOnPostOrderOnBeforeInitOutstanding(ServLine, Consume, Invoice);
                            InitOutstanding();
                            InitQtyToShip();

                            if "Inv. Discount Amount" <> OldInvDiscountAmount then
                                CalcInvDiscAmt := true;

                            OnUpdateServLinesOnPostOrderOnBeforeServLineModify(ServLine);
                            Modify();
                        end;
                until Next() = 0;

            if Find('-') then
                if SalesSetup."Calc. Inv. Discount" or CalcInvDiscAmt then begin
                    ServHeader.Get("Document Type", "Document No.");
                    Clear(ServCalcDisc);
                    ServCalcDisc.CalculateWithServHeader(ServHeader, PServLine, ServLine);
                end;
        end;
    end;

    local procedure UpdateServLinesOnPostInvoice()
    var
        PServShptLine: Record "Service Shipment Line";
    begin
        ServLine.SetFilter("Shipment No.", '<>%1', '');
        if ServLine.Find('-') then
            repeat
                if ServLine.Type <> ServLine.Type::" " then
                    with PServLine do begin
                        PServShptLine.Get(ServLine."Shipment No.", ServLine."Shipment Line No.");
                        Get("Document Type"::Order, PServShptLine."Order No.", PServShptLine."Order Line No.");
                        "Quantity Invoiced" := "Quantity Invoiced" + ServLine."Qty. to Invoice";
                        "Qty. Invoiced (Base)" := "Qty. Invoiced (Base)" + ServLine."Qty. to Invoice (Base)";
                        if Abs("Quantity Invoiced") > Abs("Quantity Shipped") then
                            Error(Text014, "Document No.");
                        Validate("Qty. to Consume", 0);
                        InitQtyToInvoice();
                        InitOutstanding();
                        Modify();
                    end;

            until ServLine.Next() = 0;
        ServITRMgt.InsertTrackingSpecification(ServHeader, TempTrackingSpecification);
        ServLine.SetRange("Shipment No.");
    end;

    local procedure UpdateServLinesOnPostCrMemo()
    begin
    end;

    local procedure GetShippingAdvice(): Boolean
    var
        ServLine2: Record "Service Line";
    begin
        ServLine2.SetRange("Document Type", ServHeader."Document Type");
        ServLine2.SetRange("Document No.", ServHeader."No.");
        OnGetShippingAdviceOnAfterServLine2SetFilters(ServLine2);
        if ServLine2.FindSet() then
            repeat
                if ServLine2.IsShipment() then begin
                    if ServLine2."Document Type" <> ServLine2."Document Type"::"Credit Memo" then
                        if ServLine2."Quantity (Base)" <>
                           ServLine2."Qty. to Ship (Base)" + ServLine2."Qty. Shipped (Base)"
                        then
                            exit(false);
                end;
            until ServLine2.Next() = 0;
        exit(true);
    end;

    local procedure RemoveLinesNotSatisfyPosting()
    var
        ServiceLine2: Record "Service Line";
        IsHandled: Boolean;
    begin
        // Find ServLines not selected to post, and check if they were completely posted
        if ServLine.FindFirst() then begin
            ServiceLine2.SetRange("Document Type", ServHeader."Document Type");
            ServiceLine2.SetRange("Document No.", ServHeader."No.");
            ServiceLine2.FindSet();
            if ServLine.Count() <> ServiceLine2.Count() then
                repeat
                    IsHandled := false;
                    OnRemoveLinesNotSatisfyPostingOnFindServLinesNotSelectedToPost(ServHeader, ServLine, ServiceLine2, CloseCondition, IsHandled);
                    if not IsHandled then
                        if not ServLine.Get(ServiceLine2."Document Type", ServiceLine2."Document No.", ServiceLine2."Line No.") then
                            if ServiceLine2.Quantity <> ServiceLine2."Quantity Invoiced" + ServiceLine2."Quantity Consumed" then
                                CloseCondition := false;
                until (ServiceLine2.Next() = 0) or (not CloseCondition);
        end;
        // Remove ServLines that do not meet the posting conditions from the selected to post lines
        with ServLine do
            if FindSet() then
                repeat
                    if ((Ship and not Consume and not Invoice and (("Qty. to Consume" <> 0) or ("Qty. to Ship" = 0))) or
                        ((Ship and Consume) and ("Qty. to Consume" = 0)) or
                        ((Ship and Invoice) and (("Qty. to Consume" <> 0) or (("Qty. to Ship" = 0) and ("Qty. to Invoice" = 0)))) or
                        ((not Ship and Invoice) and (("Qty. to Invoice" = 0) or
                                                     ("Quantity Shipped" - "Quantity Invoiced" - "Quantity Consumed" = 0)))) and
                       ("Attached to Line No." = 0)
                    then begin
                        if Quantity <> "Quantity Invoiced" + "Quantity Consumed" then
                            CloseCondition := false;
                        OnRemoveLinesNotSatisfyPostingOnBeforeRemoveServLines(ServHeader, ServLine);
                        if ((Type <> Type::" ") and (Description = '') and ("No." = '')) or
                           ((Type <> Type::" ") and (Description <> '') and ("No." <> ''))
                        then begin
                            ServiceLine2 := ServLine;
                            if ServiceLine2.Find() then begin
                                IsHandled := false;
                                OnRemoveLinesNotSatisfyPostingOnBeforeInitRemainingServLine(ServiceLine2, IsHandled);
                                if not IsHandled then begin
                                    ServiceLine2.InitOutstanding();
                                    ServiceLine2.InitQtyToShip();
                                    ServiceLine2.Modify();
                                end;
                            end;
                            DeleteWithAttachedLines();
                        end;
                    end;
                until Next() = 0;
    end;

    local procedure FinalizeDeleteComments(TableSubType: Enum "Service Document Type")
    begin
        ServiceCommentLine.SetRange("No.", ServHeader."No.");
        ServiceCommentLine.SetRange(Type, ServiceCommentLine.Type::General);
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("Table Subtype", TableSubType);
        ServiceCommentLine.DeleteAll();
    end;

    local procedure FinalizeDeleteServOrdAllocat()
    var
        ServiceOrderAllocationRec: Record "Service Order Allocation";
    begin
        if not (ServHeader."Document Type" in [ServHeader."Document Type"::Quote, ServHeader."Document Type"::Order]) then
            exit;
        ServiceOrderAllocationRec.Reset();
        ServiceOrderAllocationRec.SetCurrentKey("Document Type", "Document No.");
        ServiceOrderAllocationRec.SetRange("Document Type", ServHeader."Document Type");
        ServiceOrderAllocationRec.SetRange("Document No.", ServHeader."No.");
        ServiceOrderAllocationRec.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure TestSalesEfects(ServiceHeader: Record "Service Header"; Cust: Record Customer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Text1100000: Label 'At least one document of %1 No. %2 is closed or in a Bill Group.';
        Text1100001: Label 'This will avoid the document to be settled.\';
        Text1100002: Label 'The posting process of %3 No. %4 will not settle any document.\';
        ShowError: Boolean;
        Text1100003: Label 'Due this customer is using Apply to Oldest Application Method, please remove the lines for the Bill Group before posting.';
    begin
        ShowError := false;
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then begin
            CustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
            CustLedgEntry.SetFilter("Document Type", '%1|%2', CustLedgEntry."Document Type"::Invoice,
              CustLedgEntry."Document Type"::Bill);
            CustLedgEntry.SetFilter("Document Situation", '<>%1', CustLedgEntry."Document Situation"::" ");
            CustLedgEntry.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
            CustLedgEntry.SetRange(Open, true);

            if CustLedgEntry.Find('-') then
                repeat
                    if CustLedgEntry."Document Situation" <> CustLedgEntry."Document Situation"::Cartera then
                        if not ((CustLedgEntry."Document Situation" in
                                 [CustLedgEntry."Document Situation"::"Closed Documents",
                                  CustLedgEntry."Document Situation"::"Closed BG/PO"]) and
                                (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Rejected))
                        then
                            ShowError := true;
                until CustLedgEntry.Next() = 0;

            if ShowError then
                Error(Text1100000 +
                  Text1100001 +
                  Text1100002 +
                  Text1100003,
                  Format(CustLedgEntry."Document Type"),
                  Format(CustLedgEntry."Document No."),
                  Format(ServiceHeader."Document Type"),
                  Format(ServiceHeader."No."));
        end;
    end;

    local procedure FinalizeWarrantyLedgerEntries(var ServiceHeader: Record "Service Header"; CloseCondition: Boolean)
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.Reset();
        WarrantyLedgerEntry.SetCurrentKey("Service Order No.", "Posting Date", "Document No.");
        WarrantyLedgerEntry.SetRange("Service Order No.", ServiceHeader."No.");
        if WarrantyLedgerEntry.IsEmpty() then
            exit;
        if CloseCondition then begin
            WarrantyLedgerEntry.ModifyAll(Open, false);
            exit;
        end;
        if not ServLine.Find('-') then
            exit;
        repeat
            FillTempWarrantyLedgerEntry(ServLine, WarrantyLedgerEntry);
            ServLineInvoicedConsumedQty := ServLine."Quantity Invoiced" + ServLine."Quantity Consumed";
            UpdateTempWarrantyLedgerEntry();
            UpdWarrantyLedgEntriesFromTemp();
        until ServLine.Next() = 0;
    end;

    local procedure FillTempWarrantyLedgerEntry(TempServiceLineParam: Record "Service Line" temporary; var WarrantyLedgerEntryPar: Record "Warranty Ledger Entry")
    begin
        TempWarrantyLedgerEntry.DeleteAll();
        WarrantyLedgerEntryPar.Find('-');
        repeat
            if WarrantyLedgerEntryPar."Service Order Line No." = TempServiceLineParam."Line No." then begin
                TempWarrantyLedgerEntry := WarrantyLedgerEntryPar;
                TempWarrantyLedgerEntry.Insert();
            end;
        until WarrantyLedgerEntryPar.Next() = 0;
    end;

    local procedure UpdateTempWarrantyLedgerEntry()
    var
        Reduction: Decimal;
    begin
        if not TempWarrantyLedgerEntry.Find('-') then
            exit;
        repeat
            Reduction := FindMinimumNumber(ServLineInvoicedConsumedQty, TempWarrantyLedgerEntry.Quantity);
            ServLineInvoicedConsumedQty -= Reduction;
            TempWarrantyLedgerEntry.Quantity -= Reduction;
            TempWarrantyLedgerEntry.Modify();
        until (TempWarrantyLedgerEntry.Next() = 0) or (ServLineInvoicedConsumedQty <= 0);
        TempWarrantyLedgerEntry.Find('-');
        repeat
            TempWarrantyLedgerEntry.Open := TempWarrantyLedgerEntry.Quantity > 0;
            TempWarrantyLedgerEntry.Modify();
        until (TempWarrantyLedgerEntry.Next() = 0);
    end;

    local procedure FindMinimumNumber(DecimalNumber1: Decimal; DecimalNumber2: Decimal): Decimal
    begin
        if DecimalNumber1 < DecimalNumber2 then
            exit(DecimalNumber1);
        exit(DecimalNumber2);
    end;

    local procedure SortLines(var ServLine: Record "Service Line")
    var
        InvSetup: Record "Inventory Setup";
    begin
        OnBeforeSortLines(ServLine);

        if InvSetup.OptimGLEntLockForMultiuserEnv() then
            ServLine.SetCurrentKey("Document Type", "Document No.", Type, "No.")
        else
            ServLine.SetCurrentKey("Document Type", "Document No.", "Line No.");

        OnAfterSortLines(ServLine);
    end;

    local procedure UpdateServiceLedgerEntry(ServLedgEntryNo: Integer)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.Get(ServLedgEntryNo);
        ServiceLedgerEntry."Job Posted" := true;
        ServiceLedgerEntry.Modify();
    end;

    internal procedure UpdateServiceLedgerEntry(ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LCYRoundingPrecision: Decimal;
        CurrencyFactor: Decimal;
    begin
        if ServiceLine."Appl.-to Service Entry" = 0 then
            exit;
        if not ServiceLedgerEntry.Get(ServiceLine."Appl.-to Service Entry") then
            exit;
        if (ServiceLine."Unit Price" = xServiceLine."Unit Price") and (ServiceLine."Unit Cost" = xServiceLine."Unit Cost") and
           (ServiceLine.Amount = xServiceLine.Amount) and (ServiceLine."Line Discount Amount" = xServiceLine."Line Discount Amount") and
           (ServiceLine."Line Discount %" = xServiceLine."Line Discount %")
        then
            exit;

        CurrencyFactor := 1;
        if ServiceLine."Currency Code" <> '' then begin
            CurrencyExchangeRate.SetRange("Currency Code", ServiceLine."Currency Code");
            CurrencyExchangeRate.SetRange("Starting Date", 0D, ServiceLine."Order Date");
            if CurrencyExchangeRate.FindLast() then
                CurrencyFactor := CurrencyExchangeRate."Adjustment Exch. Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";
        end;
        GeneralLedgerSetup.Get();
        LCYRoundingPrecision := 0.01;
        if Currency.Get(GeneralLedgerSetup."LCY Code") then
            LCYRoundingPrecision := Currency."Amount Rounding Precision";

        if ServiceLine."Unit Price" <> xServiceLine."Unit Price" then
            ServiceLedgerEntry."Unit Price" := -Round(ServiceLine."Unit Price" / CurrencyFactor, LCYRoundingPrecision);
        if ServiceLine."Unit Cost (LCY)" <> xServiceLine."Unit Cost (LCY)" then
            ServiceLedgerEntry."Unit Cost" := ServiceLine."Unit Cost (LCY)";
        if ServiceLine.Amount <> xServiceLine.Amount then begin
            ServiceLedgerEntry.Amount := -ServiceLine.Amount;
            ServiceLedgerEntry."Amount (LCY)" := -Round(ServiceLine.Amount / CurrencyFactor, LCYRoundingPrecision);
        end;
        if ServiceLine."Line Discount Amount" <> xServiceLine."Line Discount Amount" then
            ServiceLedgerEntry."Discount Amount" := Round(ServiceLine."Line Discount Amount" / CurrencyFactor, LCYRoundingPrecision);
        if ServiceLine."Line Discount %" <> xServiceLine."Line Discount %" then
            ServiceLedgerEntry."Discount %" := ServiceLine."Line Discount %";
        ServiceLedgerEntry.Modify();
    end;


    local procedure UpdWarrantyLedgEntriesFromTemp()
    var
        WarrantyLedgerEntryLocal: Record "Warranty Ledger Entry";
    begin
        if not TempWarrantyLedgerEntry.Find('-') then
            exit;
        repeat
            WarrantyLedgerEntryLocal.Get(TempWarrantyLedgerEntry."Entry No.");
            if WarrantyLedgerEntryLocal.Open and not TempWarrantyLedgerEntry.Open then begin
                WarrantyLedgerEntryLocal.Open := false;
                WarrantyLedgerEntryLocal.Modify();
            end;
        until TempWarrantyLedgerEntry.Next() = 0;
        TempWarrantyLedgerEntry.DeleteAll();
    end;

    local procedure CheckCertificateOfSupplyStatus(ServShptHeader: Record "Service Shipment Header"; ServShptLine: Record "Service Shipment Line")
    var
        CertificateOfSupply: Record "Certificate of Supply";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if ServShptLine.Quantity <> 0 then
            if VATPostingSetup.Get(ServShptHeader."VAT Bus. Posting Group", ServShptLine."VAT Prod. Posting Group") and
               VATPostingSetup."Certificate of Supply Required"
            then begin
                CertificateOfSupply.InitFromService(ServShptHeader);
                CertificateOfSupply.SetRequired(ServShptHeader."No.");
                OnAfterCheckCertificateOfSupplyStatus(ServShptHeader, ServShptLine);
            end;
    end;

    local procedure GetZeroServiceLineRecID(ServiceHeader: Record "Service Header"; var ServiceLineRecID: RecordId)
    var
        ZeroServiceLine: Record "Service Line";
    begin
        ZeroServiceLine."Document Type" := ServiceHeader."Document Type";
        ZeroServiceLine."Document No." := ServiceHeader."No.";
        ZeroServiceLine."Line No." := 0;
        ServiceLineRecID := ZeroServiceLine.RecordId;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyServiceDocNoSeries(var ServHeader: Record "Service Header"; PServHeader: Record "Service Header"; ModifyHeader: Boolean)
    begin
    end;

    procedure CollectTrackingSpecification(var TempTargetTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        TempTrackingSpecification.Reset();
        TempTargetTrackingSpecification.Reset();
        TempTargetTrackingSpecification.DeleteAll();

        if TempTrackingSpecification.FindSet() then
            repeat
                TempTargetTrackingSpecification := TempTrackingSpecification;
                TempTargetTrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0;
    end;

    local procedure PostResourceUsage(TempServLine: Record "Service Line" temporary)
    var
        DocNo: Code[20];
    begin
        if Consume or not Ship or (ServLine."Qty. to Ship" = 0) or
           not (ServLine."Document Type" = ServLine."Document Type"::Invoice) and
           not (ServLine."Document Type" = ServLine."Document Type"::Order)
        then
            exit;

        if (ServLine."Document Type" = ServLine."Document Type"::Invoice) and (ServShptHeader."No." = '') then
            DocNo := GenJnlLineDocNo
        else
            DocNo := ServShptHeader."No.";

        ServPostingJnlsMgt.PostResJnlLineShip(TempServLine, DocNo, '');
    end;

    local procedure SetServiceLedgerEntryFilters(var ServLedgEntry: Record "Service Ledger Entry"; ServiceContractNo: Code[20])
    begin
        ServLedgEntry.Reset();
        ServLedgEntry.SetCurrentKey("Service Contract No.");
        ServLedgEntry.SetRange("Service Contract No.", ServiceContractNo);
        ServLedgEntry.SetRange("Service Order No.", '');
        ServLedgEntry.SetRange(Open, true);
        ServLedgEntry.SetFilter("Entry No.", '<%1', ServLedgEntryNo);

        OnAfterSetServiceLedgerEntryFilters(ServLedgEntry);
    end;

    local procedure CheckVATDate(var ServiceHeader: Record "Service Header")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // ensure VAT Date is filled in
        if ServiceHeader."VAT Reporting Date" = 0D then begin
            ServiceHeader."VAT Reporting Date" := GLSetup.GetVATDate(ServiceHeader."Posting Date", ServiceHeader."Document Date");
            ServiceHeader.Modify();
        end;
    end;

#if not CLEAN23
    local procedure UseLegacyInvoicePosting(): Boolean
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        exit(not FeatureKeyManagement.IsExtensibleInvoicePostingEngineEnabled());
    end;
#endif    

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCertificateOfSupplyStatus(ServShptHeader: Record "Service Shipment Header"; ServShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimComb(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalize(var ServiceHeader: Record "Service Header"; var CloseCondition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeHeader(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeCrMemoDocument(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: record "Service Header"; var PServCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeInvoiceDocument(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: record "Service Header"; var PServInvHeader: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeShipmentDocument(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: record "Service Header"; var PServShptHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var CloseCondition: Boolean; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServLedgerEntrySaleConsume(var NextServLedgerEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDocumentLines(var ServHeader: Record "Service Header"; var ServInvHeader: Record "Service Invoice Header"; var ServInvLine: Record "Service Invoice Line"; var ServCrMemoHeader: Record "Service Cr.Memo Header"; var ServCrMemoLine: Record "Service Cr.Memo Line"; GenJnlLineDocType: enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostServiceResourceLine(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var ServMgtSetup: Record "Service Mgt. Setup"; var TempServLine: Record "Service Line" temporary; var GenJnlLineDocNo: Code[20]; var GenJnlLineExtDocNo: Code[35]; var Ship: Boolean; var Invoice: Boolean; var Consume: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareDocument(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareShipmentHeader(var ServiceShptHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareInvoiceHeader(var ServiceInvHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header"; var ServItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServShptHeaderInsert(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServShptLineInsert(var ServiceShipmentLine: Record "Service Shipment Line"; ServiceLine: Record "Service Line"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceInvoiceHeader: Record "Service Invoice Header"; PassedServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServShptItemLineInsert(var ServiceShptItemLine: Record "Service Shipment Item Line"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServInvLineInsert(var ServiceInvoiceLine: Record "Service Invoice Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServCrMemoLineInsert(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSortLines(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcContractDates(var ServItemLine: Record "Service Item Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalize(var ServiceHeader: Record "Service Header"; var CloseCondition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeCrMemoDocument(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServHeader: Record "Service Header" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeInvoiceDocument(var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServHeader: Record "Service Header" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeShipmentDocument(var ServiceShipmentHeader: Record "Service Shipment Header"; var ServHeader: Record "Service Header" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeDeleteHeader(var PassedServHeader: Record "Service Header"; var ServHeader: Record "Service Header" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeDeleteItemLines(var PServItemLine: Record "Service Item Line"; var ServHeader: Record "Service Header" temporary; var ServItemLine: Record "Service Item Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAndCheckCustomer(var ServiceHeader: Record "Service Header" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvoicePostingSetup(var InvoicePostingInterface: Interface "Invoice Posting"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var CloseCondition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostServiceItemLine(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLedgerEntrySaleConsume(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; var ServMgtSetup: Record "Service Mgt. Setup"; var NextServLedgerEntryNo: Integer; var GenJnlLineDocNo: Code[20]; Consume: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServInvLineInsert(var ServiceInvoiceLine: Record "Service Invoice Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServCrMemoLineInsert(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServShptHeaderInsert(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServShptLineInsert(var ServiceShipmentLine: Record "Service Shipment Line"; ServiceLine: Record "Service Line"; ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServShptItemLineInsert(var ServiceShptItemLine: Record "Service Shipment Item Line"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGenJnlLineDocNumbers(var ServiceHeader: Record "Service Header"; var DocType: Integer; var DocNo: Code[20]; var ExtDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLastNos(var PServHeader: Record "Service Header"; var ServHeader: Record "Service Header" temporary; Ship: Boolean; Invoice: Boolean; ServLinesPassed: Boolean; CloseCondition: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortLines(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocumentLines(var ServHeader: Record "Service Header"; var CloseCondition: Boolean; var ServLinesPassed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCloseConditionOnAfterServiceLineTempLoop(var ServiceItemLine: Record "Service Item Line"; var ServiceLine: Record "Service Line"; Qty: Decimal; QtytoInv: Decimal; QtyToCsm: Decimal; QtyInvd: Decimal; QtyCsmd: Decimal; var ServiceItemClosedCondition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimensionsAnAfterSetServLineFilters(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndSetPostingContantsOnAfterSetFilterForConsume(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndSetPostingContantsOnAfterSetFilterForInvoice(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndSetPostingContantsOnAfterSetFilterForShip(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndBlankQtysOnAfterServLineSetFilters(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndBlankQtysOnBeforeCheckServLine(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOnBeforeFinalizeDeleteHeader(var PassedServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOnBeforeFinalizeHeader(var PassedServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeDeleteLinesOnAfterSetPServItemLineFilters(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeDeleteLinesOnAfterSetPServLineFilters(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeItemLinesOnAfterSetFilters(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeLinesOnAfterSetFilters(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterFillInvPostingBuffer(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterPrepareLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterFinishServiceRegister(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforeCheckServLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Ship: Boolean; Invoice: Boolean; var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterSortLines(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterCalcShouldPostShipmentServiceEntry(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var Ship: Boolean; var ApplToServEntryNo: Integer; var NextServLedgerEntryNo: Integer; var ShouldPostShipmentServiceEntry: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation in codeunit Service Post Invoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforePostInvoicePostBuffer(ServiceHeader: Record "Service Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforePostRemQtyToBeConsumed(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDocumentOnBeforePassedServLineFind(var PassedServLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforeRoundAmount(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterServPostingJnlsMgtCreateCreditEntry(var NextServLedgerEntryNo: Integer; var ApplToServEntryNo: Integer; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterServPostingJnlsMgtInsertServLedgerEntrySaleInvoice(var NextServLedgerEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostServiceResourceLineOnBeforeCalcSLEDivideAmount(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDocumentOnAfterSetPServItemLineFilters(var PServItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDocumentOnAfterSetPServLineFilters(var PServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveLinesNotSatisfyPostingOnBeforeInitRemainingServLine(var ServiceLine2: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateShptLinesOnInvOnAfterServiceShptLineModify(ServiceLine: Record "Service Line"; ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingSpecificationExists: Boolean; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; QtyToBeConsumed: Decimal; QtyToBeConsumedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLinesOnPostOrderOnBeforeCalcQuantityShipped(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLinesOnPostOrderOnBeforeInitOutstanding(var ServiceLine: Record "Service Line"; var Consume: Boolean; var Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDocumentOnPServLineLoopOnBeforeServLineInsert(var ServLine: Record "Service Line"; PServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceLedgerEntryFilters(var ServLedgEntry: Record "Service Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeInvtAdjustment(var InvtSetup: Record "Inventory Setup"; var ServHeader: Record "Service Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(var ServiceLine2: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNoSeries(var ServHeader: Record "Service Header" temporary; Invoice: Boolean; Consume: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOnBeforeFinalizeHeaderAndLines(var PassedServHeader: Record "Service Header"; var IsHandled: Boolean; var CloseCondition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeDeleteHeaderOnAfterDeleteInvoiceSpecFromHeader(var ServHeader: Record "Service Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareShipmentHeaderOnBeforeCalcServItemDates(var ServHeader: Record "Service Header"; var ServItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareInvoiceHeaderOnAfterServInvHeaderTransferFields(var ServHeader: Record "Service Header"; var ServInvHeader: Record "Service Invoice Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareInvoiceHeaderOnBeforeCheckPostingNo(var ServHeader: Record "Service Header"; var ServInvHeader: Record "Service Invoice Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateShptLinesOnInvOnAfterCalcQtyToBeConsumed(var ServiceLine: Record "Service Line"; var QtyToBeConsumed: Decimal; var QtyToBeConsumedBase: Decimal; var RemQtyToBeConsumed: Decimal; var RemQtyToBeConsumedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLinesOnPostOrderOnBeforeServLineLoop(var ServiceLine: Record "Service Line"; Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShippingAdviceOnAfterServLine2SetFilters(var ServiceLine2: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveLinesNotSatisfyPostingOnFindServLinesNotSelectedToPost(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceLine2: Record "Service Line"; var CloseCondition: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveLinesNotSatisfyPostingOnBeforeRemoveServLines(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforeFilterServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterCheckCloseCondition(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLinesOnPostOrderOnBeforeServLineModify(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnAfterAssignApplToServEntryNo(var ServiceHeader: Record "Service Header"; var ApplToServEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareShipmentHeaderOnBeforeCreateServiceShipmentItemLine(var ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetNoSeriesOnBeforeSetPostingNo(var ServiceHeader: Record "Service Header"; Invoice: Boolean; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimValuePostingOnAssignDimensionsToNewLine(var TableIDArr: array[10] of Integer; var NumberArr: array[10] of Code[20]; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDocumentOnServLineInsert(var ServiceHeader2: Record "Service Header"; var ServiceLine: Record "Service Line"; ServiceLine2: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforeCreateCreditEntry(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; GenJnlLineDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeHeader(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeShipmentDocumentOnAfterInserServiceShipmentLine(var ServiceShipmentLine2: Record "Service Shipment Line")
    begin
    end;
}
