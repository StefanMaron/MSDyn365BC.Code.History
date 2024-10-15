report 295 "Combine Shipments"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Combine Shipments';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(SalesOrderHeader; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order), "Combine Shipments" = CONST(true));
            RequestFilterFields = "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Sales Order';
            dataitem("Sales Shipment Header"; "Sales Shipment Header")
            {
                DataItemLink = "Order No." = FIELD("No.");
                DataItemTableView = SORTING("Order No.");
                RequestFilterFields = "Posting Date";
                RequestFilterHeading = 'Posted Sales Shipment';
                dataitem("Sales Shipment Line"; "Sales Shipment Line")
                {
                    DataItemLink = "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeSalesShipmentLineOnAfterGetRecord("Sales Shipment Line", IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if Type = Type::" " then begin
                            if (not CopyTextLines) or ("Attached to Line No." <> 0) then
                                CurrReport.Skip();
                        end;

                        if "Authorized for Credit Card" then
                            CurrReport.Skip();

                        if ("Qty. Shipped Not Invoiced" <> 0) or (Type = Type::" ") then begin
                            if ("Bill-to Customer No." <> Cust."No.") and
                               ("Sell-to Customer No." <> '')
                            then
                                Cust.Get("Bill-to Customer No.");
                            if not (Cust.Blocked in [Cust.Blocked::All, Cust.Blocked::Invoice]) then begin
                                if ShouldFinalizeSalesInvHeader(SalesOrderHeader, SalesHeader, "Sales Shipment Line") then begin
                                    if SalesHeader."No." <> '' then
                                        FinalizeSalesInvHeader;
                                    InsertSalesInvHeader;
                                    SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                                    SalesLine.SetRange("Document No.", SalesHeader."No.");
                                    SalesLine."Document Type" := SalesHeader."Document Type";
                                    SalesLine."Document No." := SalesHeader."No.";
                                end;
                                SalesShptLine := "Sales Shipment Line";
                                HasAmount := HasAmount or ("Qty. Shipped Not Invoiced" <> 0);
                                SalesShptLine.InsertInvLineFromShptLine(SalesLine);
                            end else
                                NoOfSalesInvErrors := NoOfSalesInvErrors + 1;
                        end;
                    end;

                    trigger OnPostDataItem()
                    var
                        SalesShipmentLine: Record "Sales Shipment Line";
                        SalesLineInvoice: Record "Sales Line";
                        SalesGetShpt: Codeunit "Sales-Get Shipment";
                    begin
                        SalesShipmentLine.SetRange("Document No.", "Document No.");
                        SalesShipmentLine.SetRange(Type, Type::"Charge (Item)");
                        if SalesShipmentLine.FindSet then
                            repeat
                                SalesLineInvoice.SetRange("Document Type", SalesLineInvoice."Document Type"::Invoice);
                                SalesLineInvoice.SetRange("Document No.", SalesHeader."No.");
                                SalesLineInvoice.SetRange("Shipment Line No.", SalesShipmentLine."Line No.");
                                if SalesLineInvoice.FindFirst then
                                    SalesGetShpt.GetItemChargeAssgnt(SalesShipmentLine, SalesLineInvoice."Qty. to Invoice");
                            until SalesShipmentLine.Next() = 0;
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    DueDate: Date;
                    PmtDiscDate: Date;
                    PmtDiscPct: Decimal;
                begin
                    Window.Update(3, "No.");

                    if IsCompletlyInvoiced then
                        CurrReport.Skip();

                    if OnlyStdPmtTerms then begin
                        Cust.Get("Bill-to Customer No.");
                        PaymentTermsLine.Reset();
                        PaymentTermsLine.SetRange("Sales/Purchase", PaymentSales."Sales/Purchase"::" ");
                        PaymentTermsLine.SetRange(Type, PaymentTermsLine.Type::"Payment Terms");
                        PaymentTermsLine.SetRange(Code, Cust."Payment Terms Code");
                        if PaymentTermsLine.Find('-') then
                            repeat
                                if PaymentTermsLine.Code = "Sales Shipment Header"."Payment Terms Code" then begin
                                    PaymentSales.Get(PaymentSales."Sales/Purchase"::Sales, PaymentTermsLine.Type::Order,
                                      "Sales Shipment Header"."Order No.", '', 0, PaymentTermsLine."Line No.");
                                    DueDate := CalcDate(PaymentTermsLine."Due Date Calculation", "Document Date");
                                    PmtDiscDate := CalcDate(PaymentTermsLine."Discount Date Calculation", "Document Date");
                                    PmtDiscPct := PaymentTermsLine."Discount %";
                                    if (DueDate <> PaymentSales."Due Date") or
                                       (PmtDiscDate <> PaymentSales."Pmt. Discount Date") or
                                       (PmtDiscPct <> PaymentSales."Discount %")
                                    then begin
                                        NoOfskippedShiment := NoOfskippedShiment + 1;
                                        CurrReport.Skip();
                                    end;
                                end else begin
                                    NoOfskippedShiment := NoOfskippedShiment + 1;
                                    CurrReport.Skip();
                                end;
                            until PaymentTermsLine.Next() = 0;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    "Sales Shipment Header".SetRange("Operation Occurred Date");
                end;

                trigger OnPreDataItem()
                begin
                    "Sales Shipment Header".SetRange("Operation Occurred Date", OperationDateFrom, OperationDateTo);
                end;
            }

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnAfterGetRecordSalesOrderHeader(SalesOrderHeader, IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                Window.Update(1, "Bill-to Customer No.");
                Window.Update(2, "No.");
            end;

            trigger OnPostDataItem()
            begin
                CurrReport.Language := GlobalLanguage;
                Window.Close;
                if SalesHeader."No." <> '' then begin // Not the first time
                    FinalizeSalesInvHeader;
                    if (NoOfSalesInvErrors = 0) and not HideDialog then begin
                        if NoOfskippedShiment > 0 then
                            Message(
                              Text011,
                              NoOfSalesInv, NoOfskippedShiment)
                        else
                            Message(
                              Text010,
                              NoOfSalesInv);
                    end else
                        if not HideDialog then
                            if PostInv then
                                Message(
                                  Text007,
                                  NoOfSalesInvErrors)
                            else
                                Message(
                                  NotAllInvoicesCreatedMsg,
                                  NoOfSalesInvErrors)
                end else
                    if not HideDialog then
                        Message(Text008);
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Operation Type") <> '' then
                    Error(MissingFilterErr, FieldName("Operation Type"));
                SetCurrentKey(
                    "Sell-to Customer No.", "Bill-to Customer No.", "Currency Code", "Payment Terms Code",
                    "Payment Method Code", "Salesperson Code", "EU 3-Party Trade");
                SetRange("Operation Type", OperationType.Code);

                if OperationDateFrom = 0D then
                    Error(InsertDateErr, OperationDateFromTxt);
                if OperationDateTo = 0D then
                    Error(InsertDateErr, OperationDateToTxt);

                LocalAppMgt.CheckSameMonth(OperationDateFrom, OperationDateTo);
                LocalAppMgt.CheckData(OperationDateFrom, OperationDateTo, OperationDateFromTxt, OperationDateToTxt);

                if PostingDateReq = 0D then
                    Error(Text000);
                if DocDateReq = 0D then
                    Error(Text001);
                LocalAppMgt.CheckData(DocDateReq, PostingDateReq, DocumentDateTxt, PostingDateTxt);
                Window.Open(
                  Text002 +
                  Text003 +
                  Text004 +
                  Text005);

                OnSalesOrderHeaderOnPreDataItem(SalesOrderHeader);
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
                    field(CombineFromDate; OperationDateFrom)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine From Date';
                        ToolTip = 'Specifies the start date for combining shipments.';
                    }
                    field(CombineToDate; OperationDateTo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine To Date';
                        ToolTip = 'Specifies the end date for combining shipments.';
                    }
                    field(OperationType; OperationType.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        TableRelation = "No. Series" WHERE("No. Series Type" = FILTER(Sales | Purchase));
                        ToolTip = 'Specifies the type of sales or purchase.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the invoice(s) that the batch job creates. This field must be filled in.';
                    }
                    field(DocDateReq; DocDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date for the invoice(s) that the batch job creates. This field must be filled in.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the shipment.';

                        trigger OnValidate()
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PostInv; PostInv)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Invoices';
                        ToolTip = 'Specifies if you want to have the invoices posted immediately.';
                    }
                    field(OnlyStdPmtTerms; OnlyStdPmtTerms)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Std. Payment Terms';
                        ToolTip = 'Specifies if you want to include shipments with standard payments terms. If you select this option, you must manually invoice all other shipments.';
                    }
                    field(CopyTextLines; CopyTextLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy Text Lines';
                        ToolTip = 'Specifies if you want manually written text on the shipment lines to be copied to the invoice.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDateReq = 0D then
                PostingDateReq := WorkDate;
            if DocDateReq = 0D then
                DocDateReq := WorkDate;
            SalesSetup.Get();
            CalcInvDisc := SalesSetup."Calc. Inv. Discount";
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnBeforePostReport;
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport;
    end;

    var
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document date.';
        Text002: Label 'Combining shipments...\\';
        Text003: Label 'Customer No.    #1##########\';
        Text004: Label 'Order No.       #2##########\';
        Text005: Label 'Shipment No.    #3##########';
        Text007: Label 'Not all the invoices were posted. A total of %1 invoices were not posted.';
        Text008: Label 'There is nothing to combine.';
        Text010: Label 'The shipments are now combined and the number of invoices created is %1.';
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        SalesSetup: Record "Sales & Receivables Setup";
        Cust: Record Customer;
        Language: Codeunit Language;
        SalesCalcDisc: Codeunit "Sales-Calc. Discount";
        SalesPost: Codeunit "Sales-Post";
        Window: Dialog;
        PostingDateReq: Date;
        DocDateReq: Date;
        CalcInvDisc: Boolean;
        PostInv: Boolean;
        OnlyStdPmtTerms: Boolean;
        HasAmount: Boolean;
        HideDialog: Boolean;
        NoOfSalesInvErrors: Integer;
        NoOfSalesInv: Integer;
        Text011: Label 'The shipments are now combined, and the number of invoices created is %1.\%2 Shipments with nonstandard payment terms have not been combined.', Comment = '%1-Number of invoices,%2-Number Of shipments';
        InsertDateErr: Label 'Insert the %1 date.', Comment = '%1 = Field Name';
        OperationDateFromTxt: Label 'Combine Shipments From';
        OperationDateToTxt: Label 'Combine Shipments To';
        PostingDateTxt: Label 'Posting Date';
        DocumentDateTxt: Label 'Document Date';
        MissingFilterErr: Label 'The filter on %1 must be specified in the request form.', Comment = '%1 = Field';
        OperationType: Record "No. Series";
        PaymentTermsLine: Record "Payment Lines";
        PaymentSales: Record "Payment Lines";
        LocalAppMgt: Codeunit LocalApplicationManagement;
        OperationDateFrom: Date;
        OperationDateTo: Date;
        NoOfskippedShiment: Integer;
        CopyTextLines: Boolean;
        NotAllInvoicesCreatedMsg: Label 'Not all the invoices were created. A total of %1 invoices were not created.';

    local procedure FinalizeSalesInvHeader()
    var
        HasError: Boolean;
    begin
        HasError := false;
        OnBeforeFinalizeSalesInvHeader(SalesHeader, HasAmount, HasError);
        if HasError then
            NoOfSalesInvErrors += 1;

        with SalesHeader do begin
            if (not HasAmount) or HasError then begin
                OnFinalizeSalesInvHeaderOnBeforeDelete(SalesHeader);
                Delete(true);
                OnFinalizeSalesInvHeaderOnAfterDelete(SalesHeader);
                exit;
            end;
            OnFinalizeSalesInvHeader(SalesHeader);
            if CalcInvDisc then
                SalesCalcDisc.Run(SalesLine);
            Find;
            Commit();
            Clear(SalesCalcDisc);
            Clear(SalesPost);
            NoOfSalesInv := NoOfSalesInv + 1;
            if PostInv then begin
                Clear(SalesPost);
                if not SalesPost.Run(SalesHeader) then
                    NoOfSalesInvErrors := NoOfSalesInvErrors + 1;
            end;
        end;
    end;

    local procedure InsertSalesInvHeader()
    begin
        Clear(SalesHeader);
        with SalesHeader do begin
            Init;
            "Document Type" := "Document Type"::Invoice;
            "No." := '';
            OnBeforeSalesInvHeaderInsert(SalesHeader, SalesOrderHeader);
            Insert(true);
            Validate("Sell-to Customer No.", SalesOrderHeader."Sell-to Customer No.");
            Validate("Bank Account", SalesOrderHeader."Bank Account");
            Validate("Operation Type", OperationType.Code);
            Validate("Activity Code", SalesOrderHeader."Activity Code");
            Validate("Bill-to Customer No.", SalesOrderHeader."Bill-to Customer No.");
            Validate("Posting Date", PostingDateReq);
            Validate("Document Date", DocDateReq);
            Validate("Currency Code", SalesOrderHeader."Currency Code");
            Validate("Payment Terms Code", SalesOrderHeader."Payment Terms Code");
            Validate("Payment Method Code", SalesOrderHeader."Payment Method Code");
            Validate("EU 3-Party Trade", SalesOrderHeader."EU 3-Party Trade");
            Validate("Salesperson Code", SalesOrderHeader."Salesperson Code");
            Validate("Fattura Project Code", SalesOrderHeader."Fattura Project Code");
            Validate("Fattura Tender Code", SalesOrderHeader."Fattura Tender Code");
            "Salesperson Code" := SalesOrderHeader."Salesperson Code";
            "Shortcut Dimension 1 Code" := SalesOrderHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := SalesOrderHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := SalesOrderHeader."Dimension Set ID";
            OnBeforeSalesInvHeaderModify(SalesHeader, SalesOrderHeader);
            Modify;
            Commit();
            HasAmount := false;
        end;

        OnAfterInsertSalesInvHeader(SalesHeader, "Sales Shipment Header");
    end;

    procedure InitializeRequest(NewPostingDate: Date; NewDocDate: Date; NewCalcInvDisc: Boolean; NewPostInv: Boolean; NewOnlyStdPmtTerms: Boolean; NewCopyTextLines: Boolean)
    begin
        PostingDateReq := NewPostingDate;
        DocDateReq := NewDocDate;
        CalcInvDisc := NewCalcInvDisc;
        PostInv := NewPostInv;
        OnlyStdPmtTerms := NewOnlyStdPmtTerms;
        CopyTextLines := NewCopyTextLines;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure ShouldFinalizeSalesInvHeader(SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; SalesShipmentLine: Record "Sales Shipment Line") Finalize: Boolean
    begin
        Finalize :=
          (SalesOrderHeader."Sell-to Customer No." <> SalesHeader."Sell-to Customer No.") or
          (SalesOrderHeader."Bill-to Customer No." <> SalesHeader."Bill-to Customer No.") or
          (SalesOrderHeader."Currency Code" <> SalesHeader."Currency Code") or
          (SalesOrderHeader."EU 3-Party Trade" <> SalesHeader."EU 3-Party Trade") or
          (SalesOrderHeader."Dimension Set ID" <> SalesHeader."Dimension Set ID") or
          (SalesOrderHeader."Salesperson Code" <> SalesHeader."Salesperson Code") or
          (SalesOrderHeader."Payment Terms Code" <> SalesHeader."Payment Terms Code") or
          (SalesOrderHeader."Payment Method Code" <> SalesHeader."Payment Method Code") or
          (SalesOrderHeader."Activity Code" <> SalesHeader."Activity Code") or
          (SalesOrderHeader."Bank Account" <> SalesHeader."Bank Account") or
          (SalesOrderHeader."Fattura Project Code" <> SalesHeader."Fattura Project Code") or
          (SalesOrderHeader."Fattura Tender Code" <> SalesHeader."Fattura Tender Code");

        OnAfterShouldFinalizeSalesInvHeader(SalesOrderHeader, SalesHeader, Finalize, SalesShipmentLine);
        exit(Finalize);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesInvHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeSalesInvHeader(var SalesHeader: Record "Sales Header"; var HasAmount: Boolean; var HasError: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvHeaderModify(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShipmentLineOnAfterGetRecord(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeSalesInvHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeSalesInvHeaderOnAfterDelete(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeSalesInvHeaderOnBeforeDelete(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesOrderHeaderOnPreDataItem(var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldFinalizeSalesInvHeader(var SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; var Finalize: Boolean; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;
}

