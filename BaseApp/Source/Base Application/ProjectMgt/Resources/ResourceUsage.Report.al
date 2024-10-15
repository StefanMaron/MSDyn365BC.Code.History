report 1106 "Resource Usage"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ProjectMgt/Resources/ResourceUsage.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource Utilization';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ResTableCaptionResFilter; TableCaption + ': ' + ResFilter)
            {
            }
            column(ResFilter; ResFilter)
            {
            }
            column(No_Resource; "No.")
            {
                IncludeCaption = true;
            }
            column(Type_Resource; Type)
            {
                IncludeCaption = true;
            }
            column(Name_Resource; Name)
            {
                IncludeCaption = true;
            }
            column(capacity_Resource; Capacity)
            {
                IncludeCaption = true;
            }
            column(UsageQty_Resource; "Usage (Qty.)")
            {
                IncludeCaption = true;
            }
            column(CapacityUsageQty; Capacity - "Usage (Qty.)")
            {
            }
            column(ResourceUsageCaption; ResourceUsageCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CapacityUsageQtyCaption; CapacityUsageQtyCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Capacity, "Usage (Qty.)");
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
        ResFilter := Resource.GetFilters();
    end;

    var
        ResFilter: Text;
        ResourceUsageCaptionLbl: Label 'Resource Usage';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CapacityUsageQtyCaptionLbl: Label 'Balance';
}

