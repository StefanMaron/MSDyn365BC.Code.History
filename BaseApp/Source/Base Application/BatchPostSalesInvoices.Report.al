#if not CLEAN17
report 297 "Batch Post Sales Invoices"
{
    Caption = 'Batch Post Sales Invoices (Obsolete)';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Invoice));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Sales Invoice';

            trigger OnPreDataItem()
            var
                SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
            begin
                OnBeforeSalesHeaderPreDataItem("Sales Header");

                if ReplaceVATDate and (VATDateReq = 0D) then
                    Error(EnterVATDateErr);

                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDate);
                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::"VAT Date", VATDateReq);

                SalesBatchPostMgt.SetParameter("Batch Posting Parameter Type"::Print, PrintDoc);
                SalesBatchPostMgt.RunBatch("Sales Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, true);

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
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';

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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the sales orders'' posting date with the date entered in the field above.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if the new document date will be applied.';
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the invoices before posting.';

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
                        ToolTip = 'Specifies if you want to print the invoice after posting. In the Report Output Type field on the Sales and Receivables page, you define if the report will be printed or output as a PDF.';

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
    local procedure OnBeforeSalesHeaderPreDataItem(var SalesHeader: Record "Sales Header")
    begin
    end;
}
#endif