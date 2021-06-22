report 99000780 "Capacity Task List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CapacityTaskList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Capacity Task List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
        {
            DataItemTableView = SORTING(Type, "No.");
            RequestFilterFields = Type, "No.", Status, "Starting Date";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PORtngLineTableCaptFilter; TableCaption + ':' + ProdOrderRtngLineFilter)
            {
            }
            column(ProdOrderRtngLineFilter; ProdOrderRtngLineFilter)
            {
            }
            column(Type_ProdOrderRtngLine; Type)
            {
            }
            column(No_ProdOrderRtngLine; "No.")
            {
            }
            column(PONo_ProdOrderRtngLine; "Prod. Order No.")
            {
                IncludeCaption = true;
            }
            column(RtngNo_ProdOrderRtngLine; "Routing No.")
            {
                IncludeCaption = true;
            }
            column(OPNo_ProdOrderRtngLine; "Operation No.")
            {
                IncludeCaption = true;
            }
            column(Desc_ProdOrderRtngLine; Description)
            {
                IncludeCaption = true;
            }
            column(InptQty_ProdOrderRtngLine; "Input Quantity")
            {
                IncludeCaption = true;
            }
            column(StrtTm_ProdOrderRtngLine; "Starting Time")
            {
                IncludeCaption = true;
            }
            column(StrtDt_ProdOrderRtngLine; Format("Starting Date"))
            {
            }
            column(EndTime_ProdOrderRtngLine; "Ending Time")
            {
                IncludeCaption = true;
            }
            column(EndDate_ProdOrderRtngLine; Format("Ending Date"))
            {
            }
            column(CapacityTaskListCapt; CapacityTaskListCaptLbl)
            {
            }
            column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
            {
            }
            column(ProdOrderRtngLnStrtDtCapt; ProdOrderRtngLnStrtDtCaptLbl)
            {
            }
            column(ProdOrderRtngLnEndDtCapt; ProdOrderRtngLnEndDtCaptLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if (Status = Status::Finished) or ("Routing Status" = "Routing Status"::Finished) then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                ProdOrderRtngLineFilter := GetFilters;
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
        ProdOrderRtngLineFilter: Text;
        CapacityTaskListCaptLbl: Label 'Capacity Task List';
        CurrReportPageNoCaptLbl: Label 'Page';
        ProdOrderRtngLnStrtDtCaptLbl: Label 'Starting Date';
        ProdOrderRtngLnEndDtCaptLbl: Label 'Ending Date';
}

