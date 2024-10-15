report 99003804 "Demand Forecast"
{
    DefaultLayout = RDLC;
    RDLCLayout = './DemandForecast.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Demand Forecast';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Forecast Entry"; "Production Forecast Entry")
        {
            DataItemTableView = SORTING("Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");
            RequestFilterFields = "Production Forecast Name", "Item No.", "Forecast Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ForecastEntryTblCaptFilt; TableCaption + ': ' + ForecastFilter)
            {
            }
            column(ForecastFilter; ForecastFilter)
            {
            }
            column(ItemNo_ForecastEntry; "Item No.")
            {
                IncludeCaption = true;
            }
            column(ForecastDt_ForecastEntry; Format("Forecast Date"))
            {
            }
            column(ForecastQty_ForecastEntry; "Forecast Quantity")
            {
            }
            column(LocationCode_ForecastEntry; "Location Code")
            {
                IncludeCaption = true;
            }
            column(Desc_ForecastEntry; Description)
            {
                IncludeCaption = true;
            }
            column(EntryNo_ForecastEntry; "Entry No.")
            {
            }
            column(ProductionForecastCaption; ProductionForecastCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(SalesOrdShipmentDateCapt; SalesOrdShipmentDateCaptLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(ForecastCaption; ForecastCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemTableView = SORTING("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
                column(DocNo_SalesLine; "Document No.")
                {
                }
                column(Qty_SalesLine; Quantity)
                {
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(Desc_SalesLine; Description)
                {
                }
                column(No_SalesLine; "No.")
                {
                }
                column(SalesOrderCaption; SalesOrderCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Total := Total - Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    if not (ProdForecastEntry.Next() = 0) then
                        SetRange("Shipment Date",
                          "Production Forecast Entry"."Forecast Date",
                          ProdForecastEntry."Forecast Date" - 1)
                    else
                        SetFilter("Shipment Date", '%1..', "Production Forecast Entry"."Forecast Date");
                    SetRange(Type, Type::Item);
                    SetRange("No.", "Production Forecast Entry"."Item No.");
                    SetRange("Document Type", "Document Type"::Order);
                    if MfgSetup."Use Forecast on Locations" then
                        SetRange("Location Code", "Production Forecast Entry"."Location Code");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number);
                MaxIteration = 1;
                column(Total; Total)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                ProdForecastEntry.Copy("Production Forecast Entry");
                ProdForecastEntry.SetRange("Production Forecast Name", "Production Forecast Name");
                ProdForecastEntry.SetRange("Item No.", "Item No.");
                ProdForecastEntry.SetRange("Forecast Date", "Forecast Date");
                if MfgSetup."Use Forecast on Locations" then
                    ProdForecastEntry.SetRange("Location Code", "Location Code");
                Total := 0;
                repeat
                    Total += ProdForecastEntry."Forecast Quantity";
                until ProdForecastEntry.Next() = 0;
                ProdForecastEntry.SetRange("Forecast Date");

                Copy(ProdForecastEntry);
                CopyFilters(ProdForecastEntry2);
                "Forecast Quantity" := Total;
            end;

            trigger OnPreDataItem()
            begin
                ProdForecastEntry2.Copy("Production Forecast Entry");
                MfgSetup.Get();
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
        ForecastFilter := "Production Forecast Entry".GetFilters;
    end;

    var
        ProdForecastEntry: Record "Production Forecast Entry";
        ProdForecastEntry2: Record "Production Forecast Entry";
        MfgSetup: Record "Manufacturing Setup";
        Total: Decimal;
        ForecastFilter: Text;
        ProductionForecastCaptionLbl: Label 'Demand Forecast';
        CurrReportPageNoCaptionLbl: Label 'Page';
        SalesOrdShipmentDateCaptLbl: Label 'Date';
        QuantityCaptionLbl: Label 'Quantity';
        TypeCaptionLbl: Label 'Type';
        NoCaptionLbl: Label 'No.';
        ForecastCaptionLbl: Label 'Forecast';
        SalesOrderCaptionLbl: Label 'Sales Order';
        TotalCaptionLbl: Label 'Total';
}

