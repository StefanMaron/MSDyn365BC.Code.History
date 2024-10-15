#if not CLEAN17
report 6655 "Batch Post Sales Return Orders"
{
    Caption = 'Batch Post Sales Return Orders (Obsolete)';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST("Return Order"));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Sales Return Order';

            trigger OnPreDataItem()
            var
                SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
            begin
                OnBeforeSalesHeaderOnPreDataItem("Sales Header", ReceiveReq, InvReq);

                if ReplaceVATDate and (VATDateReq = 0D) then
                    Error(EnterVATDateErr);

                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDate);
                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::"VAT Date", VATDateReq);

                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::Receive, ReceiveReq);
                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::Print, PrintDoc);
                SalesBatchPostMgt.RunBatch("Sales Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, InvReq);

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
                    field(ReceiveReq; ReceiveReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Receive';
                        ToolTip = 'Specifies if the orders are received when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(InvReq; InvReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies if the orders are invoiced when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the document date or the posting date when you post if you select the Replace Document Date check box or the Replace Posting Date check box.';

                        trigger OnValidate()
                        begin
                            VATDateReq := PostingDateReq; // NAVCZ
                        end;
                    }
                    field(VATDate; VATDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Date';
                        ToolTip = 'Specifies VAT Date for posting.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                        ObsoleteTag = '17.4';
                        Visible = UseVATDate;
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the orders with the date that is entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the orders with the date in the Posting Date field.';
                    }
                    field(ReplaceVATDate; ReplaceVATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace VAT Date';
                        ToolTip = 'Specifies if the new VAT date will be applied.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                        ObsoleteTag = '17.4';
                        Visible = UseVATDate;
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = SalesReturnOrder;
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
                        ToolTip = 'Specifies if you want to print the return order after posting. In the Report Output Type field on the Sales & Receivables page, you define if the report will be printed or output as a PDF.';

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
        begin
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
                exit;
            SalesReceivablesSetup.Get();
            CalcInvDisc := SalesReceivablesSetup."Calc. Inv. Discount";
            ReplacePostingDate := false;
            ReplaceDocumentDate := false;
            PrintDoc := false;
            PrintDocVisible := SalesReceivablesSetup."Post & Print with Job Queue";
            SetControlVisibility; // NAVCZ
        end;
    }

    labels
    {
    }

    var
        Text003: Label 'The exchange rate associated with the new posting date on the sales header will not apply to the sales lines.';
        PostingDateReq: Date;
        VATDateReq: Date;
        ReceiveReq: Boolean;
        InvReq: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        ReplaceVATDate: Boolean;
        [InDataSet]
        UseVATDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        [InDataSet]
        PrintDocVisible: Boolean;
        EnterVATDateErr: Label 'Enter the VAT date.';

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // NAVCZ
        GLSetup.Get();
        UseVATDate := GLSetup."Use VAT Date";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderOnPreDataItem(var SalesHeader: Record "Sales Header"; var ReceiveReq: Boolean; var InvReq: Boolean)
    begin
    end;
}
#endif