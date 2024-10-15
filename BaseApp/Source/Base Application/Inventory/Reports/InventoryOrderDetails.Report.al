namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;

report 708 "Inventory Order Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryOrderDetails.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Order Details';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Bin Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(StrSbStNoSalOdrLnSalLnFlt; StrSubstNo(Text000, SalesLineFilter))
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(OutstandingAmt_SalesLine; "Sales Line"."Outstanding Amount")
            {
            }
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
            }
            column(BinFilter_Item; "Bin Filter")
            {
            }
            column(InvntryOrderDetailCapt; InvntryOrderDetailCaptLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(SalesHeaderBilltoNameCapt; SalesHeaderBilltoNameCaptLbl)
            {
            }
            column(SalesLineShipDateCaption; SalesLineShipDateCaptionLbl)
            {
            }
            column(BackOrderQtyCaption; BackOrderQtyCaptionLbl)
            {
            }
            column(SalesLineLineDiscCaption; SalesLineLineDiscCaptionLbl)
            {
            }
            column(SalesLineInvDiscAmtCapt; SalesLineInvDiscAmtCaptLbl)
            {
            }
            column(SalesLineOutstngAmtCapt; SalesLineOutstngAmtCaptLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where("Document Type" = const(Order), Type = const(Item), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(SalesLineDocumentNo; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(SalesHeaderBilltoName; SalesHeader."Bill-to Name")
                {
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(Quantity_SalesLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(OutstandingQty_SalesLine; "Outstanding Quantity")
                {
                    IncludeCaption = true;
                }
                column(BackOrderQty; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SalesLineUnitPrice; "Unit Price")
                {
                    IncludeCaption = true;
                }
                column(SalesLineLineDiscount; "Line Discount %")
                {
                }
                column(InvDiscountAmt_SalesLine; "Inv. Discount Amount")
                {
                }
                column(OutstandingAmt1_SalesLine; "Outstanding Amount")
                {
                }
                column(SalesLineDescription; Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SalesHeader.Get("Document Type", "Document No.");
                    if SalesHeader."Currency Factor" <> 0 then
                        "Outstanding Amount" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              WorkDate(), SalesHeader."Currency Code", "Outstanding Amount",
                              SalesHeader."Currency Factor"));
                    if "Shipment Date" < WorkDate() then
                        BackOrderQty := "Outstanding Quantity"
                    else
                        BackOrderQty := 0;
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Order Details';
        AboutText = 'Analyse your outstanding sales orders to understand your expected sales volume. Show all outstanding sales and highlight overdue sales lines for each item.';

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
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        BackOrderQty: Decimal;
        ItemFilter: Text;
        SalesLineFilter: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InvntryOrderDetailCaptLbl: Label 'Inventory Order Details';
        CurrReportPageNoCaptionLbl: Label 'Page';
        SalesHeaderBilltoNameCaptLbl: Label 'Customer';
        SalesLineShipDateCaptionLbl: Label 'Shipment Date';
        BackOrderQtyCaptionLbl: Label 'Quantity on Back Order';
        SalesLineLineDiscCaptionLbl: Label 'Line Discount %';
        SalesLineInvDiscAmtCaptLbl: Label 'Invoice Discount Amount';
        SalesLineOutstngAmtCaptLbl: Label 'Amount on Order Inclusive VAT';
        TotalCaptionLbl: Label 'Total';

    protected var
        SalesHeader: Record "Sales Header";
}

