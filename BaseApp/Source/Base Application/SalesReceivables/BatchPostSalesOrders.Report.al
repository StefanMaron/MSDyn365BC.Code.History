﻿report 296 "Batch Post Sales Orders"
{
    Caption = 'Batch Post Sales Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Sales Order';

            trigger OnPreDataItem()
            var
                SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeSalesBatchPostMgt("Sales Header", ShipReq, InvReq, SalesBatchPostMgt, IsHandled);
                if not IsHandled then begin
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Print, PrintDoc);
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDateReq);
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"VAT Date", VATDateReq);
                    SalesBatchPostMgt.RunBatch("Sales Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, ShipReq, InvReq);
                end;
                OnAfterSalesBatchPostMgt("Sales Header", SalesBatchPostMgt);
                CurrReport.Break();
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
                    field(Ship; ShipReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ship';
                        ToolTip = 'Specifies whether the orders will be shipped when posted. If you place a check in the box, it will apply to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PostInvoiceEditable;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies whether the orders will be invoiced when posted. If you place a check in the box, it will apply to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';

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
                        ToolTip = 'Specifies the date that the program will use as the VAT date when you post if you place a checkmark in Replace VAT Date.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if the new posting date will be applied.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then begin
                                Message(Text003);
                                Message(Text1130000, "Sales Header".FieldCaption("Document Date"), "Sales Header".FieldCaption("Operation Occurred Date"),
                                  "Sales Header".FieldCaption("Posting Date"));
                            end;

                            if VATReportingDateMgt.IsVATDateUsageSetToPostingDate() then
                                ReplaceVATDateReq := ReplacePostingDate;
                            UpdateVATDate();
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the sales orders'' document date with the date in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if VATReportingDateMgt.IsVATDateUsageSetToDocumentDate() then
                                ReplaceVATDateReq := ReplaceDocumentDate;
                            UpdateVATDate();
                        end;
                    }
                    field(ReplaceVATDate; ReplaceVATDateReq)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Replace VAT Date';
                        Editable = VATDateEnabled;
                        Visible = VATDateEnabled;
                        ToolTip = 'Specifies if you want to replace the sales orders'' VAT date with the date in the VAT Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            SalesReceivablesSetup.Get();
                            SalesReceivablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the order after posting. In the Report Output Type field on the Sales & Receivables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            if PrintDoc then begin
                                SalesReceivablesSetup.Get();
                                if SalesReceivablesSetup."Post with Job Queue" then
                                    SalesReceivablesSetup.TestField("Post & Print with Job Queue");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            SalesReceivablesSetup: Record "Sales & Receivables Setup";
            ClientTypeManagement: Codeunit "Client Type Management";
            UserSetupManagement: Codeunit "User Setup Management";
            Ship: Boolean;
            IsHandled: Boolean;
        begin
            IsHandled := false;
            OnBeforeOnOpenPage(IsHandled);
            if not IsHandled then
                if ClientTypeManagement.GetCurrentClientType() <> ClientType::Background then begin
                    SalesReceivablesSetup.Get();
                    CalcInvDisc := SalesReceivablesSetup."Calc. Inv. Discount";
                    ReplacePostingDate := false;
                    ReplaceDocumentDate := false;
                    PrintDoc := false;
                    PrintDocVisible := SalesReceivablesSetup."Post & Print with Job Queue";
                    VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
                    UserSetupManagement.GetSalesInvoicePostingPolicy(Ship, InvReq);
                    PostInvoiceEditable := not Ship;
                end;
            OnAfterOnOpenPage(ShipReq, InvReq, PostingDateReq, ReplacePostingDate, ReplaceDocumentDate, CalcInvDisc);
        end;
    }

    labels
    {
    }

    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        Text003: Label 'The exchange rate associated with the new posting date on the sales header will apply to the sales lines.';
        PrintDoc: Boolean;
        [InDataSet]
        PrintDocVisible: Boolean;
        Text1130000: Label 'The %1 and %2 may be modified automatically if they are greater than the %3.';
        VATDateEnabled: Boolean;
        PostInvoiceEditable: Boolean;

    protected var
        ShipReq: Boolean;
        InvReq: Boolean;
        PostingDateReq, VATDateReq: Date;
        ReplacePostingDate, ReplaceVATDateReq: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;

#if not CLEAN22
    [Obsolete('Replaced by InitializeRequest with VAT Date parameters.', '22.0')]
    procedure InitializeRequest(ShipParam: Boolean; InvoiceParam: Boolean; PostingDateParam: Date; ReplacePostingDateParam: Boolean; ReplaceDocumentDateParam: Boolean; CalcInvDiscParam: Boolean)
    begin
        ShipReq := ShipParam;
        InvReq := InvoiceParam;
        PostingDateReq := PostingDateParam;
        ReplacePostingDate := ReplacePostingDateParam;
        ReplaceDocumentDate := ReplaceDocumentDateParam;
        ReplaceVATDateReq := false;
        CalcInvDisc := CalcInvDiscParam;
    end;
#endif

    procedure InitializeRequest(ShipParam: Boolean; InvoiceParam: Boolean; PostingDateParam: Date; VATDateParam: Date; ReplacePostingDateParam: Boolean; ReplaceDocumentDateParam: Boolean; ReplaceVATDateParam: Boolean; CalcInvDiscParam: Boolean)
    begin
        ShipReq := ShipParam;
        InvReq := InvoiceParam;
        PostingDateReq := PostingDateParam;
        VATDateReq := VATDateParam;
        ReplacePostingDate := ReplacePostingDateParam;
        ReplaceDocumentDate := ReplaceDocumentDateParam;
        ReplaceVATDateReq := ReplaceVATDateParam; 
        CalcInvDisc := CalcInvDiscParam;
    end;

    local procedure UpdateVATDate()
    begin
        if ReplaceVATDateReq then
            VATDateReq := PostingDateReq;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var ShipReq: Boolean; var InvReq: Boolean; var PostingDateReq: Date; var ReplacePostingDate: Boolean; var ReplaceDocumentDate: Boolean; var CalcInvDisc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesBatchPostMgt(var SalesHeader: Record "Sales Header"; var ShipReq: Boolean; var InvReq: Boolean; var SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesBatchPostMgt(var SalesHeader: Record "Sales Header"; var SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.")
    begin
    end;
}

