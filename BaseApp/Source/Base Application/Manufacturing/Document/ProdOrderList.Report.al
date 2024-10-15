// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

report 99000763 "Prod. Order - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Document/ProdOrderList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = "No.", Status, "Source No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Production_Order__TABLECAPTION_________ProdOrderFilter; TableCaption + ':' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(Production_Order__No__; "No.")
            {
            }
            column(Production_Order_Description; Description)
            {
            }
            column(Production_Order__Source_No__; "Source No.")
            {
            }
            column(Production_Order__Routing_No__; "Routing No.")
            {
            }
            column(Production_Order__Starting_Date_; Format("Starting Date"))
            {
            }
            column(Production_Order__Ending_Date_; Format("Ending Date"))
            {
            }
            column(Production_Order__Due_Date_; Format("Due Date"))
            {
            }
            column(Production_Order_Status; Status)
            {
            }
            column(Production_Order_Quantity; Quantity)
            {
            }
            column(Production_Order_Status_Control8; Status)
            {
            }
            column(Prod__Order___ListCaption; Prod__Order___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Production_Order__No__Caption; FieldCaption("No."))
            {
            }
            column(Production_Order_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Production_Order__Source_No__Caption; FieldCaption("Source No."))
            {
            }
            column(Production_Order__Routing_No__Caption; FieldCaption("Routing No."))
            {
            }
            column(Production_Order__Starting_Date_Caption; Production_Order__Starting_Date_CaptionLbl)
            {
            }
            column(Production_Order__Ending_Date_Caption; Production_Order__Ending_Date_CaptionLbl)
            {
            }
            column(Production_Order__Due_Date_Caption; Production_Order__Due_Date_CaptionLbl)
            {
            }
            column(Production_Order_StatusCaption; FieldCaption(Status))
            {
            }
            column(Production_Order_QuantityCaption; FieldCaption(Quantity))
            {
            }

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
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

    var
        ProdOrderFilter: Text;
        Prod__Order___ListCaptionLbl: Label 'Prod. Order - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Production_Order__Starting_Date_CaptionLbl: Label 'Starting Date';
        Production_Order__Ending_Date_CaptionLbl: Label 'Ending Date';
        Production_Order__Due_Date_CaptionLbl: Label 'Due Date';
}

