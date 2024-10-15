﻿report 6665 "Batch Post Purch. Ret. Orders"
{
    Caption = 'Batch Post Purch. Ret. Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST("Return Order"));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Purchase Return Order';

            trigger OnPreDataItem()
            var
                PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
            begin
                OnBeforePurchaseHeaderOnPreDataItem("Purchase Header", ShipReq, InvReq);

                PurchaseBatchPostMgt.SetParameter("Batch Posting Parameter Type"::Ship, ShipReq);
                PurchaseBatchPostMgt.SetParameter("Batch Posting Parameter Type"::Print, PrintDoc);
                PurchaseBatchPostMgt.RunBatch("Purchase Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, InvReq);

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
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Ship';
                        ToolTip = 'Specifies if the orders are shipped when posted. If you select this check box, it applies to all orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies if the orders are invoiced when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the document date or the posting date when you post if you select the Replace Document Date check box or the Replace Posting Date check box.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the orders with the date that is entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then begin
                                Message(Text003);
                                Message(Text1130000, "Purchase Header".FieldCaption("Document Date"), "Purchase Header".FieldCaption("Operation Occurred Date"),
                                  "Purchase Header".FieldCaption("Posting Date"));
                            end;
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the orders with the date in the Posting Date field.';
                    }
                    field(CalcInvDiscount; CalcInvDisc)
                    {
                        ApplicationArea = PurchReturnOrder;
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
                        ApplicationArea = Basic, Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the return order after posting. In the Report Output Type field on the Purchases and Payables page, you define if the report will be printed or output as a PDF.';

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
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
                exit;
            PurchasesPayablesSetup.Get();
            CalcInvDisc := PurchasesPayablesSetup."Calc. Inv. Discount";
            PrintDoc := false;
            PrintDocVisible := PurchasesPayablesSetup."Post & Print with Job Queue";

            OnAfterOnOpenPage(ShipReq, InvReq, PostingDateReq, ReplacePostingDate, ReplaceDocumentDate, CalcInvDisc);
        end;
    }

    labels
    {
    }

    var
        Text003: Label 'The exchange rate associated with the new posting date on the purchase header will not apply to the purchase lines.';
        Text1130000: Label 'The %1 and %2 may be modified automatically if they are greater than the %3.';

    protected var
        PostingDateReq: Date;
        ShipReq: Boolean;
        InvReq: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        [InDataSet]
        PrintDocVisible: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var ShipReq: Boolean; var InvReq: Boolean; var PostingDateReq: Date; var ReplacePostingDate: Boolean; var ReplaceDocumentDate: Boolean; var CalcInvDisc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderOnPreDataItem(var PurchaseHeader: Record "Purchase Header"; var ShipReq: Boolean; var InvReq: Boolean)
    begin
    end;
}

