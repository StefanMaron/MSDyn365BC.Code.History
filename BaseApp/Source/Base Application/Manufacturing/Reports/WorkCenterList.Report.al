namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.WorkCenter;

report 99000759 "Work Center List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/WorkCenterList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Work Center List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Work Center Group Code", "Shop Calendar Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Work_Center__TABLECAPTION_________WorkCenterFilter; TableCaption + ':' + WorkCenterFilter)
            {
            }
            column(WorkCenterFilter; WorkCenterFilter)
            {
            }
            column(Work_Center__No__; "No.")
            {
            }
            column(Work_Center_Name; Name)
            {
            }
            column(Work_Center__Alternate_Work_Center_; "Alternate Work Center")
            {
            }
            column(Work_Center__Work_Center_Group_Code_; "Work Center Group Code")
            {
            }
            column(Work_Center__Unit_Cost_; "Unit Cost")
            {
            }
            column(Work_Center_Capacity; Capacity)
            {
            }
            column(Work_Center_Efficiency; Efficiency)
            {
            }
            column(Work_Center__Shop_Calendar_Code_; "Shop Calendar Code")
            {
            }
            column(Work_Center__Unit_of_Measure_Code_; "Unit of Measure Code")
            {
            }
            column(Work_Center_ListCaption; Work_Center_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Work_Center__No__Caption; FieldCaption("No."))
            {
            }
            column(Work_Center_NameCaption; FieldCaption(Name))
            {
            }
            column(Work_Center__Alternate_Work_Center_Caption; FieldCaption("Alternate Work Center"))
            {
            }
            column(Work_Center__Work_Center_Group_Code_Caption; FieldCaption("Work Center Group Code"))
            {
            }
            column(Work_Center__Unit_Cost_Caption; FieldCaption("Unit Cost"))
            {
            }
            column(Work_Center_CapacityCaption; FieldCaption(Capacity))
            {
            }
            column(Work_Center_EfficiencyCaption; FieldCaption(Efficiency))
            {
            }
            column(Work_Center__Shop_Calendar_Code_Caption; FieldCaption("Shop Calendar Code"))
            {
            }
            column(Work_Center__Unit_of_Measure_Code_Caption; FieldCaption("Unit of Measure Code"))
            {
            }

            trigger OnPreDataItem()
            begin
                WorkCenterFilter := GetFilters();
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
        WorkCenterFilter: Text;
        Work_Center_ListCaptionLbl: Label 'Work Center List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

