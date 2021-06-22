codeunit 5987 "Serv-Posting Journals Mgt."
{
    Permissions = TableData "Invoice Post. Buffer" = imd;

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
        TimeSheetMgt: Codeunit "Time Sheet Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[20];
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
        SrcCodeSetup.Get;
        SalesSetup.Get;
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

    procedure SetGenJnlLineDocNos(DocNo: Code[20]; ExtDocNo: Code[20])
    begin
        GenJnlLineDocNo := DocNo;
        GenJnlLineExtDocNo := ExtDocNo;
    end;

    local procedure IsWarehouseShipment(ServiceLine: Record "Service Line"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        with WarehouseShipmentLine do begin
            SetRange("Source Type", DATABASE::"Service Line");
            SetRange("Source Subtype", 1);
            SetRange("Source No.", ServiceLine."Document No.");
            SetRange("Source Line No.", ServiceLine."Line No.");
            exit(not IsEmpty);
        end;
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
    begin
        Clear(ItemJnlPostLine);
        if not ItemJnlRollRndg then begin
            RemAmt := 0;
            RemDiscAmt := 0;
        end;

        with ItemJnlLine do begin
            Init;
            CopyFromServHeader(ServiceHeader);
            CopyFromServLine(ServiceLine);

            CopyTrackingFromSpec(TrackingSpecification);

            if QtyToBeShipped = 0 then begin
                if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                    "Document Type" := "Document Type"::"Service Credit Memo"
                else
                    "Document Type" := "Document Type"::"Service Invoice";
                if QtyToBeConsumed <> 0 then begin
                    "Entry Type" := "Entry Type"::"Negative Adjmt.";
                    "Document No." := ServShptLineDocNo;
                    "External Document No." := '';
                    "Document Type" := "Document Type"::"Service Shipment";
                end else begin
                    "Document No." := GenJnlLineDocNo;
                    "External Document No." := GenJnlLineExtDocNo;
                end;
                "Posting No. Series" := ServiceHeader."Posting No. Series";
            end else begin
                if ServiceLine."Document Type" <> ServiceLine."Document Type"::"Credit Memo" then begin
                    "Document Type" := "Document Type"::"Service Shipment";
                    "Document No." := ServShptHeader."No.";
                    "Posting No. Series" := ServShptHeader."No. Series";
                end;
                if (QtyToBeInvoiced <> 0) or (QtyToBeConsumed <> 0) then begin
                    if QtyToBeConsumed <> 0 then
                        "Entry Type" := "Entry Type"::"Negative Adjmt.";
                    "Invoice No." := GenJnlLineDocNo;
                    "External Document No." := GenJnlLineExtDocNo;
                    if "Document No." = '' then begin
                        if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                            "Document Type" := "Document Type"::"Service Credit Memo"
                        else
                            "Document Type" := "Document Type"::"Service Invoice";
                        "Document No." := GenJnlLineDocNo;
                    end;
                    "Posting No. Series" := ServiceHeader."Posting No. Series";
                end;
                if (QtyToBeConsumed <> 0) and ("Document No." = '') then
                    "Document No." := ServShptLineDocNo;
            end;

            "Document Line No." := ServiceLine."Line No.";
            Quantity := -QtyToBeShipped;
            "Quantity (Base)" := -QtyToBeShippedBase;
            if QtyToBeInvoiced <> 0 then begin
                "Invoiced Quantity" := -QtyToBeInvoiced;
                "Invoiced Qty. (Base)" := -QtyToBeInvoicedBase;
            end else
                if QtyToBeConsumed <> 0 then begin
                    "Invoiced Quantity" := -QtyToBeConsumed;
                    "Invoiced Qty. (Base)" := -QtyToBeConsumedBase;
                end;
            "Unit Cost" := ServiceLine."Unit Cost (LCY)";
            "Source Currency Code" := ServiceHeader."Currency Code";
            "Unit Cost (ACY)" := ServiceLine."Unit Cost";
            "Value Entry Type" := "Value Entry Type"::"Direct Cost";
            "Applies-from Entry" := ServiceLine."Appl.-from Item Entry";

            if Invoice and (QtyToBeInvoiced <> 0) then begin
                Amount := -(ServiceLine.Amount * (QtyToBeInvoiced / ServiceLine."Qty. to Invoice") - RemAmt);
                if ServiceHeader."Prices Including VAT" then
                    "Discount Amount" :=
                      -((ServiceLine."Line Discount Amount" + ServiceLine."Inv. Discount Amount") / (1 + ServiceLine."VAT %" / 100) *
                        (QtyToBeInvoiced / ServiceLine."Qty. to Invoice") - RemDiscAmt)
                else
                    "Discount Amount" :=
                      -((ServiceLine."Line Discount Amount" + ServiceLine."Inv. Discount Amount") *
                        (QtyToBeInvoiced / ServiceLine."Qty. to Invoice") - RemDiscAmt);
            end else
                if Consume and (QtyToBeConsumed <> 0) then begin
                    Amount := -(ServiceLine.Amount * QtyToBeConsumed - RemAmt);
                    "Discount Amount" :=
                      -(ServiceLine."Line Discount Amount" * QtyToBeConsumed - RemDiscAmt);
                end;

            if (QtyToBeInvoiced <> 0) or (QtyToBeConsumed <> 0) then begin
                RemAmt := Amount - Round(Amount);
                RemDiscAmt := "Discount Amount" - Round("Discount Amount");
                Amount := Round(Amount);
                "Discount Amount" := Round("Discount Amount");
            end else begin
                if ServiceHeader."Prices Including VAT" then
                    Amount :=
                      -((QtyToBeShipped *
                         ServiceLine."Unit Price" * (1 - ServiceLine."Line Discount %" / 100) / (1 + ServiceLine."VAT %" / 100)) - RemAmt)
                else
                    Amount :=
                      -((QtyToBeShipped * ServiceLine."Unit Price" * (1 - ServiceLine."Line Discount %" / 100)) - RemAmt);
                RemAmt := Amount - Round(Amount);
                if ServiceHeader."Currency Code" <> '' then
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          ServiceLine."Posting Date", ServiceHeader."Currency Code",
                          Amount, ServiceHeader."Currency Factor"))
                else
                    Amount := Round(Amount);
            end;

            "Source Code" := SrcCode;
            "Item Shpt. Entry No." := ItemLedgShptEntryNo;
            "Invoice-to Source No." := ServiceLine."Bill-to Customer No.";

            if SalesSetup."Exact Cost Reversing Mandatory" and (ServiceLine.Type = ServiceLine.Type::Item) then
                if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                    CheckApplFromItemEntry := ServiceLine.Quantity > 0
                else
                    CheckApplFromItemEntry := ServiceLine.Quantity < 0;

            if (ServiceLine."Location Code" <> '') and (ServiceLine.Type = ServiceLine.Type::Item) and (Quantity <> 0) then begin
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

            exit("Item Shpt. Entry No.");
        end;
    end;

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; ServLine: Record "Service Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; Location: Record Location)
    var
        WMSMgmt: Codeunit "WMS Management";
        WhseMgt: Codeunit "Whse. Management";
    begin
        with ServLine do begin
            WMSMgmt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
            WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, false);
            TempWhseJnlLine."Source Type" := DATABASE::"Service Line";
            TempWhseJnlLine."Source Subtype" := "Document Type";
            TempWhseJnlLine."Source Code" := SrcCode;
            TempWhseJnlLine."Source Document" := WhseMgt.GetSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
            TempWhseJnlLine."Source No." := "Document No.";
            TempWhseJnlLine."Source Line No." := "Line No.";
            case "Document Type" of
                "Document Type"::Order:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Shipment";
                "Document Type"::Invoice:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted S. Inv.";
                "Document Type"::"Credit Memo":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted S. Cr. Memo";
            end;
            TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        end;
    end;

    local procedure PostWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
    begin
        ServITRMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
        if TempWhseJnlLine2.Find('-') then
            repeat
                WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next = 0;
    end;

    procedure PostInvoicePostBufferLine(var InvoicePostBuffer: Record "Invoice Post. Buffer"; DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntryNo: Integer;
    begin
        with GenJnlLine do begin
            InitNewLine(
              ServiceLinePostingDate, ServiceHeader."Document Date", InvoicePostBuffer."Entry Description",
              InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code",
              InvoicePostBuffer."Dimension Set ID", ServiceHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, '');

            CopyFromServiceHeader(ServiceHeader);
            CopyFromInvoicePostBuffer(InvoicePostBuffer);
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;

            OnBeforePostInvoicePostBuffer(GenJnlLine, InvoicePostBuffer, ServiceHeader, GenJnlPostLine);
            GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostInvoicePostBuffer(GenJnlLine, InvoicePostBuffer, ServiceHeader, GLEntryNo, GenJnlPostLine);
        end;
    end;

    procedure PostCustomerEntry(var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              ServiceLinePostingDate, ServiceHeader."Document Date", ServiceHeader."Posting Description",
              ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
              ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, '');

            "Account Type" := "Account Type"::Customer;
            "Account No." := ServiceHeader."Bill-to Customer No.";
            CopyFromServiceHeader(ServiceHeader);
            SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

            CopyFromServiceHeaderApplyTo(ServiceHeader);
            CopyFromServiceHeaderPayment(ServiceHeader);

            Amount := -TotalServiceLine."Amount Including VAT";
            "Source Currency Amount" := -TotalServiceLine."Amount Including VAT";
            "Amount (LCY)" := -TotalServiceLineLCY."Amount Including VAT";
            "Sales/Purch. (LCY)" := -TotalServiceLineLCY.Amount;
            "Profit (LCY)" := -(TotalServiceLineLCY.Amount - TotalServiceLineLCY."Unit Cost (LCY)");
            "Inv. Discount (LCY)" := -TotalServiceLineLCY."Inv. Discount Amount";
            "System-Created Entry" := true;

            OnBeforePostCustomerEntry(GenJnlLine, ServiceHeader, TotalServiceLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostCustomerEntry(GenJnlLine, ServiceHeader, GenJnlPostLine);
        end;
    end;

    procedure PostBalancingEntry(var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; DocType: Integer; DocNo: Code[20]; ExtDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CustLedgEntry.FindLast;
        with GenJnlLine do begin
            InitNewLine(
              ServiceLinePostingDate, ServiceHeader."Document Date", ServiceHeader."Posting Description",
              ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
              ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

            if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
                CopyDocumentFields("Document Type"::Refund, DocNo, ExtDocNo, SrcCode, '')
            else
                CopyDocumentFields("Document Type"::Payment, DocNo, ExtDocNo, SrcCode, '');

            "Account Type" := "Account Type"::Customer;
            "Account No." := ServiceHeader."Bill-to Customer No.";
            CopyFromServiceHeader(ServiceHeader);
            SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

            SetApplyToDocNo(ServiceHeader, GenJnlLine, DocType, DocNo);

            Amount := TotalServiceLine."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            CustLedgEntry.CalcFields(Amount);
            if CustLedgEntry.Amount = 0 then
                "Amount (LCY)" := TotalServiceLineLCY."Amount Including VAT"
            else
                "Amount (LCY)" :=
                  TotalServiceLineLCY."Amount Including VAT" +
                  Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");

            OnBeforePostBalancingEntry(GenJnlLine, ServiceHeader, TotalServiceLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostBalancingEntry(GenJnlLine, ServiceHeader, GenJnlPostLine);
        end;
    end;

    local procedure SetApplyToDocNo(ServiceHeader: Record "Service Header"; var GenJnlLine: Record "Gen. Journal Line"; DocType: Option; DocNo: Code[20])
    begin
        with GenJnlLine do begin
            if ServiceHeader."Bal. Account Type" = ServiceHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := ServiceHeader."Bal. Account No.";
            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;
        end;
    end;

    procedure PostResJnlLineShip(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[20])
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        if ServiceLine."Time Sheet No." <> '' then
            TimeSheetMgt.CheckServiceLine(ServiceLine);

        PostResJnlLine(
          ServiceHeader, ServiceLine,
          DocNo, ExtDocNo, SrcCode, ServiceHeader."Posting No. Series",
          ResJnlLine."Entry Type"::Usage, -ServiceLine."Qty. to Ship",
          ServiceLine.Amount / ServiceLine."Qty. to Ship", -ServiceLine.Amount);

        TimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, GenJnlLineDocNo, true);
    end;

    procedure PostResJnlLineUndoUsage(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[20])
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        PostResJnlLine(
          ServiceHeader, ServiceLine,
          DocNo, ExtDocNo, SrcCode, ServiceHeader."Posting No. Series",
          ResJnlLine."Entry Type"::Usage, -ServiceLine."Qty. to Invoice",
          ServiceLine.Amount / ServiceLine."Qty. to Invoice", -ServiceLine.Amount);
    end;

    procedure PostResJnlLineSale(var ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[20])
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
    begin
        if ServiceLine."Time Sheet No." <> '' then
            TimeSheetMgt.CheckServiceLine(ServiceLine);

        PostResJnlLine(
          ServiceHeader, ServiceLine,
          ServShptHeader."No.", '', SrcCode, ServShptHeader."No. Series",
          ResJnlLine."Entry Type"::Usage, -ServiceLine."Qty. to Consume", 0, 0);

        TimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, GenJnlLineDocNo, false);
    end;

    local procedure PostResJnlLine(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; DocNo: Code[20]; ExtDocNo: Code[35]; SrcCode: Code[10]; PostingNoSeries: Code[20]; EntryType: Option; Qty: Decimal; UnitPrice: Decimal; TotalPrice: Decimal)
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        with ResJnlLine do begin
            Init;
            CopyDocumentFields(DocNo, ExtDocNo, SrcCode, PostingNoSeries);
            CopyFromServHeader(ServiceHeader);
            CopyFromServLine(ServiceLine);

            "Entry Type" := EntryType;
            Quantity := Qty;
            "Unit Cost" := ServiceLine."Unit Cost (LCY)";
            "Total Cost" := ServiceLine."Unit Cost (LCY)" * Quantity;
            "Unit Price" := UnitPrice;
            "Total Price" := TotalPrice;

            OnBeforeResJnlPostLine(ResJnlLine, ServiceHeader, ServiceLine);
            ResJnlPostLine.RunWithCheck(ResJnlLine);
        end;
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
        TempValueEntryRelation.Reset;
        PassedValueEntryRelation.Reset;

        if TempValueEntryRelation.FindSet then
            repeat
                PassedValueEntryRelation := TempValueEntryRelation;
                PassedValueEntryRelation."Source RowId" := RowId;
                PassedValueEntryRelation.Insert;
            until TempValueEntryRelation.Next = 0;

        TempValueEntryRelation.DeleteAll;
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

        with ServLine do begin
            if ("Job No." = '') or (QtyToBeConsumed = 0) then
                exit(false);

            TestField("Job Task No.");
            Job.LockTable;
            JobTask.LockTable;
            Job.Get("Job No.");
            JobTask.Get("Job No.", "Job Task No.");

            JobJnlLine.Init;
            JobJnlLine.DontCheckStdCost;
            JobJnlLine.Validate("Job No.", "Job No.");
            JobJnlLine.Validate("Job Task No.", "Job Task No.");
            JobJnlLine.Validate("Line Type", "Job Line Type");
            JobJnlLine.Validate("Posting Date", "Posting Date");
            JobJnlLine."Job Posting Only" := true;
            JobJnlLine."No." := "No.";

            case Type of
                Type::"G/L Account":
                    JobJnlLine.Type := JobJnlLine.Type::"G/L Account";
                Type::Item:
                    JobJnlLine.Type := JobJnlLine.Type::Item;
                Type::Resource:
                    JobJnlLine.Type := JobJnlLine.Type::Resource;
                Type::Cost:
                    begin
                        ServiceCost.SetRange(Code, "No.");
                        ServiceCost.FindFirst;
                        JobJnlLine.Type := JobJnlLine.Type::"G/L Account";
                        JobJnlLine."No." := ServiceCost."Account No.";
                    end;
            end; // Case Type

            OnPostJobJnlLineOnBeforeValidateNo(JobJnlLine, ServLine);

            JobJnlLine.Validate("No.");
            JobJnlLine.Description := Description;
            JobJnlLine."Description 2" := "Description 2";
            JobJnlLine."Variant Code" := "Variant Code";
            JobJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            JobJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            JobJnlLine.Validate(Quantity, -QtyToBeConsumed);
            JobJnlLine."Document No." := ServHeader."Shipping No.";
            JobJnlLine."Service Order No." := "Document No.";
            JobJnlLine."External Document No." := ServHeader."Shipping No.";
            JobJnlLine."Posted Service Shipment No." := ServHeader."Shipping No.";
            if Type = Type::Item then begin
                Item.Get("No.");
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    JobJnlLine.Validate("Unit Cost (LCY)", Item."Standard Cost")
                else
                    JobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)")
            end else
                JobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");

            Currency.Initialize("Currency Code");
            Customer.Get("Customer No.");
            if Customer."Prices Including VAT" then
                Validate("Unit Price", Round("Unit Price" / (1 + ("VAT %" / 100)), Currency."Unit-Amount Rounding Precision"));

            if "Currency Code" = Job."Currency Code" then
                JobJnlLine.Validate("Unit Price", "Unit Price");
            if "Currency Code" <> '' then begin
                CurrencyFactor := CurrExchRate.ExchangeRate("Posting Date", "Currency Code");
                UnitPriceLCY :=
                  Round(CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", "Unit Price", CurrencyFactor),
                    Currency."Amount Rounding Precision");
                JobJnlLine.Validate("Unit Price (LCY)", UnitPriceLCY);
            end else
                JobJnlLine.Validate("Unit Price (LCY)", "Unit Price");

            JobJnlLine.Validate("Line Discount %", "Line Discount %");
            JobJnlLine."Job Planning Line No." := "Job Planning Line No.";
            JobJnlLine."Remaining Qty." := "Job Remaining Qty.";
            JobJnlLine."Remaining Qty. (Base)" := "Job Remaining Qty. (Base)";
            JobJnlLine."Location Code" := "Location Code";
            JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
            JobJnlLine."Posting Group" := "Posting Group";
            JobJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            JobJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            JobJnlLine."Customer Price Group" := "Customer Price Group";
            SourceCodeSetup.Get;
            JobJnlLine."Source Code" := SourceCodeSetup."Service Management";
            JobJnlLine."Work Type Code" := "Work Type Code";
            JobJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            JobJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            JobJnlLine."Dimension Set ID" := "Dimension Set ID";
            OnAfterTransferValuesToJobJnlLine(JobJnlLine, ServLine);
        end;

        JobJnlPostLine.RunWithCheck(JobJnlLine);
        exit(true);
    end;

    procedure SetPostingDate(PostingDate: Date)
    begin
        ServiceLinePostingDate := PostingDate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJournalLine: Record "Gen. Journal Line"; var ServiceHeader: Record "Service Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJournalLine: Record "Gen. Journal Line"; var ServiceHeader: Record "Service Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvoicePostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceHeader: Record "Service Header"; GLEntryNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValuesToJobJnlLine(var JobJournalLine: Record "Job Journal Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJournalLine: Record "Gen. Journal Line"; var ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoicePostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceHeader: Record "Service Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

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
    local procedure OnPostJobJnlLineOnBeforeValidateNo(var JobJournalLine: Record "Job Journal Line"; ServiceLine: Record "Service Line");
    begin
    end;
}

