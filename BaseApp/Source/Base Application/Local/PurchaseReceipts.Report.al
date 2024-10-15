report 28029 "Purchase Receipts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/PurchaseReceipts.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Purchase Receipts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Purch. Rcpt. Header"; "Purch. Rcpt. Header")
        {
            DataItemTableView = SORTING("Pay-to Vendor No.");
            RequestFilterFields = "Pay-to Vendor No.", "Posting Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ReportFilter; ReportFilter)
            {
            }
            column(BuyfromVendorNo_PurchRcptHeader; "Buy-from Vendor No.")
            {
            }
            column(BuyfromVendorName_PurchRcptHeader; "Buy-from Vendor Name")
            {
            }
            column(FormatQuantity_PurchRcptLine; "Purch. Rcpt. Line".Quantity)
            {
            }
            column(TotalAmount; TotalAmount)
            {
            }
            column(PaytoVendorNo_PurchRcptHeader; "Pay-to Vendor No.")
            {
            }
            column(PurchaseReceiptsCaption; PurchaseReceiptsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(TypeCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption(Type))
            {
            }
            column(NoCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption("No."))
            {
            }
            column(DescriptionCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption(Description))
            {
            }
            column(DirectUnitCostCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption("Direct Unit Cost"))
            {
            }
            column(QuantityCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption(Quantity))
            {
            }
            column(InvoiceNoCaption; InvoiceNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(UnitofMeasureCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption("Unit of Measure"))
            {
            }
            column(LocationCodeCaption_PurchRcptLine; "Purch. Rcpt. Line".FieldCaption("Location Code"))
            {
            }
            dataitem("Purch. Rcpt. Line"; "Purch. Rcpt. Line")
            {
                DataItemLink = "Document No." = FIELD("No."), "Pay-to Vendor No." = FIELD("Pay-to Vendor No.");
                column(Type_PurchRcptLine; Type)
                {
                }
                column(No_PurchRcptLine; "No.")
                {
                }
                column(Description_PurchRcptLine; Description)
                {
                }
                column(DirectUnitCost_PurchRcptLine; "Direct Unit Cost")
                {
                }
                column(Quantity_PurchRcptLine; Quantity)
                {
                }
                column(FormatTotalAmount; TotalAmount)
                {
                }
                column(No_PurchRcptHeader; "Purch. Rcpt. Header"."No.")
                {
                }
                column(UnitofMeasure_PurchRcptLine; "Unit of Measure")
                {
                }
                column(LocationCode_PurchRcptLine; "Location Code")
                {
                }
                column(LineNo_PurchRcptLine; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalAmount := Quantity * "Direct Unit Cost";
                end;
            }

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Pay-to Vendor No.");
                Clear(TotalAmount);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ReportFilter := "Purch. Rcpt. Header".GetFilters();
    end;

    var
        ReportFilter: Text[250];
        LastFieldNo: Integer;
        TotalAmount: Decimal;
        PurchaseReceiptsCaptionLbl: Label 'Purchase Receipts';
        PageCaptionLbl: Label 'Page';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        TotalCaptionLbl: Label 'Total';
}

