report 6004 "Batch Post Service Invoices"
{
    Caption = 'Batch Post Service Invoices';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Invoice));
            RequestFilterFields = "No.", Status, Priority;

            trigger OnAfterGetRecord()
            begin
                if CalcInvDisc then
                    CalculateInvoiceDiscount();

                Counter := Counter + 1;
                Window.Update(1, "No.");
                Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
                Clear(ServPost);
                ServPost.SetPostingDate(ReplacePostingDate, ReplaceDocumentDate, PostingDateReq);
                ServPost.SetPostingOptions(true, false, true); // ship, consume, invoice
                if ServPost.Run("Service Header") then begin
                    CounterOK := CounterOK + 1;
                    if MarkedOnly then
                        Mark(false);
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
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
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program uses as the document or posting date if you select the Replace Posting Date check box or the Replace Document Date check box or both check boxes.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the service invoices with the date that you entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the service invoices with the date in the Posting Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Service;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the invoices before posting.';

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
        var
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
                exit;
            SalesSetup.Get();
            CalcInvDisc := SalesSetup."Calc. Inv. Discount";
            ReplacePostingDate := false;
            ReplaceDocumentDate := false;
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
        OnBeforePreReport();
    end;

    var
        ServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ServCalcDisc: Codeunit "Service-Calc. Discount";
        ServPost: Codeunit "Service-Post";
        Window: Dialog;
        PostingDateReq: Date;
        CounterTotal: Integer;
        Counter: Integer;
        CounterOK: Integer;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;

        Text000: Label 'Enter the posting date.';
        Text001: Label 'Posting invoices   #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 invoices out of a total of %2 have now been posted.';
        Text003: Label 'The exchange rate associated with the new posting date on the service header will not apply to the service lines.';

    local procedure CalculateInvoiceDiscount()
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Service Header"."Document Type");
        ServLine.SetRange("Document No.", "Service Header"."No.");
        if ServLine.FindFirst() then
            if ServCalcDisc.Run(ServLine) then begin
                "Service Header".Get("Service Header"."Document Type", "Service Header"."No.");
                Commit();
            end;
    end;

    procedure InitializeRequest(PostingDateReqFrom: Date; ReplacePostingDateFrom: Boolean; ReplaceDocumentDateFrom: Boolean; CalcInvDiscFrom: Boolean)
    begin
        PostingDateReq := PostingDateReqFrom;
        ReplacePostingDate := ReplacePostingDateFrom;
        ReplaceDocumentDate := ReplaceDocumentDateFrom;
        CalcInvDisc := CalcInvDiscFrom;
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostReport(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePreReport()
    begin
    end;
}

