namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 309 "Vendor - Purchase List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorPurchaseList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Purchase List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(MinAmtLCY; MinAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(HideAddr; HideAddr)
            {
            }
            column(TableCaptVendFilter; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(VendNo; "No.")
            {
                IncludeCaption = true;
            }
            column(VendName; Name)
            {
                IncludeCaption = true;
            }
            column(VendVATRegNo; "VAT Registration No.")
            {
                IncludeCaption = true;
            }
            column(AmtPurchLCY; AmtPurchLCY)
            {
                AutoFormatType = 1;
            }
            column(VendAddr2; VendorAddr[2])
            {
            }
            column(VendAddr3; VendorAddr[3])
            {
            }
            column(VendAddr4; VendorAddr[4])
            {
            }
            column(VendAddr5; VendorAddr[5])
            {
            }
            column(VendAddr6; VendorAddr[6])
            {
            }
            column(VendAddr7; VendorAddr[7])
            {
            }
            column(VendAddr8; VendorAddr[8])
            {
            }
            column(VendPurchListCapt; VendPurchListCaptLbl)
            {
            }
            column(CurrRptPageNoCapt; CurrRptPageNoCaptLbl)
            {
            }
            column(MinAmtLCYCapt; MinAmtLCYCaptLbl)
            {
            }
            column(AmtPurchLCYCapt; AmtPurchLCYCaptLbl)
            {
            }
            column(TotRptedAmtofPurchLCYCapt; TotRptedAmtofPurchLCYCaptLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                FormatAddr: Codeunit "Format Address";
            begin
                AmtPurchLCY := CalculateAmtOfPurchaseLCY();
                if AmtPurchLCY < MinAmtLCY then
                    CurrReport.Skip();

                if not HideAddr then
                    FormatAddr.Vendor(VendorAddr, Vendor);
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
                    field(MinAmtLCY; MinAmtLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Amounts (LCY) Greater Than';
                        ToolTip = 'Specifies an amount so that the report will only include those customers to which you have sold more than this amount within the specified dates.';
                    }
                    field(HideAddr; HideAddr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Hide Address Detail';
                        ToolTip = 'Specifies that you do not want the report to show address details for each vendor.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
    end;

    var
        MinAmtLCY: Decimal;
        HideAddr: Boolean;
        AmtPurchLCY: Decimal;
        VendorAddr: array[8] of Text[100];
        VendFilter: Text;
        VendPurchListCaptLbl: Label 'Vendor - Purchase List';
        CurrRptPageNoCaptLbl: Label 'Page';
        MinAmtLCYCaptLbl: Label 'Amounts (LCY) greater than';
        AmtPurchLCYCaptLbl: Label 'Amount of Purchase (LCY)';
        TotRptedAmtofPurchLCYCaptLbl: Label 'Total Reported Amount of Purchase (LCY)';

    local procedure CalculateAmtOfPurchaseLCY(): Decimal
    var
        VendorLedgEntry: Record "Vendor Ledger Entry";
        Amt: Decimal;
        i: Integer;
    begin
        with VendorLedgEntry do begin
            SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
            SetRange("Vendor No.", Vendor."No.");
            SetFilter("Posting Date", Vendor.GetFilter("Date Filter"));
            for i := 1 to 3 do begin
                case i of
                    1:
                        SetRange("Document Type", "Document Type"::Invoice);
                    2:
                        SetRange("Document Type", "Document Type"::"Credit Memo");
                    3:
                        SetRange("Document Type", "Document Type"::Refund);
                end;
                CalcSums("Purchase (LCY)");
                Amt := Amt + "Purchase (LCY)";
            end;
            exit(-Amt);
        end;
    end;

    procedure InitializeRequest(NewMinAmtLCY: Decimal; NewHideAddress: Boolean)
    begin
        MinAmtLCY := NewMinAmtLCY;
        HideAddr := NewHideAddress;
    end;
}

