codeunit 5988 "Serv-Documents Mgt."
{
    Permissions = TableData "Invoice Post. Buffer" = imd,
                  TableData "Service Header" = imd,
                  TableData "Service Item Line" = imd,
                  TableData "Service Line" = imd,
                  TableData "Service Ledger Entry" = m,
                  TableData "Warranty Ledger Entry" = m,
                  TableData "Service Shipment Item Line" = imd,
                  TableData "Service Shipment Header" = imd,
                  TableData "Service Shipment Line" = imd,
                  TableData "Service Invoice Header" = imd,
                  TableData "Service Invoice Line" = imd,
                  TableData "Service Cr.Memo Header" = imd,
                  TableData "Service Cr.Memo Line" = imd;

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
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        GenJnlLineExtDocNo: Code[35];
        GenJnlLineDocNo: Code[20];
        SrcCode: Code[10];
        GenJnlLineDocType: Integer;
        ItemLedgShptEntryNo: Integer;
        NextServLedgerEntryNo: Integer;
        NextWarrantyLedgerEntryNo: Integer;
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
        Text001: Label 'There is nothing to post.';
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
        PassedServiceHeader.ValidateSalesPersonOnServiceHeader(PassedServiceHeader, true, true);
        PrepareDocument(PassedServiceHeader, PassedServiceLine);
        CheckSysCreatedEntry();
        CheckShippingAdvice();
        CheckDimensions();
        ServMgtSetup.Get();
        GetAndCheckCustomer();
        SalesSetup.Get();
        SrcCodeSetup.Get();
        SrcCode := SrcCodeSetup."Service Management";
        ServPostingJnlsMgt.Initialize(ServHeader, Consume, Invoice);
        ServAmountsMgt.Initialize(ServHeader."Currency Code"); // roundingLineInserted is set to FALSE;
        TrackingSpecificationExists := false;

        OnAfterInitialize(PassedServiceHeader, PassedServiceLine, CloseCondition, Ship, Consume, Invoice);
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
        TempServLine: Record "Service Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineForSLE: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        InvPostingBuffer: array[2] of Record "Invoice Post. Buffer" temporary;
        DummyTrackingSpecification: Record "Tracking Specification";
        Item: Record Item;
        ServItemMgt: Codeunit ServItemManagement;
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal;
        RemQtyToBeConsumed: Decimal;
        RemQtyToBeConsumedBase: Decimal;
        LineCount: Integer;
        ApplToServEntryNo: Integer;
        WarrantyNo: Integer;
        BiggestLineNo: Integer;
        LastLineRetrieved: Boolean;
    begin
        LineCount := 0;

        // init cu for posting SLE type Usage
        ServPostingJnlsMgt.InitServiceRegister(NextServLedgerEntryNo, NextWarrantyLedgerEntryNo);
        if not ApplicationAreaMgmt.IsSalesTaxEnabled then begin
            ServLine.CalcVATAmountLines(1, ServHeader, ServLine, TempVATAmountLine, Ship);
            ServLine.CalcVATAmountLines(2, ServHeader, ServLine, TempVATAmountLineForSLE, Ship);
        end;

        ServLine.Reset();
        SortLines(ServLine);
        ServLedgEntryNo := FindFirstServLedgEntry(ServLine);
        if ServLine.Find('-') then
            repeat
                ServPostingJnlsMgt.SetItemJnlRollRndg(false);
                if ServLine.Type = ServLine.Type::Item then
                    DummyTrackingSpecification.CheckItemTrackingQuantity(
                      DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.",
                      ServLine."Qty. to Ship (Base)", ServLine."Qty. to Invoice (Base)", Ship, Invoice);
                LineCount += 1;
                Window.Update(2, LineCount);

                with ServLine do begin
                    OnPostDocumentLinesOnBeforeCheckServLine(ServHeader, ServLine, Ship, Invoice);

                    if Ship and ("Qty. to Ship" <> 0) or Invoice and ("Qty. to Invoice" <> 0) then
                        ServOrderMgt.CheckServItemRepairStatus(ServHeader, ServItemLine, ServLine);

                    ServLineOld := ServLine;
                    if "Spare Part Action" in
                       ["Spare Part Action"::"Component Replaced",
                        "Spare Part Action"::Permanent,
                        "Spare Part Action"::"Temporary"]
                    then begin
                        "Spare Part Action" := "Spare Part Action"::"Component Installed";
                        Modify
                    end;

                    // post Service Ledger Entry of type Usage, on shipment
                    if (Ship and ("Document Type" = "Document Type"::Order) or
                        ("Document Type" = "Document Type"::Invoice)) and
                       ("Qty. to Ship" <> 0) and not ServAmountsMgt.RoundingLineInserted
                    then begin
                        TempServLine := ServLine;
                        ServPostingJnlsMgt.CalcSLEDivideAmount("Qty. to Ship", ServHeader, TempServLine, TempVATAmountLineForSLE);

                        ApplToServEntryNo :=
                          ServPostingJnlsMgt.InsertServLedgerEntry(NextServLedgerEntryNo,
                            ServHeader, TempServLine, ServItemLine, "Qty. to Ship", ServHeader."Shipping No.");

                        if "Appl.-to Service Entry" = 0 then
                            "Appl.-to Service Entry" := ApplToServEntryNo;
                    end;

                    if (Type = Type::Item) and ("No." <> '') then begin
                        GetServLineItem(ServLine, Item);
                        if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment then
                            GetUnitCost;
                    end;

                    if CheckCloseCondition(
                         Quantity, "Qty. to Invoice", "Qty. to Consume", "Quantity Invoiced", "Quantity Consumed") = false
                    then
                        CloseCondition := false;

                    if Quantity = 0 then
                        TestField("Line Amount", 0)
                    else begin
                        TestBinCode;
                        TestField("No.");
                        TestField(Type);
                        if not ApplicationAreaMgmt.IsSalesTaxEnabled then begin
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
                        ServPostingJnlsMgt.CreateCreditEntry(NextServLedgerEntryNo,
                          ServHeader, ServLine, GenJnlLineDocNo);
                    end else
                        if (Invoice or ("Document Type" = "Document Type"::Invoice)) and
                           ("Qty. to Invoice" <> 0) and not ServAmountsMgt.RoundingLineInserted
                        then begin
                            CheckIfServDuplicateLine(ServLine);
                            ServPostingJnlsMgt.InsertServLedgerEntrySale(NextServLedgerEntryNo,
                              ServHeader, ServLine, ServItemLine, "Qty. to Invoice", "Qty. to Invoice", GenJnlLineDocNo, "Line No.");
                        end;

                    if Consume and ("Document Type" = "Document Type"::Order) and
                       ("Qty. to Consume" <> 0)
                    then
                        ServPostingJnlsMgt.InsertServLedgerEntrySale(NextServLedgerEntryNo,
                          ServHeader, ServLine, ServItemLine, "Qty. to Consume", 0, ServHeader."Shipping No.", "Line No.");

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
                        UpdateRcptLinesOnInv
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
                        // Copy sales to buffer
                        ServAmountsMgt.FillInvPostingBuffer(InvPostingBuffer, ServLine, ServiceLineACY, ServHeader);

                    OnPostDocumentLinesOnAfterFillInvPostingBuffer(ServHeader, ServLine);

                    // prepare posted document lines
                    if Ship then
                        PrepareShipmentLine(TempServiceLine, WarrantyNo);
                    if Invoice then
                        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                            PrepareInvoiceLine(TempServiceLine)
                        else
                            PrepareCrMemoLine(TempServiceLine);

                    if Invoice or Consume then
                        CollectValueEntryRelation;

                    if ServAmountsMgt.RoundingLineInserted then
                        LastLineRetrieved := true
                    else begin
                        BiggestLineNo := ServAmountsMgt.MAX(ServAmountsMgt.GetLastLineNo(ServLine), "Line No.");
                        LastLineRetrieved := Next = 0; // ServLine
                        if LastLineRetrieved and SalesSetup."Invoice Rounding" then
                            ServAmountsMgt.InvoiceRounding(ServHeader, ServLine, TotalServiceLine,
                              LastLineRetrieved, false, BiggestLineNo);
                    end;
                end; // With ServLine
            until LastLineRetrieved;

        with ServHeader do begin
            // again reverse amount
            if "Document Type" <> "Document Type"::"Credit Memo" then begin
                ServAmountsMgt.ReverseAmount(TotalServiceLine);
                ServAmountsMgt.ReverseAmount(TotalServiceLineLCY);
                TotalServiceLineLCY."Unit Cost (LCY)" := -TotalServiceLineLCY."Unit Cost (LCY)";
            end;

            ServPostingJnlsMgt.FinishServiceRegister(NextServLedgerEntryNo, NextWarrantyLedgerEntryNo);

            if Invoice or ("Document Type" = "Document Type"::Invoice) then begin
                Clear(ServDocReg);
                // fake service register entry to be used in the following PostServSalesDocument()
                if Invoice and ("Document Type" = "Document Type"::Order) and (ServLine."Contract No." <> '') then
                    ServDocReg.InsertServSalesDocument(
                      ServDocReg."Source Document Type"::Contract, ServLine."Contract No.",
                      ServDocReg."Destination Document Type"::Invoice, ServLine."Document No.");
                ServDocReg.PostServSalesDocument(
                  ServDocReg."Destination Document Type"::Invoice,
                  ServLine."Document No.", ServInvHeader."No.");
            end;
            if Invoice or ("Document Type" = "Document Type"::"Credit Memo") then begin
                Clear(ServDocReg);
                ServDocReg.PostServSalesDocument(
                  ServDocReg."Destination Document Type"::"Credit Memo",
                  ServLine."Document No.",
                  ServCrMemoHeader."No.");
            end;

            // Post sales and VAT to G/L entries from posting buffer
            if Invoice then begin
                OnPostDocumentLinesOnBeforePostInvoicePostBuffer(
                  ServHeader, InvPostingBuffer[1], TotalServiceLine, TotalServiceLineLCY);
                LineCount := 0;
                if InvPostingBuffer[1].Find('+') then
                    repeat
                        LineCount += 1;
                        Window.Update(3, LineCount);
                        ServPostingJnlsMgt.SetPostingDate("Posting Date");
                        ServPostingJnlsMgt.PostInvoicePostBufferLine(
                          InvPostingBuffer[1], GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo);
                    until InvPostingBuffer[1].Next(-1) = 0;

                // Post customer entry
                Window.Update(4, 1);
                ServPostingJnlsMgt.SetPostingDate("Posting Date");
                ServPostingJnlsMgt.PostCustomerEntry(
                  TotalServiceLine, TotalServiceLineLCY,
                  GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo);

                // post Balancing account
                if "Bal. Account No." <> '' then begin
                    Window.Update(5, 1);
                    ServPostingJnlsMgt.SetPostingDate("Posting Date");
                    ServPostingJnlsMgt.PostBalancingEntry(
                      TotalServiceLine, TotalServiceLineLCY,
                      GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo);
                end;
            end; // end posting sales,receivables,balancing

            MakeInvtAdjustment;
            if Ship then begin
                "Last Shipping No." := "Shipping No.";
                "Shipping No." := '';
            end;

            if Invoice then begin
                "Last Posting No." := "Posting No.";
                "Posting No." := '';
            end;

            Modify;
        end;// with header
    end;

    local procedure PostServiceItemLine(ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; RemQtyToBeInvoicedBase: Decimal; RemQtyToBeInvoiced: Decimal; RemQtyToBeConsumedBase: Decimal; RemQtyToBeConsumed: Decimal; var WarrantyNo: Integer)
    var
        TempServLine: Record "Service Line" temporary;
        TempVATAmountLineForSLE: Record "VAT Amount Line" temporary;
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
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
    end;

    local procedure MakeInvtAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <>
           InvtSetup."Automatic Cost Adjustment"::Never
        then begin
            InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
            InvtAdjmt.MakeMultiLevelAdjmt;
        end;
    end;

    procedure UpdateDocumentLines()
    begin
        with ServHeader do begin
            Modify;
            if ("Document Type" = "Document Type"::Order) and not CloseCondition then begin
                ServITRMgt.InsertTrackingSpecification(ServHeader, TempTrackingSpecification);

                // update service line quantities according to posted values
                UpdateServLinesOnPostOrder;
            end else begin
                // close condition met for order, or we post Invoice or CrMemo

                if ServLinesPassed then
                    UpdateServLinesOnPostOrder;

                case "Document Type" of
                    "Document Type"::Invoice:
                        UpdateServLinesOnPostInvoice;
                    "Document Type"::"Credit Memo":
                        UpdateServLinesOnPostCrMemo;
                end;// case

                ServAllocMgt.SetServOrderAllocStatus(ServHeader);
            end; // End CloseConditionMet
        end;
    end;

    local procedure PrepareDocument(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line")
    begin
        // fill ServiceHeader we will work with (tempTable)
        ServHeader.DeleteAll();
        ServHeader.Copy(PassedServHeader);
        ServHeader.Insert(); // temporary table

        // Fetch persistent Service Lines and Service Item Lines bound to Service Header.
        // Copy persistent records to temporary.
        with ServHeader do begin
            ServLine.DeleteAll();
            PassedServLine.Reset();
            // collect passed lines
            OnPrepareDocumentOnBeforePassedServLineFind(PassedServLine, ServHeader);
            if PassedServLine.Find('-') then begin
                repeat
                    ServLine.Copy(PassedServLine);
                    ServLine.Insert(); // temptable
                until PassedServLine.Next = 0;
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
                        OnPrepareDocumentOnPServLineLoopOnBeforeServLineInsert(ServLine);
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

        OnAfterPrepareDocument(PassedServHeader, PassedServLine);
    end;

    procedure PrepareShipmentHeader(): Code[20]
    var
        ServLine: Record "Service Line";
        PServShptHeader: Record "Service Shipment Header";
        PServShptLine: Record "Service Shipment Line";
        ServItemMgt: Codeunit ServItemManagement;
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with ServHeader do begin
            if ("Document Type" = "Document Type"::Order) or
               (("Document Type" = "Document Type"::Invoice) and ServMgtSetup."Shipment on Invoice")
            then begin
                PServShptHeader.LockTable();
                PServShptLine.LockTable();
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
                ServShptHeader."User ID" := UserId;
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
                        // create SSIL
                        ServShptItemLine.TransferFields(ServItemLine);
                        ServShptItemLine."No." := ServShptHeader."No.";
                        OnBeforeServShptItemLineInsert(ServShptItemLine, ServItemLine);
                        ServShptItemLine.Insert();
                        OnAfterServShptItemLineInsert(ServShptItemLine, ServItemLine);

                        // set mgt. date and service dates
                        if (ServItemLine."Contract No." <> '') and (ServItemLine."Contract Line No." <> 0) and
                           ("Contract No." <> '')
                        then begin
                            ServLine.SetRange("Document Type", "Document Type");
                            ServLine.SetRange("Document No.", "No.");
                            ServLine.SetFilter("Quantity Shipped", '>%1', 0);
                            if not ServLine.FindFirst then
                                ServOrderMgt.CalcContractDates(ServHeader, ServItemLine);
                        end;
                        ServOrderMgt.CalcServItemDates(ServHeader, ServItemLine."Service Item No.");
                    until ServItemLine.Next = 0
                else begin
                    ServShptItemLine.Init();
                    ServShptItemLine."No." := ServShptHeader."No.";
                    ServShptItemLine."Line No." := 10000;
                    ServShptItemLine.Description := Format("Document Type") + ' ' + "No.";
                    ServShptItemLine.Insert();
                end;
            end;

            ServItemMgt.CopyReservationEntryService(ServHeader);

            OnAfterPrepareShipmentHeader(ServShptHeader, ServHeader);
            exit(ServShptHeader."No.");
        end;
    end;

    local procedure PrepareShipmentLine(var passedServLine: Record "Service Line"; passedWarrantyNo: Integer)
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        with passedServLine do begin
            if (ServShptHeader."No." <> '') and ("Shipment No." = '') and not ServAmountsMgt.RoundingLineInserted then begin
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
            if "Document Type" = "Document Type"::Order then begin
                ServInvHeader."No." := "Posting No.";
                ServInvHeader."Pre-Assigned No. Series" := '';
                ServInvHeader."Order No. Series" := "No. Series";
                ServInvHeader."Order No." := "No.";
                Window.Update(1, StrSubstNo(Text007, "Document Type", "No.", ServInvHeader."No."));
            end else begin
                ServInvHeader."Pre-Assigned No. Series" := "No. Series";
                ServInvHeader."Pre-Assigned No." := "No.";
                if "Posting No." <> '' then begin
                    ServInvHeader."No." := "Posting No.";
                    Window.Update(1, StrSubstNo(Text007, "Document Type", "No.", ServInvHeader."No."));
                end;
            end;
            if ServMgtSetup."Copy Comments Order to Invoice" then
                RecordLinkManagement.CopyLinks(ServHeader, ServInvHeader);
            ServInvHeader."Source Code" := SrcCode;
            ServInvHeader."User ID" := UserId;
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

            SetGenJnlLineDocNos(2,// Invoice
              ServInvHeader."No.", "No.");

            if ("Document Type" = "Document Type"::Invoice) or
               ("Document Type" = "Document Type"::Order) and ServMgtSetup."Copy Comments Order to Invoice"
            then
                ServOrderMgt.CopyCommentLinesWithSubType(
                  "Service Comment Table Name"::"Service Header".AsInteger(),
                  "Service Comment Table Name"::"Service Invoice Header".AsInteger(),
                  "No.", ServInvHeader."No.", "Document Type".AsInteger());

            OnAfterPrepareInvoiceHeader(ServInvHeader, ServHeader);
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
            ServCrMemoHeader."User ID" := UserId;
            ServCrMemoHeader."No. Printed" := 0;
            OnBeforeServCrMemoHeaderInsert(ServCrMemoHeader, ServHeader);
            ServCrMemoHeader.Insert();
            OnAfterServCrMemoHeaderInsert(ServCrMemoHeader, ServHeader);

            Clear(ServLogMgt);
            ServLogMgt.ServCrMemoPost("No.", ServCrMemoHeader."No.");

            SetGenJnlLineDocNos(3,// Credit Memo
              ServCrMemoHeader."No.", "No.");

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
    begin
        OnBeforeFinalize(PassedServHeader, CloseCondition);

        // finalize codeunits calls
        ServPostingJnlsMgt.Finalize();

        // finalize posted documents
        FinalizeShipmentDocument();
        FinalizeInvoiceDocument();
        FinalizeCrMemoDocument();
        FinalizeWarrantyLedgerEntries(PassedServHeader, CloseCondition);

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
    begin
        PassedServHeader.Copy(ServHeader);
        ServHeader.DeleteAll();

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
            until ServLine.Next = 0;
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
            until ServItemLine.Next = 0;
        ServItemLine.DeleteAll(); // just temp records
    end;

    local procedure FinalizeDeleteHeader(var PassedServHeader: Record "Service Header")
    begin
        with PassedServHeader do begin
            Delete;
            ServITRMgt.DeleteInvoiceSpecFromHeader(ServHeader);
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
    begin
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
        PServShptHeader: Record "Service Shipment Header";
        PServShptItemLine: Record "Service Shipment Item Line";
        PServShptLine: Record "Service Shipment Line";
    begin
        OnBeforeFinalizeShipmentDocument(ServShptHeader);

        ServShptHeader.Reset();
        if ServShptHeader.FindFirst then begin
            PServShptHeader.Init();
            PServShptHeader.Copy(ServShptHeader);
            PServShptHeader.Insert();
        end;
        ServShptHeader.DeleteAll();

        ServShptItemLine.Reset();
        if ServShptItemLine.Find('-') then
            repeat
                PServShptItemLine.Init();
                PServShptItemLine.Copy(ServShptItemLine);
                PServShptItemLine.Insert();
            until ServShptItemLine.Next = 0;
        ServShptItemLine.DeleteAll();

        ServShptLine.Reset();
        if ServShptLine.Find('-') then
            repeat
                PServShptLine.Init();
                PServShptLine.Copy(ServShptLine);
                PServShptLine.Insert();
            until ServShptLine.Next = 0;
        ServShptLine.DeleteAll();

        OnAfterFinalizeShipmentDocument(ServShptHeader, ServHeader);
    end;

    local procedure FinalizeInvoiceDocument()
    var
        PServInvHeader: Record "Service Invoice Header";
        PServInvLine: Record "Service Invoice Line";
    begin
        OnBeforeFinalizeInvoiceDocument(ServInvHeader);

        ServInvHeader.Reset();
        if ServInvHeader.FindFirst then begin
            PServInvHeader.Init();
            PServInvHeader.Copy(ServInvHeader);
            PServInvHeader.Insert();
        end;
        ServInvHeader.DeleteAll();

        ServInvLine.Reset();
        if ServInvLine.Find('-') then
            repeat
                PServInvLine.Init();
                PServInvLine.Copy(ServInvLine);
                PServInvLine.Insert();
            until ServInvLine.Next = 0;
        ServInvLine.DeleteAll();

        OnAfterFinalizeInvoiceDocument(ServInvHeader, ServHeader);
    end;

    local procedure FinalizeCrMemoDocument()
    var
        PServCrMemoHeader: Record "Service Cr.Memo Header";
        PServCrMemoLine: Record "Service Cr.Memo Line";
    begin
        OnBeforeFinalizeCrMemoDocument(ServCrMemoHeader);

        ServCrMemoHeader.Reset();
        if ServCrMemoHeader.FindFirst then begin
            PServCrMemoHeader.Init();
            PServCrMemoHeader.Copy(ServCrMemoHeader);
            PServCrMemoHeader.Insert();
        end;
        ServCrMemoHeader.DeleteAll();

        ServCrMemoLine.Reset();
        if ServCrMemoLine.Find('-') then
            repeat
                PServCrMemoLine.Init();
                PServCrMemoLine.Copy(ServCrMemoLine);
                PServCrMemoLine.Insert();
            until ServCrMemoLine.Next = 0;
        ServCrMemoLine.DeleteAll();

        OnAfterFinalizeCrMemoDocument(ServCrMemoHeader, ServHeader);
    end;

    local procedure GetAndCheckCustomer()
    var
        Cust: Record Customer;
    begin
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
                if not ServLine.IsEmpty then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", true, true);
            end else
                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, true);

            if "Bill-to Customer No." <> "Customer No." then begin
                Cust.Get("Bill-to Customer No.");
                if Ship or ServMgtSetup."Shipment on Invoice" and
                   ("Document Type" = "Document Type"::Invoice)
                then begin
                    ServLine.Reset();
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter("Qty. to Ship", '<>0');
                    if not ServLine.IsEmpty then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", true, true);
                end else
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, true);
            end;
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
            until ServLine.Next = 0;
        ServLine.Reset();
    end;

    local procedure CollectValueEntryRelation()
    begin
        with ServHeader do begin
            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                ServPostingJnlsMgt.CollectValueEntryRelation(TempValueEntryRelation, ServInvLine.RowID1)
            else
                ServPostingJnlsMgt.CollectValueEntryRelation(TempValueEntryRelation, ServCrMemoLine.RowID1);
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
        if ServLine2.FindFirst then
            Error(
              Text035, ServLine2.FieldCaption("Line No."),
              ServLine2."Line No.", ServLedgEntry.TableCaption, CurrentServLine."Line No.");

        if CurrentServLine."Document Type" = CurrentServLine."Document Type"::Invoice then
            if ServLedgEntry.Get(CurrentServLine."Appl.-to Service Entry") and
               (ServLedgEntry.Open = false) and
               ((ServLedgEntry."Document Type" = ServLedgEntry."Document Type"::Invoice) or
                (ServLedgEntry."Document Type" = ServLedgEntry."Document Type"::"Credit Memo"))
            then
                Error(
                  Text039, ServLine2.FieldCaption("Line No."), CurrentServLine."Line No.",
                  Format(ServLine2."Document Type"), ServHeader."No.",
                  ServLedgEntry.TableCaption);

        if (CurrentServLine."Contract No." <> '') and
           (CurrentServLine."Shipment No." = '') and
           (CurrentServLine."Document Type" <> CurrentServLine."Document Type"::Order)
        then begin
            SetServiceLedgerEntryFilters(ServLedgEntry, CurrentServLine."Contract No.");
            if not ServLedgEntry.IsEmpty and (ServHeader."Contract No." <> '') then
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
            until Next = 0;
        exit(ApplServLedgEntryNo);
    end;

    local procedure CheckDimComb(ServiceLine: Record "Service Line")
    begin
        if ServiceLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(ServHeader."Dimension Set ID") then
                Error(Text028,
                  ServHeader."Document Type", ServHeader."No.", DimMgt.GetDimCombErr);

        if ServiceLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(ServiceLine."Dimension Set ID") then
                Error(Text029,
                  ServHeader."Document Type", ServHeader."No.", ServiceLine."Line No.", DimMgt.GetDimCombErr);

        OnAfterCheckDimComb(ServHeader, ServiceLine);
    end;

    local procedure CheckDimValuePosting(var ServiceLine2: Record "Service Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        OnBeforeCheckDimValuePosting(ServiceLine2);

        if ServiceLine2."Line No." = 0 then begin
            TableIDArr[1] := DATABASE::Customer;
            NumberArr[1] := ServHeader."Bill-to Customer No.";
            TableIDArr[2] := DATABASE::"Salesperson/Purchaser";
            NumberArr[2] := ServHeader."Salesperson Code";
            TableIDArr[3] := DATABASE::"Responsibility Center";
            NumberArr[3] := ServHeader."Responsibility Center";
            TableIDArr[4] := DATABASE::"Service Order Type";
            NumberArr[4] := ServHeader."Service Order Type";

            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ServHeader."Dimension Set ID") then
                Error(
                  Text030,
                  ServHeader."Document Type", ServHeader."No.", DimMgt.GetDimValuePostingErr);
        end else begin
            TableIDArr[1] := DimMgt.TypeToTableID5(ServiceLine2.Type.AsInteger());
            NumberArr[1] := ServiceLine2."No.";
            TableIDArr[2] := DATABASE::Job;
            NumberArr[2] := ServiceLine2."Job No.";

            TableIDArr[3] := DATABASE::"Responsibility Center";
            NumberArr[3] := ServiceLine2."Responsibility Center";

            if ServiceLine2."Service Item Line No." <> 0 then begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", ServiceLine2."Document Type");
                ServItemLine.SetRange("Document No.", ServiceLine2."Document No.");
                ServItemLine.SetRange("Line No.", ServiceLine2."Service Item Line No.");
                if ServItemLine.Find('-') then begin
                    TableIDArr[4] := DATABASE::"Service Item";
                    NumberArr[4] := ServItemLine."Service Item No.";
                    TableIDArr[5] := DATABASE::"Service Item Group";
                    NumberArr[5] := ServItemLine."Service Item Group Code";
                end;
                ServItemLine.Reset();
            end;

            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ServiceLine2."Dimension Set ID") then
                Error(Text031,
                  ServHeader."Document Type", ServHeader."No.", ServiceLine2."Line No.", DimMgt.GetDimValuePostingErr);
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
                    until PassedConsume or (ServLine.Next = 0);
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
                    until PassedInvoice or (ServLine.Next = 0);
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
                        if ServDocType = DATABASE::"Service Contract Header" then
                            TestField("Contract No.");
                        if ServDocType = DATABASE::"Service Header" then
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

                    if not (Ship or ServAmountsMgt.RoundingLineInserted) then begin
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
                        if Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice) then begin
                            "Qty. to Consume" := 0;
                            "Qty. to Consume (Base)" := 0;
                            InitQtyToInvoice;
                        end
                    end else begin
                        "Qty. to Invoice" := 0;
                        "Qty. to Invoice (Base)" := 0;
                    end;

                    if Consume then begin
                        if Abs("Qty. to Consume") > Abs(MaxQtyToConsume) then begin
                            "Qty. to Consume" := MaxQtyToConsume;
                            "Qty. to Consume (Base)" := MaxQtyToConsumeBase;
                        end;
                    end else begin
                        "Qty. to Consume" := 0;
                        "Qty. to Consume (Base)" := 0;
                    end;

                    Modify;
                end;

            until ServLine.Next = 0;
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
        if ServiceItemLineTemp.FindSet then
            repeat
                ServiceLineTemp.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                ServiceLineTemp.SetRange("Document Type", ServiceItemLineTemp."Document Type");
                ServiceLineTemp.SetRange("Document No.", ServiceItemLineTemp."Document No.");
                ServiceLineTemp.SetRange("Service Item No.", ServiceItemLineTemp."Service Item No.");
                if not ServiceLineTemp.FindFirst then
                    ServiceItemClosedCondition := false
            until (ServiceItemLineTemp.Next = 0) or (not ServiceItemClosedCondition);
        exit(QtyClosedCondition and ServiceItemClosedCondition);
    end;

    local procedure CheckSysCreatedEntry()
    begin
        with ServLine do
            if ServHeader."Document Type" = ServHeader."Document Type"::Invoice then begin
                Reset;
                SetRange("System-Created Entry", false);
                SetFilter(Quantity, '<>0');
                if not Find('-') then
                    Error(Text001);
                Reset;
            end;
    end;

    local procedure CheckShippingAdvice()
    begin
        if ServHeader."Shipping Advice" = ServHeader."Shipping Advice"::Complete then
            with ServLine do
                if FindSet then
                    repeat
                        if IsShipment then begin
                            if not GetShippingAdvice then
                                Error(Text023);
                            exit;
                        end;
                    until Next = 0;
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
                             StrSubstNo(Text015, TableCaption, FieldCaption("Service Price Group Code")), true)
                        then
                            Error('');
            Reset;
        end;
    end;

    procedure IsCloseConditionMet(): Boolean
    begin
        exit(CloseCondition);
    end;

    procedure SetNoSeries(var PServHeader: Record "Service Header"): Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ModifyHeader: Boolean;
    begin
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
            Modify;

            if ModifyHeader then begin
                PServHeader."Shipping No." := "Shipping No.";
                PServHeader."Posting No." := "Posting No.";
            end;
        end;
        exit(ModifyHeader);
    end;

    procedure SetLastNos(var PServHeader: Record "Service Header")
    begin
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

    local procedure SetGenJnlLineDocNos(DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[35])
    begin
        OnBeforeSetGenJnlLineDocNosHandler(ServHeader, DocType, DocNo, ExtDocNo);
        OnBeforeSetGenJnlLineDocNumbers(ServHeader, DocType, DocNo, ExtDocNo);

        GenJnlLineDocType := DocType;
        GenJnlLineDocNo := DocNo;
        GenJnlLineExtDocNo := ExtDocNo;
        ServPostingJnlsMgt.SetGenJnlLineDocNos(GenJnlLineDocNo, GenJnlLineExtDocNo);
    end;

    [Obsolete('Replaced by OnBeforeSetGenJnlLineDocNumbers', '16.0')]
    local procedure OnBeforeSetGenJnlLineDocNosHandler(var ServiceHeader: Record "Service Header"; var DocType: Integer; var DocNo: Code[20]; var ExtDocNo: Code[35])
    var
        ShortExtDocNo: Code[20];
    begin
        ShortExtDocNo := CopyStr(ExtDocNo, 1, MaxStrLen(ShortExtDocNo));
        OnBeforeSetGenJnlLineDocNos(ServHeader, DocType, DocNo, ShortExtDocNo);
        if ShortExtDocNo <> CopyStr(ExtDocNo, 1, MaxStrLen(ShortExtDocNo)) then
            ExtDocNo := ShortExtDocNo;
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
                        EndLoop := (TempInvoicingSpecification.Next = 0)
                    else
                        EndLoop :=
                          (ServiceShptLine.Next = 0) or
                          ((Invoice and (Abs(RemQtyToBeInvoiced) <= Abs(ServiceLine."Qty. to Ship"))) or
                           (Consume and (Abs(RemQtyToBeConsumed) <= Abs(ServiceLine."Qty. to Ship"))));
                until EndLoop;
            end else
                if ServiceLine."Shipment Line No." <> 0 then
                    Error(Text026, ServiceLine."Shipment Line No.", ServiceLine."Shipment No.")
                else
                    Error(Text001);
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
    begin
        CalcInvDiscAmt := false;
        with ServLine do begin
            if Find('-') then
                repeat
                    if Quantity <> 0 then begin
                        OldInvDiscountAmount := "Inv. Discount Amount";

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

                        InitOutstanding;
                        InitQtyToShip;

                        if "Inv. Discount Amount" <> OldInvDiscountAmount then
                            CalcInvDiscAmt := true;

                        Modify;
                    end;
                until Next = 0;

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
                        InitQtyToInvoice;
                        InitOutstanding;
                        Modify;
                    end;

            until ServLine.Next = 0;
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
        if ServLine2.FindSet then
            repeat
                if ServLine2.IsShipment then begin
                    if ServLine2."Document Type" <> ServLine2."Document Type"::"Credit Memo" then
                        if ServLine2."Quantity (Base)" <>
                           ServLine2."Qty. to Ship (Base)" + ServLine2."Qty. Shipped (Base)"
                        then
                            exit(false);
                end;
            until ServLine2.Next = 0;
        exit(true);
    end;

    local procedure RemoveLinesNotSatisfyPosting()
    var
        ServLine2: Record "Service Line";
        IsHandled: Boolean;
    begin
        // Find ServLines not selected to post, and check if they were completely posted
        if ServLine.FindFirst then begin
            ServLine2.SetRange("Document Type", ServHeader."Document Type");
            ServLine2.SetRange("Document No.", ServHeader."No.");
            ServLine2.FindSet;
            if ServLine.Count <> ServLine2.Count then
                repeat
                    if not ServLine.Get(ServLine2."Document Type", ServLine2."Document No.", ServLine2."Line No.") then
                        if ServLine2.Quantity <> ServLine2."Quantity Invoiced" + ServLine2."Quantity Consumed" then
                            CloseCondition := false;
                until (ServLine2.Next = 0) or (not CloseCondition);
        end;
        // Remove ServLines that do not meet the posting conditions from the selected to post lines
        with ServLine do
            if FindSet then
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
                        if ((Type <> Type::" ") and (Description = '') and ("No." = '')) or
                           ((Type <> Type::" ") and (Description <> '') and ("No." <> ''))
                        then begin
                            ServLine2 := ServLine;
                            if ServLine2.Find() then begin
                                IsHandled := false;
                                OnRemoveLinesNotSatisfyPostingOnBeforeInitRemainingServLine(ServLine2, IsHandled);
                                if not IsHandled then begin
                                    ServLine2.InitOutstanding();
                                    ServLine2.InitQtyToShip();
                                    ServLine2.Modify();
                                end;
                            end;
                            DeleteWithAttachedLines;
                        end;
                    end;
                until Next = 0;
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

    local procedure FinalizeWarrantyLedgerEntries(var ServiceHeader: Record "Service Header"; CloseCondition: Boolean)
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.Reset();
        WarrantyLedgerEntry.SetCurrentKey("Service Order No.", "Posting Date", "Document No.");
        WarrantyLedgerEntry.SetRange("Service Order No.", ServiceHeader."No.");
        if WarrantyLedgerEntry.IsEmpty then
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
            UpdateTempWarrantyLedgerEntry;
            UpdWarrantyLedgEntriesFromTemp;
        until ServLine.Next = 0;
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
        until WarrantyLedgerEntryPar.Next = 0;
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
        until (TempWarrantyLedgerEntry.Next = 0) or (ServLineInvoicedConsumedQty <= 0);
        TempWarrantyLedgerEntry.Find('-');
        repeat
            TempWarrantyLedgerEntry.Open := TempWarrantyLedgerEntry.Quantity > 0;
            TempWarrantyLedgerEntry.Modify();
        until (TempWarrantyLedgerEntry.Next = 0);
    end;

    local procedure FindMinimumNumber(DecimalNumber1: Decimal; DecimalNumber2: Decimal): Decimal
    begin
        if DecimalNumber1 < DecimalNumber2 then
            exit(DecimalNumber1);
        exit(DecimalNumber2);
    end;

    local procedure SortLines(var ServLine: Record "Service Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        OnBeforeSortLines(ServLine);

        GLSetup.Get();
        if GLSetup.OptimGLEntLockForMultiuserEnv then
            ServLine.SetCurrentKey("Document Type", "Document No.", Type, "No.")
        else
            ServLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
    end;

    local procedure UpdateServiceLedgerEntry(ServLedgEntryNo: Integer)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.Get(ServLedgEntryNo);
        ServiceLedgerEntry."Job Posted" := true;
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
        until TempWarrantyLedgerEntry.Next = 0;
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyServiceDocNoSeries(var ServHeader: Record "Service Header"; PServHeader: Record "Service Header"; ModifyHeader: Boolean)
    begin
    end;

    procedure CollectTrackingSpecification(var TempTargetTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        TempTrackingSpecification.Reset();
        TempTargetTrackingSpecification.Reset();
        TempTargetTrackingSpecification.DeleteAll();

        if TempTrackingSpecification.FindSet then
            repeat
                TempTargetTrackingSpecification := TempTrackingSpecification;
                TempTargetTrackingSpecification.Insert();
            until TempTrackingSpecification.Next = 0;
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
    local procedure OnAfterFinalizeCrMemoDocument(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeInvoiceDocument(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeShipmentDocument(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var CloseCondition: Boolean; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
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
    local procedure OnAfterPrepareInvoiceHeader(var ServiceInvHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
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
    local procedure OnBeforeFinalize(var ServiceHeader: Record "Service Header"; var CloseCondition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeCrMemoDocument(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeInvoiceDocument(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeShipmentDocument(var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var CloseCondition: Boolean)
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
    [Obsolete('Replaced by OnBeforeSetGenJnlLineDocNumbers', '16.0')]
    local procedure OnBeforeSetGenJnlLineDocNos(var ServiceHeader: Record "Service Header"; var DocType: Integer; var DocNo: Code[20]; var ExtDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGenJnlLineDocNumbers(var ServiceHeader: Record "Service Header"; var DocType: Integer; var DocNo: Code[20]; var ExtDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortLines(var ServiceLine: Record "Service Line")
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
    local procedure OnPostDocumentLinesOnAfterFillInvPostingBuffer(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforeCheckServLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Ship: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforePostInvoicePostBuffer(ServiceHeader: Record "Service Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line")
    begin
    end;

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
    local procedure OnPrepareDocumentOnPServLineLoopOnBeforeServLineInsert(var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceLedgerEntryFilters(var ServLedgEntry: Record "Service Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(var ServiceLine2: Record "Service Line")
    begin
    end;
}

