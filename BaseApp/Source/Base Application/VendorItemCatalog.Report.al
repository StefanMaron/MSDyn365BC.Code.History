report 320 "Vendor Item Catalog"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VendorItemCatalog.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Item Catalog';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(VendTblCapVendFltr; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(PhoneNo_Vendor; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(PricesInclVATText; PricesInclVATText)
            {
            }
            column(VendorItemCatalogCaption; VendorItemCatalogCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(PurchPriceStartDateCaption; PurchPriceStartDateCaptionLbl)
            {
            }
            column(ItemVendLeadTimeCalcCaptn; ItemVendLeadTimeCalcCaptnLbl)
            {
            }
            column(ItemVendorItemNoCaption; ItemVendorItemNoCaptionLbl)
            {
            }
            dataitem("Purchase Price"; "Purchase Price")
            {
                DataItemLink = "Vendor No." = FIELD("No.");
                DataItemTableView = SORTING("Vendor No.");
                column(ItemNo_PurchPrice; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(ItemDescription; Item.Description)
                {
                    IncludeCaption = false;
                }
                column(StartingDt_PurchPrice; Format("Starting Date"))
                {
                }
                column(DrctUnitCost_PurchPrice; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                    IncludeCaption = true;
                }
                column(CurrCode_PurchPrice; "Currency Code")
                {
                }
                column(ItemVendLeadTimeCal; ItemVend."Lead Time Calculation")
                {
                    IncludeCaption = false;
                }
                column(ItemVendVendorItemNo; ItemVend."Vendor Item No.")
                {
                    IncludeCaption = false;
                }

                trigger OnAfterGetRecord()
                begin
                    if "Item No." <> Item."No." then
                        Item.Get("Item No.");

                    if not ItemVend.Get("Vendor No.", "Item No.", "Variant Code") then
                        ItemVend.Init;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Prices Including VAT" then
                    PricesInclVATText := Text000
                else
                    PricesInclVATText := Text001;
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
    end;

    var
        Text000: Label 'Prices Include VAT';
        Text001: Label 'Prices Exclude VAT';
        Item: Record Item;
        ItemVend: Record "Item Vendor";
        VendFilter: Text;
        PricesInclVATText: Text[30];
        VendorItemCatalogCaptionLbl: Label 'Vendor Item Catalog';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemDescriptionCaptionLbl: Label 'Description';
        PurchPriceStartDateCaptionLbl: Label 'Starting Date';
        ItemVendLeadTimeCalcCaptnLbl: Label 'Lead Time Calculation';
        ItemVendorItemNoCaptionLbl: Label 'Vendor Item No.';
}

