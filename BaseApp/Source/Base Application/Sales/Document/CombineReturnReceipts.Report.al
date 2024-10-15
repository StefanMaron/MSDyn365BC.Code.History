namespace Microsoft.Sales.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using System.Globalization;
using Microsoft.Utilities;

report 6653 "Combine Return Receipts"
{
    ApplicationArea = SalesReturnOrder, PurchReturnOrder;
    Caption = 'Combine Return Receipts';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(SalesOrderHeader; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "Combine Shipments", "Bill-to Customer No.") where("Document Type" = const("Return Order"), "Combine Shipments" = const(true));
            RequestFilterFields = "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Sales Return Order';
            dataitem("Return Receipt Header"; "Return Receipt Header")
            {
                DataItemLink = "Return Order No." = field("No.");
                DataItemTableView = sorting("Return Order No.");
                RequestFilterFields = "Posting Date";
                RequestFilterHeading = 'Posted Return Receipts';
                dataitem("Return Receipt Line"; "Return Receipt Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemTableView = sorting("Document No.", "Line No.") where("Return Qty. Rcd. Not Invd." = filter(<> 0));

                    trigger OnAfterGetRecord()
                    var
                        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeReturnReceiptLineOnAfterGetRecord("Return Receipt Line", IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if "Return Qty. Rcd. Not Invd." <> 0 then begin
                            if "Bill-to Customer No." <> Cust."No." then
                                Cust.Get("Bill-to Customer No.");
                            if Cust.Blocked <> Cust.Blocked::All then begin
                                if ShouldFinalizeSalesInvHeader(SalesOrderHeader, SalesHeader, "Return Receipt Line") then begin
                                    if SalesHeader."No." <> '' then
                                        FinalizeSalesInvHeader();
                                    InsertSalesInvHeader();
                                    SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                                    SalesLine.SetRange("Document No.", SalesHeader."No.");
                                    SalesLine."Document Type" := SalesHeader."Document Type";
                                    SalesLine."Document No." := SalesHeader."No.";
                                end;
                                ReturnRcptLine := "Return Receipt Line";
                                ReturnRcptLine.InsertInvLineFromRetRcptLine(SalesLine);
                                if Type = Type::"Charge (Item)" then
                                    SalesGetReturnReceipts.GetItemChargeAssgnt("Return Receipt Line", SalesLine."Qty. to Invoice");
                            end else
                                NoOfSalesInvErrors := NoOfSalesInvErrors + 1;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Window.Update(3, "No.");
                end;

                trigger OnPostDataItem()
                begin
                    "Return Receipt Header".SetRange("Operation Occurred Date");
                end;

                trigger OnPreDataItem()
                begin
                    "Return Receipt Header".SetRange("Operation Occurred Date", OperationDateFrom, OperationDateTo);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := Language.GetFormatRegionOrDefault("Format Region");

                Window.Update(1, "Bill-to Customer No.");
                Window.Update(2, "No.");
            end;

            trigger OnPostDataItem()
            begin
                CurrReport.Language := ReportLanguage;
                Window.Close();
                ShowResult();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Operation Type") <> '' then
                    Error(Text1130009, FieldName("Operation Type"))
                else
                    SetRange("Operation Type", OperationType.Code);

                if OperationDateFrom = 0D then
                    Error('%1 %2', Text1130000, Text1130001);
                if OperationDateTo = 0D then
                    Error('%1 %2', Text1130000, Text1130002);

                LocalAppMgt.CheckSameMonth(OperationDateFrom, OperationDateTo);
                LocalAppMgt.CheckData(OperationDateFrom, OperationDateTo, Text1130001, Text1130002);


                if PostingDateReq = 0D then
                    Error(Text000);
                if DocDateReq = 0D then
                    Error(Text001);
                if VATDateReq = 0D then
                    Error(VATDateEmptyErr);

                LocalAppMgt.CheckData(PostingDateReq, DocDateReq, Text1130003, Text1130004);

                Window.Open(
                  Text002 +
                  Text003 +
                  Text004 +
                  Text005);

                OnAfterSalesOrderHeaderOnPreDataItem(SalesOrderHeader);
                ReportLanguage := CurrReport.Language();
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
                    field(OperationDateFrom; OperationDateFrom)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine From Date';
                        ToolTip = 'Specifies the start date for combining return receipts.';
                    }
                    field(OperationDateTo; OperationDateTo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine To Date';
                        ToolTip = 'Specifies the end date for combining return receipts.';
                    }
                    field("OperationType.Code"; OperationType.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        TableRelation = "No. Series" where("No. Series Type" = filter(Sales | Purchase));
                        ToolTip = 'Specifies the type of sales or purchase.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the credit memo(s) that the batch job creates.';

                        trigger OnValidate()
                        begin
                            UpdateVATDate();
                        end;
                    }
                    field(DocDateReq; DocDateReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date for the credit memo(s) that the batch job creates. This field must be filled in.';

                        trigger OnValidate()
                        begin
                            UpdateVATDate();
                        end;
                    }
                    field(VATDate; VATDateReq)
                    {
                        ApplicationArea = VAT;
                        Caption = 'VAT Date';
                        Editable = VATDateEnabled;
                        Visible = VATDateEnabled;
                        ToolTip = 'Specifies the VAT date for the credit memo(s) that the batch job creates. This field must be filled in.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discounts calculated automatically.';

                        trigger OnValidate()
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PostInv; PostInv)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Credit Memos';
                        ToolTip = 'Specifies if you want to have the credit memos posted immediately.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        begin
            if PostingDateReq = 0D then
                PostingDateReq := WorkDate();
            if DocDateReq = 0D then
                DocDateReq := WorkDate();
            if VATDateReq = 0D then
                VATDateReq := GLSetup.GetVATDate(PostingDateReq, DocDateReq);

            SalesSetup.Get();
            CalcInvDisc := SalesSetup."Calc. Inv. Discount";
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        end;
    }

    labels
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesSetup: Record "Sales & Receivables Setup";
        Cust: Record Customer;
        Language: Codeunit Language;
        SalesCalcDisc: Codeunit "Sales-Calc. Discount";
        SalesPost: Codeunit "Sales-Post";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        HideDialog: Boolean;
        NoOfSalesInvErrors: Integer;
        NoOfSalesInv: Integer;
        OperationType: Record "No. Series";
        LocalAppMgt: Codeunit LocalApplicationManagement;
        OperationDateFrom: Date;
        OperationDateTo: Date;
        ReportLanguage: Integer;
        Text1130000: Label 'Insert the Date ';
        Text1130001: Label '[Combine Return Receipts From]';
        Text1130002: Label '[Combine Return Receipts To]';
        Text1130003: Label '[Posting]';
        Text1130004: Label '[Document]';
        Text1130009: Label 'The filter on %1 must be specified in the request form.';

        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document date.';
        Text002: Label 'Combining return receipts...\\';
        Text003: Label 'Customer No.        #1##########\';
        Text004: Label 'Return Order No.    #2##########\';
        Text005: Label 'Return Receipt No.  #3##########';
        Text007: Label 'Not all the credit memos were posted. A total of %1 credit memos were not posted.';
        Text008: Label 'There is nothing to combine.';
        Text010: Label 'The return receipts are now combined and the number of credit memos created is %1.';
        VATDateEmptyErr: Label 'Enter the VAT date.';

    protected var
        PostingDateReq: Date;
        DocDateReq: Date;
        VATDateReq: Date;
        CalcInvDisc: Boolean;
        PostInv: Boolean;
        VATDateEnabled: Boolean;

    local procedure FinalizeSalesInvHeader()
    var
        ShouldPostInv: Boolean;
    begin
        OnBeforeFinalizeSalesInvHeader(SalesHeader);

        with SalesHeader do begin
            if CalcInvDisc then
                SalesCalcDisc.Run(SalesLine);
            Find();
            Commit();
            Clear(SalesCalcDisc);
            Clear(SalesPost);
            NoOfSalesInv := NoOfSalesInv + 1;
            ShouldPostInv := PostInv;
            OnFinalizeSalesInvHeaderOnAfterCalcShouldPostInv(SalesHeader, NoOfSalesInv, ShouldPostInv);
            if ShouldPostInv then begin
                Clear(SalesPost);
                if not SalesPost.Run(SalesHeader) then
                    NoOfSalesInvErrors := NoOfSalesInvErrors + 1;
            end;
        end;
    end;

    local procedure InsertSalesInvHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertSalesInvHeader(SalesHeader, SalesOrderHeader, "Return Receipt Header", "Return Receipt Line", NoOfSalesInv, IsHandled);
        if not IsHandled then
            with SalesHeader do begin
                Init();
                "Document Type" := "Document Type"::"Credit Memo";
                "No." := '';

                OnBeforeSalesCrMemoHeaderInsert(SalesHeader, SalesOrderHeader);

                Insert(true);
                ValidateCustomerNoFromOrder(SalesHeader, SalesOrderHeader);
                Validate("Operation Type", OperationType.Code);
                Validate("Activity Code", SalesOrderHeader."Activity Code");
                Validate("Currency Code", SalesOrderHeader."Currency Code");
                Validate("Posting Date", PostingDateReq);
                Validate("Document Date", DocDateReq);
                Validate("VAT Reporting Date", VATDateReq);

                Validate("Payment Terms Code", SalesOrderHeader."Payment Terms Code");
                Validate("Payment Method Code", SalesOrderHeader."Payment Method Code");
                Validate("Salesperson Code", SalesOrderHeader."Salesperson Code");

                "Shortcut Dimension 1 Code" := SalesOrderHeader."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := SalesOrderHeader."Shortcut Dimension 2 Code";
                "Dimension Set ID" := SalesOrderHeader."Dimension Set ID";
                OnBeforeSalesCrMemoHeaderModify(SalesHeader, SalesOrderHeader);

                Modify();
                Commit();
            end;

        OnAfterInsertSalesInvHeader(SalesHeader, "Return Receipt Header");
    end;

    local procedure ValidateCustomerNoFromOrder(var ToSalesHeader: Record "Sales Header"; FromSalesOrderHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCustomerNoFromOrder(ToSalesHeader, FromSalesOrderHeader, "Return Receipt Header", "Return Receipt Line", IsHandled);
        if IsHandled then
            exit;

        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesOrderHeader."Bill-to Customer No.");
        if ToSalesHeader."Bill-to Customer No." <> ToSalesHeader."Sell-to Customer No." then
            ToSalesHeader.Validate("Bill-to Customer No.", FromSalesOrderHeader."Bill-to Customer No.");
    end;

    procedure InitializeRequest(NewOperationDateFrom: Date; NewOperationDateTo: Date; NewOperationTypeCode: Code[20]; NewPostingDate: Date; NewDocumentDate: Date; NewCalcInvDisc: Boolean; NewPostCreditMemo: Boolean)
    begin
        OperationDateFrom := NewOperationDateFrom;
        OperationDateTo := NewOperationDateTo;
        OperationType.Code := NewOperationTypeCode;
        PostingDateReq := NewPostingDate;
        DocDateReq := NewDocumentDate;
        VATDateReq := GLSetup.GetVATDate(PostingDateReq, DocDateReq);
        CalcInvDisc := NewCalcInvDisc;
        PostInv := NewPostCreditMemo;
    end;

    procedure InitializeRequest(NewOperationDateFrom: Date; NewOperationDateTo: Date; NewOperationTypeCode: Code[20]; NewPostingDate: Date; NewDocumentDate: Date; NewVATDate: Date; NewCalcInvDisc: Boolean; NewPostCreditMemo: Boolean)
    begin
        InitializeRequest(NewOperationDateFrom, NewOperationDateTo, NewOperationTypeCode, NewPostingDate, NewDocumentDate, NewCalcInvDisc, NewPostCreditMemo);
        VATDateReq := NewVATDate;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure ShowResult()
    begin
        OnBeforeShowResult(SalesHeader, NoOfSalesInvErrors, PostInv);

        if SalesHeader."No." <> '' then begin // Not the first time
            FinalizeSalesInvHeader();
            OnReturnReceiptHeaderOnAfterFinalizeSalesInvHeader(SalesHeader, NoOfSalesInvErrors, PostInv, HideDialog);
            if not HideDialog then
                if NoOfSalesInvErrors = 0 then
                    Message(Text010, NoOfSalesInv)
                else
                    Message(Text007, NoOfSalesInvErrors)
        end else
            if not HideDialog then
                Message(Text008);
    end;

    local procedure ShouldFinalizeSalesInvHeader(SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; ReturnReceiptLine: Record "Return Receipt Line") Finalize: Boolean
    begin
        Finalize :=
          (SalesOrderHeader."Bill-to Customer No." <> SalesHeader."Bill-to Customer No.") or
          (SalesOrderHeader."Currency Code" <> SalesHeader."Currency Code") or
          (SalesOrderHeader."Dimension Set ID" <> SalesHeader."Dimension Set ID") or
          (SalesOrderHeader."Salesperson Code" <> SalesHeader."Salesperson Code") or
          (SalesOrderHeader."Payment Terms Code" <> SalesHeader."Payment Terms Code") or
          (SalesOrderHeader."Payment Method Code" <> SalesHeader."Payment Method Code") or
          (SalesOrderHeader."Activity Code" <> SalesHeader."Activity Code");

        OnAfterShouldFinalizeSalesInvHeader(SalesOrderHeader, SalesHeader, Finalize, ReturnReceiptLine, "Return Receipt Header");
        exit(Finalize);
    end;

    local procedure UpdateVATDate()
    begin
        VATDateReq := GLSetup.GetVATDate(PostingDateReq, DocDateReq);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesInvHeader(var SalesHeader: Record "Sales Header"; var ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesOrderHeaderOnPreDataItem(var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldFinalizeSalesInvHeader(var SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; var Finalize: Boolean; ReturnReceiptLine: Record "Return Receipt Line"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeSalesInvHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesInvHeader(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header"; ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; var NoOfSalesInv: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnReceiptLineOnAfterGetRecord(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoHeaderModify(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowResult(var SalesHeader: Record "Sales Header"; var NoOfSalesInvErrors: Integer; PostInv: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerNoFromOrder(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header"; ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeSalesInvHeaderOnAfterCalcShouldPostInv(var SalesHeader: Record "Sales Header"; var NoOfSalesInv: Integer; var ShouldPostInv: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReturnReceiptHeaderOnAfterFinalizeSalesInvHeader(var SalesHeader: Record "Sales Header"; var NoOfSalesCrMemoErrors: Integer; PostInv: Boolean; HideDialog: Boolean)
    begin
    end;
}