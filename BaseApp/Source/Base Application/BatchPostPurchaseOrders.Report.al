report 496 "Batch Post Purchase Orders"
{
    Caption = 'Batch Post Purchase Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Purchase Order';

            trigger OnPreDataItem()
            var
                BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
                PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
            begin
                OnBeforePurchaseBatchPostMgt("Purchase Header", ReceiveReq, InvReq);

                PurchaseBatchPostMgt.AddParameter(BatchPostParameterTypes.Print, PrintDoc);
                PurchaseBatchPostMgt.RunBatch(
                  "Purchase Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, ReceiveReq, InvReq);

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
                    field(Receive; ReceiveReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Receive';
                        ToolTip = 'Specifies whether the purchase orders will be received when posted. If you place a check mark in the box, it will apply to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies whether the purchase orders will be invoiced when posted. If you place a check mark in the box, it will apply to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the orders'' posting date with the date entered in the field above.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the purchase orders'' document date with the date in the Posting Date field.';
                    }
                    field(CalcInvDiscount; CalcInvDisc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        var
                            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                        begin
                            PurchasesPayablesSetup.Get();
                            PurchasesPayablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the order after posting. In the Report Output Type field on the Purchases and Payables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                        begin
                            if PrintDoc then begin
                                PurchasesPayablesSetup.Get();
                                if PurchasesPayablesSetup."Post with Job Queue" then
                                    PurchasesPayablesSetup.TestField("Post & Print with Job Queue");
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
            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        begin
            PurchasesPayablesSetup.Get();
            CalcInvDisc := PurchasesPayablesSetup."Calc. Inv. Discount";
            PrintDoc := false;
            PrintDocVisible := PurchasesPayablesSetup."Post & Print with Job Queue";
        end;
    }

    labels
    {
    }

    var
        Text003: Label 'The exchange rate associated with the new posting date on the purchase header will not apply to the purchase lines.';
        ReceiveReq: Boolean;
        InvReq: Boolean;
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        [InDataSet]
        PrintDocVisible: Boolean;

    procedure InitializeRequest(NewReceiveReq: Boolean; NewInvReq: Boolean; NewPostingDateReq: Date; NewReplacePostingDate: Boolean; NewReplaceDocumentDate: Boolean; NewCalcInvDisc: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        ReceiveReq := NewReceiveReq;
        InvReq := NewInvReq;
        PostingDateReq := NewPostingDateReq;
        ReplacePostingDate := NewReplacePostingDate;
        ReplaceDocumentDate := NewReplaceDocumentDate;
        if NewCalcInvDisc then
            PurchasesPayablesSetup.TestField("Calc. Inv. Discount", false);
        CalcInvDisc := NewCalcInvDisc;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseBatchPostMgt(var PurchaseHeader: Record "Purchase Header"; var ReceiveReq: Boolean; var InvReq: Boolean)
    begin
    end;
}

