report 6001 "Batch Post Service Orders"
{
    Caption = 'Batch Post Service Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", Status, Priority;

            trigger OnAfterGetRecord()
            begin
                if CalcInvDisc then
                    CalculateInvoiceDiscount;

                Counter := Counter + 1;
                Window.Update(1, "No.");
                Window.Update(2, Round(Counter / CounterTotal * 10000, 1));

                if PostServiceHeader("Service Header") then begin
                    CounterOK := CounterOK + 1;
                    if MarkedOnly then
                        Mark(false);
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
                Message(Text002, CounterOK, CounterTotal);
            end;

            trigger OnPreDataItem()
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);
                CounterTotal := Count;
                Window.Open(Text001);
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
                        ApplicationArea = Service;
                        Caption = 'Ship';
                        ToolTip = 'Specifies if the orders are shipped when posted. When you select this check box, it applies to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Service;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies if the orders are invoiced when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that is to be used as the document date or the posting date when you post if you select the Replace Document Date check box or the Replace Posting Date check box.';
                    }
                    field(ReplacePostingDate_Option; ReplacePostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the service orders with the date that is entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);
                        end;
                    }
                    field(ReplaceDocumentDate_Option; ReplaceDocumentDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the service orders with the date in the Posting Date field.';
                    }
                    field(CalcInvDiscount; CalcInvDisc)
                    {
                        ApplicationArea = Service;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitValues;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnAfterPostReport("Service Header");
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport;
    end;

    var
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Posting orders  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 orders out of a total of %2 have now been posted.';
        Text003: Label 'The exchange rate associated with the new posting date on the service header will not apply to the service lines.';
        ServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ServCalcDisc: Codeunit "Service-Calc. Discount";
        ServPost: Codeunit "Service-Post";
        Window: Dialog;
        ShipReq: Boolean;
        InvReq: Boolean;
        PostingDateReq: Date;
        CounterTotal: Integer;
        Counter: Integer;
        CounterOK: Integer;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;

    local procedure CalculateInvoiceDiscount()
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Service Header"."Document Type");
        ServLine.SetRange("Document No.", "Service Header"."No.");
        if ServLine.FindFirst then
            if ServCalcDisc.Run(ServLine) then begin
                "Service Header".Get("Service Header"."Document Type", "Service Header"."No.");
                Commit();
            end;
    end;

    procedure InitializeRequest(ShipReqFrom: Boolean; InvReqFrom: Boolean; PostingDateReqFrom: Date; ReplacePostingDateFrom: Boolean; ReplaceDocumentDateFrom: Boolean; CalcInvDiscFrom: Boolean)
    begin
        InitValues;
        ShipReq := ShipReqFrom;
        InvReq := InvReqFrom;
        PostingDateReq := PostingDateReqFrom;
        ReplacePostingDate := ReplacePostingDateFrom;
        ReplaceDocumentDate := ReplaceDocumentDateFrom;
        if CalcInvDiscFrom then
            SalesSetup.TestField("Calc. Inv. Discount", false);
        CalcInvDisc := CalcInvDiscFrom;
    end;

    procedure InitValues()
    begin
        SalesSetup.Get();
        CalcInvDisc := SalesSetup."Calc. Inv. Discount";
        ReplacePostingDate := false;
        ReplaceDocumentDate := false;
    end;

    local procedure PostServiceHeader(var ServiceHeader: Record "Service Header"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostServiceHeader(ServiceHeader, IsHandled);
        if IsHandled then
            exit(true);

        Clear(ServPost);
        ServPost.SetPostingDate(ReplacePostingDate, ReplaceDocumentDate, PostingDateReq);
        ServPost.SetPostingOptions(ShipReq, false, InvReq);
        ServPost.SetHideValidationDialog(true);
        exit(ServPost.Run(ServiceHeader));
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostReport(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostServiceHeader(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePreReport()
    begin
    end;
}

