namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

report 107 "Customer - Order Summary"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerOrderSummary.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Order Summary';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = Customer;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(CustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter1; CustFilter)
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1]))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] - 1))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1))
            {
            }
            column(SalesAmtOnOrderLCY1; SalesAmtOnOrderLCY[1])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY2; SalesAmtOnOrderLCY[2])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY3; SalesAmtOnOrderLCY[3])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY4; SalesAmtOnOrderLCY[4])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY5; SalesAmtOnOrderLCY[5])
            {
                AutoFormatType = 1;
            }
            column(SalesOrderAmountLCY; SalesOrderAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(No_Cust; "No.")
            {
            }
            column(CustomerOrderSummaryCaption; CustomerOrderSummaryCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(OutstandingOrdersCaption; OutstandingOrdersCaptionLbl)
            {
            }
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
            }
            column(CustomerNameCaption; CustomerNameCap)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Bill-to Customer No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Currency Code" = field("Currency Filter");
                DataItemTableView = sorting("Document Type", "Bill-to Customer No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                column(SalesOrderAmount; SalesOrderAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder5; SalesAmtOnOrder[5])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder4; SalesAmtOnOrder[4])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder3; SalesAmtOnOrder[3])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder2; SalesAmtOnOrder[2])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder1; SalesAmtOnOrder[1])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrencyCode_SalesLine; "Currency Code")
                {
                }
                column(Name_Cust; Customer.Name)
                {
                    IncludeCaption = true;
                }
                column(SalesLineBilltoNo_Customer; "Bill-to Customer No.")
                {
                }
                column(GroupNumber; GroupNumber)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PeriodNo := 1;
                    while "Shipment Date" >= PeriodStartDate[PeriodNo] do
                        PeriodNo := PeriodNo + 1;

                    Currency.InitRoundingPrecision();
                    if "VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"] then
                        SalesOrderAmount :=
                          Round(
                            (Amount + "VAT Base Amount" * "VAT %" / 100) * "Outstanding Quantity" / Quantity / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision")
                    else
                        SalesOrderAmount :=
                          Round(
                            "Outstanding Amount" / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision");
                    SalesOrderAmountLCY := SalesOrderAmount;

                    for i := 1 to ArrayLen(SalesAmtOnOrder) do begin
                        SalesAmtOnOrder[i] := 0;
                        SalesAmtOnOrderLCY[i] := 0;
                    end;

                    if "Currency Code" <> '' then begin
                        SalesHeader.Get(1, "Document No.");
                        if SalesHeader."Currency Factor" <> 0 then
                            SalesOrderAmountLCY :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), SalesHeader."Currency Code",
                                  SalesOrderAmount, SalesHeader."Currency Factor"));
                    end;

                    SalesAmtOnOrder[PeriodNo] := SalesOrderAmount;
                    SalesAmtOnOrderLCY[PeriodNo] := SalesOrderAmountLCY;

                    if NewCustomer then
                        GroupNumber += 1
                    else
                        if not PrintAmountsInLCY and ("Currency Code" <> LastCurrencyCode) then
                            GroupNumber += 1;
                    NewCustomer := false;
                    LastCurrencyCode := "Currency Code";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                NewCustomer := true;
            end;

            trigger OnPreDataItem()
            begin
                ClearAmounts();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Customer - Order Summary';
        AboutText = 'Analyse your nonshipped orders in order to understand your expected sales volume. See order details with the quantity not yet shipped for each customer in three periods of 30 days each, starting from the specified date.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShwAmtinLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        if not PrintAmountsInLCY then begin
            Currency.SetFilter(Code, Customer.GetFilter("Currency Filter"));
            if Currency.Count = 1 then
                Currency.FindFirst();
        end;
        for i := 1 to 3 do
            PeriodStartDate[i + 1] := CalcDate('<1M>', PeriodStartDate[i]);
        PeriodStartDate[5] := DMY2Date(31, 12, 9999);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        CustFilter: Text;
        SalesOrderAmount: Decimal;
        SalesOrderAmountLCY: Decimal;
        PeriodStartDate: array[5] of Date;
        SalesAmtOnOrderLCY: array[5] of Decimal;
        PrintAmountsInLCY: Boolean;
        PeriodNo: Integer;
        SalesAmtOnOrder: array[5] of Decimal;
        i: Integer;
        CustomerOrderSummaryCaptionLbl: Label 'Customer - Order Summary';
        PageNoCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY';
        OutstandingOrdersCaptionLbl: Label 'Outstanding Orders';
        CustomerNoCaptionLbl: Label 'Customer No.';
#pragma warning disable AA0074
        CustomerNameCap: Label 'Name';
#pragma warning restore AA0074
        BeforeCaptionLbl: Label '...before';
        AfterCaptionLbl: Label 'after...';
        TotalCaptionLbl: Label 'Total';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        GroupNumber: Integer;
        NewCustomer: Boolean;
        LastCurrencyCode: Code[10];

    procedure InitializeRequest(StartingDate: Date; ShowAmountInLCY: Boolean)
    begin
        PeriodStartDate[1] := StartingDate;
        PrintAmountsInLCY := ShowAmountInLCY;
    end;

    local procedure ClearAmounts()
    begin
        Clear(SalesOrderAmountLCY);
        Clear(SalesAmtOnOrderLCY);
        Clear(SalesOrderAmount);
        Clear(SalesAmtOnOrder);
    end;
}

