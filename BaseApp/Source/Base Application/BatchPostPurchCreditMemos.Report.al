report 498 "Batch Post Purch. Credit Memos"
{
    Caption = 'Batch Post Purch. Credit Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST("Credit Memo"));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Purchase Credit Memo';

            trigger OnPreDataItem()
            var
                BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
                PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
            begin
                if ReplaceVATDate and (VATDateReq = 0D) then
                    Error(EnterVATDateErr);

                PurchaseBatchPostMgt.AddParameter(BatchPostParameterTypes.ReplaceVATDate, ReplaceVATDate);
                PurchaseBatchPostMgt.AddParameter(BatchPostParameterTypes.VATDate, VATDateReq);

                PurchaseBatchPostMgt.AddParameter(BatchPostParameterTypes.Print, PrintDoc);
                PurchaseBatchPostMgt.RunBatch("Purchase Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, false);

                CurrReport.Break;
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
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post, if you place a check mark in one or both of the fields below.';

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
                        Visible = UseVATDate;
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the credit memo with the date entered in the Posting/Document Date field.';

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
                        ToolTip = 'Specifies if you want to replace the document date of the credit memo with the date in the Posting/Document Date field.';
                    }
                    field(ReplaceVATDate; ReplaceVATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace VAT Date';
                        ToolTip = 'Specifies if the new VAT date will be applied.';
                        Visible = UseVATDate;
                    }
                    field(CalcInvDiscount; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies whether the inventory discount should be calculated.';

                        trigger OnValidate()
                        var
                            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                        begin
                            PurchasesPayablesSetup.Get;
                            PurchasesPayablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the credit memo after posting. In the Report Output Type field on the Purchases and Payables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                        begin
                            if PrintDoc then begin
                                PurchasesPayablesSetup.Get;
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
            PurchasesPayablesSetup.Get;
            CalcInvDisc := PurchasesPayablesSetup."Calc. Inv. Discount";
            PrintDoc := false;

            SetControlVisibility; // NAVCZ
        end;
    }

    labels
    {
    }

    var
        Text003: Label 'The exchange rate associated with the new posting date on the purchase header will not apply to the purchase lines.';
        PostingDateReq: Date;
        VATDateReq: Date;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        ReplaceVATDate: Boolean;
        [InDataSet]
        UseVATDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        EnterVATDateErr: Label 'Enter the VAT date.';

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // NAVCZ
        GLSetup.Get;
        UseVATDate := GLSetup."Use VAT Date";
    end;
}

