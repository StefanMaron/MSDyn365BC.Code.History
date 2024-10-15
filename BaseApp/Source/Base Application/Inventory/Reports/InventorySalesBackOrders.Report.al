namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 718 "Inventory - Sales Back Orders"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventorySalesBackOrders.rdlc';
    AdditionalSearchTerms = 'delayed order,unfulfilled demand';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Sales Back Orders';
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
            column(StrSubStNoSalesLineFltr; StrSubstNo(Text000, SalesLineFilter))
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
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(BinFilter_Item; "Bin Filter")
            {
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
            }
            column(InvSalesBackOrdersCaption; InvSalesBackOrdersCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CustNameCaption; CustNameCaptionLbl)
            {
            }
            column(CustPhoneNoCaption; CustPhoneNoCaptionLbl)
            {
            }
            column(SalesLineShipDateCaption; SalesLineShipDateCaptionLbl)
            {
            }
            column(OtherBackOrdersCaption; OtherBackOrdersCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Bin Code" = field("Bin Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where(Type = const(Item), "Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(DocumentNo_SalesLine; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(CustName; Cust.Name)
                {
                }
                column(CustPhoneNo; Cust."Phone No.")
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
                column(OtherBackOrders; OtherBackOrders)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Shipment Date" >= WorkDate() then
                        CurrReport.Skip();
                    Cust.Get("Bill-to Customer No.");

                    SalesOrderLine.SetRange("Bill-to Customer No.", Cust."No.");
                    SalesOrderLine.SetFilter("No.", '<>' + Item."No.");
                    OtherBackOrders := SalesOrderLine.FindFirst();
                end;

                trigger OnPreDataItem()
                begin
                    SalesOrderLine.SetCurrentKey("Document Type", "Bill-to Customer No.");
                    SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
                    SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Item);
                    SalesOrderLine.SetRange("Shipment Date", 0D, WorkDate() - 1);
                    SalesOrderLine.SetFilter("Outstanding Quantity", '<>0');
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Sales Back Orders';
        AboutText = 'See an overview of sales orders that can''''t be fulfilled due to out-of-stock items. This report highlights sales lines that are overdue to be shipped and includes information on the document & customer the order is linked to.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        ItemNoCaptionLbl = 'Item No.';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
    end;

    var
        Cust: Record Customer;
        SalesOrderLine: Record "Sales Line";
        OtherBackOrders: Boolean;
        ItemFilter: Text;
        SalesLineFilter: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InvSalesBackOrdersCaptionLbl: Label 'Inventory - Sales Back Orders';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CustNameCaptionLbl: Label 'Customer';
        CustPhoneNoCaptionLbl: Label 'Phone No.';
        SalesLineShipDateCaptionLbl: Label 'Shipment Date';
        OtherBackOrdersCaptionLbl: Label 'Other Back Orders';
}

