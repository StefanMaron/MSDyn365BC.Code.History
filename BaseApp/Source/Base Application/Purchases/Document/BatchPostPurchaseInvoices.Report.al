﻿namespace Microsoft.Purchases.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using System.Environment;

report 497 "Batch Post Purchase Invoices"
{
    Caption = 'Batch Post Purchase Invoices';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Invoice));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Purchase Invoice';

            trigger OnPreDataItem()
            var
                PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
                PostingSelectionManagement: Codeunit "Posting Selection Management";
            begin
                PostingSelectionManagement.CheckUserCanInvoicePurchase();
                PurchaseBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Print, PrintDoc);
                PurchaseBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDateReq);
                PurchaseBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"VAT Date", VATDateReq);
                PurchaseBatchPostMgt.RunBatch("Purchase Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, true);

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
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a check mark in one or both of the following boxes.';

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
                        ToolTip = 'Specifies if you want to replace the purchase invoices'' posting date with the date entered in the field above.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then begin
                                Message(Text003);
                                Message(Text1130000, "Purchase Header".FieldCaption("Document Date"), "Purchase Header".FieldCaption("Operation Occurred Date"),
                                  "Purchase Header".FieldCaption("Posting Date"));
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
                        ToolTip = 'Specifies if the new document date will be applied.';

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
                        ToolTip = 'Specifies if you want to replace the purchase invoices VAT date with the date in the VAT Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the invoices before posting.';

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
                        ToolTip = 'Specifies if you want to print the invoice after posting. In the Report Output Type field on the Purchases and Payables page, you define if the report will be printed or output as a PDF.';

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
            if not VATReportingDateMgt.IsVATDateEnabled() then begin
                ReplaceVATDateReq := ReplacePostingDate;
                VATDateReq := PostingDateReq;
            end;
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
                exit;
            PurchasesPayablesSetup.Get();
            CalcInvDisc := PurchasesPayablesSetup."Calc. Inv. Discount";
            PrintDoc := false;
            PrintDocVisible := PurchasesPayablesSetup."Post & Print with Job Queue";
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        end;
    }

    labels
    {
    }

    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
#pragma warning disable AA0074
        Text003: Label 'The exchange rate associated with the new posting date on the purchase header will not apply to the purchase lines.';
#pragma warning restore AA0074

    protected var
        PostingDateReq, VATDateReq : Date;
        ReplacePostingDate, ReplaceVATDateReq : Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        PrintDocVisible: Boolean;
        Text1130000: Label 'The %1 and %2 may be modified automatically if they are greater than the %3.';
        VATDateEnabled: Boolean;

    local procedure UpdateVATDate()
    begin
        if ReplaceVATDateReq then
            VATDateReq := PostingDateReq;
    end;
}

