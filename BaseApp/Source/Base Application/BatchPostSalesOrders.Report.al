report 296 "Batch Post Sales Orders"
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
                BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
                SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
            begin
                SalesBatchPostMgt.AddParameter(BatchPostParameterTypes.Print, PrintDoc);
                SalesBatchPostMgt.RunBatch("Sales Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, ShipReq, InvReq);

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
                    field(Ship; ShipReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ship';
                        ToolTip = 'Specifies whether the orders will be shipped when posted. If you place a check in the box, it will apply to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies whether the orders will be invoiced when posted. If you place a check in the box, it will apply to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';
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
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the sales orders'' document date with the date in the Posting Date field.';
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
                            SalesReceivablesSetup.Get;
                            SalesReceivablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the order after posting. In the Report Output Type field on the Sales & Receivables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            if PrintDoc then begin
                                SalesReceivablesSetup.Get;
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
        begin
            SalesReceivablesSetup.Get;
            CalcInvDisc := SalesReceivablesSetup."Calc. Inv. Discount";
            ReplacePostingDate := false;
            ReplaceDocumentDate := false;
            PrintDoc := false;
        end;
    }

    labels
    {
    }

    var
        Text003: Label 'The exchange rate associated with the new posting date on the sales header will not apply to the sales lines.';
        ShipReq: Boolean;
        InvReq: Boolean;
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        Text1130000: Label 'The %1 and %2 may be modified automatically if they are greater than the %3.';

    procedure InitializeRequest(ShipParam: Boolean; InvoiceParam: Boolean; PostingDateParam: Date; ReplacePostingDateParam: Boolean; ReplaceDocumentDateParam: Boolean; CalcInvDiscParam: Boolean)
    begin
        ShipReq := ShipParam;
        InvReq := InvoiceParam;
        PostingDateReq := PostingDateParam;
        ReplacePostingDate := ReplacePostingDateParam;
        ReplaceDocumentDate := ReplaceDocumentDateParam;
        CalcInvDisc := CalcInvDiscParam;
    end;
}

