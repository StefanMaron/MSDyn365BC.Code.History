namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

report 108 "Customer - Order Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerOrderDetail.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Order Detail';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = Customer;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", Priority;
            column(ShipmentPeriodDate; StrSubstNo(Text000, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(CustTableCapCustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(SalesOrderLineFilter; StrSubstNo(Text001, SalesLineFilter))
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(No_Customer; "No.")
            {
                IncludeCaption = true;
            }
            column(Name_Customer; Name)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(CustOrderDetailCaption; CustOrderDetailCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllAmtAreInLCYCaption; AllAmtAreInLCYCaptionLbl)
            {
            }
            column(ShipmentDateCaption; ShipmentDateCaptionLbl)
            {
            }
            column(QtyOnBackOrderCaption; QtyOnBackOrderCaptionLbl)
            {
            }
            column(OutstandingOrdersCaption; OutstandingOrdersCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Bill-to Customer No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", "Bill-to Customer No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(SalesHeaderNo; SalesHeader."No.")
                {
                }
                column(SalesHeaderOrderDate; SalesHeader."Order Date")
                {
                }
                column(Description_SalesLine; Description)
                {
                    IncludeCaption = true;
                }
                column(No_SalesLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(Type_SalesLine; Type)
                {
                    IncludeCaption = true;
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(Quantity_SalesLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(OutStandingQty_SalesLine; "Outstanding Quantity")
                {
                    IncludeCaption = true;
                }
                column(BackOrderQty; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(UnitPrice_SalesLine; "Unit Price")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                    IncludeCaption = true;
                }
                column(LineDiscAmt_SalesLine; "Line Discount Amount")
                {
                    IncludeCaption = true;
                }
                column(InvDiscAmt_SalesLine; "Inv. Discount Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                    IncludeCaption = true;
                }
                column(SalesOrderAmount; SalesOrderAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesHeaderCurrCode; SalesHeader."Currency Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    NewOrder := "Document No." <> SalesHeader."No.";
                    if NewOrder then
                        SalesHeader.Get(1, "Document No.");
                    if "Shipment Date" <= WorkDate() then
                        BackOrderQty := "Outstanding Quantity"
                    else
                        BackOrderQty := 0;
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
                    if SalesHeader."Currency Code" <> '' then begin
                        if SalesHeader."Currency Factor" <> 0 then
                            SalesOrderAmountLCY :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), SalesHeader."Currency Code",
                                  SalesOrderAmountLCY, SalesHeader."Currency Factor"));
                        if PrintAmountsInLCY then begin
                            "Unit Price" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), SalesHeader."Currency Code",
                                  "Unit Price", SalesHeader."Currency Factor"));
                            SalesOrderAmount := SalesOrderAmountLCY;
                        end;
                    end;
                    if SalesHeader."Prices Including VAT" then begin
                        "Unit Price" := "Unit Price" / (1 + "VAT %" / 100);
                        "Inv. Discount Amount" := "Inv. Discount Amount" / (1 + "VAT %" / 100);
                    end;
                    "Inv. Discount Amount" := "Inv. Discount Amount" * "Outstanding Quantity" / Quantity;
                    CurrencyCode2 := SalesHeader."Currency Code";
                    if PrintAmountsInLCY then
                        CurrencyCode2 := '';
                    TempCurrencyTotalBuffer.UpdateTotal(
                      CurrencyCode2,
                      SalesOrderAmount,
                      Counter1,
                      Counter1);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(SalesOrderAmountLCY);
                    Clear(SalesOrderAmount);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(TotalAmt_CurrTotalBuff; TempCurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = TempCurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode_CurrTotalBuff; TempCurrencyTotalBuffer."Currency Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := TempCurrencyTotalBuffer.Find('-')
                    else
                        OK := TempCurrencyTotalBuffer.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    TempCurrencyTotalBuffer2.UpdateTotal(
                      TempCurrencyTotalBuffer."Currency Code",
                      TempCurrencyTotalBuffer."Total Amount",
                      Counter1,
                      Counter1);
                end;

                trigger OnPostDataItem()
                begin
                    TempCurrencyTotalBuffer.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPage then
                    PageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                Clear(SalesOrderAmountLCY);
            end;
        }
        dataitem(Integer2; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(TotalAmt_CurrTotalBuff2; TempCurrencyTotalBuffer2."Total Amount")
            {
                AutoFormatExpression = TempCurrencyTotalBuffer2."Currency Code";
                AutoFormatType = 1;
            }
            column(CurrCode_CurrTotalBuff2; TempCurrencyTotalBuffer2."Currency Code")
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := TempCurrencyTotalBuffer2.Find('-')
                else
                    OK := tempCurrencyTotalBuffer2.Next() <> 0;
                if not OK then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                TempCurrencyTotalBuffer2.DeleteAll();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer - Order Detail';
        AboutText = 'Analyse your outstanding sales orders to understand your expected sales volume. Show all outstanding sales and highlight overdue sales lines for each customer.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                    field(NewPagePerCustomer; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer''s information is printed on a new page if you have chosen two or more customers to be included in the report.';
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
        OrderNoCaption = 'Order No.';
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        SalesLineFilter := "Sales Line".GetFilters();
        PeriodText := "Sales Line".GetFilter("Shipment Date");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        TempCurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        TempCurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        Currency: Record Currency;
        CustFilter: Text;
        SalesLineFilter: Text;
        SalesOrderAmount: Decimal;
        SalesOrderAmountLCY: Decimal;
        PrintAmountsInLCY: Boolean;
        PeriodText: Text;
        PrintOnlyOnePerPage: Boolean;
        BackOrderQty: Decimal;
        NewOrder: Boolean;
        OK: Boolean;
        Counter1: Integer;
        CurrencyCode2: Code[10];
        PageGroupNo: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Shipment Date: %1';
        Text001: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CustOrderDetailCaptionLbl: Label 'Customer - Order Detail';
        PageCaptionLbl: Label 'Page';
        AllAmtAreInLCYCaptionLbl: Label 'All amounts are in LCY';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
        QtyOnBackOrderCaptionLbl: Label 'Quantity on Back Order';
        OutstandingOrdersCaptionLbl: Label 'Outstanding Orders';
        TotalCaptionLbl: Label 'Total';

    protected var
        SalesHeader: Record "Sales Header";

    procedure InitializeRequest(ShowAmountInLCY: Boolean; NewPagePerCustomer: Boolean)
    begin
        PrintAmountsInLCY := ShowAmountInLCY;
        PrintOnlyOnePerPage := NewPagePerCustomer;
    end;
}

