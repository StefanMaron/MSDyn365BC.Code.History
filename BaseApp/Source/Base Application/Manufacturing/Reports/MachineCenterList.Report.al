namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.MachineCenter;

report 99000760 "Machine Center List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/MachineCenterList.rdlc';
    AdditionalSearchTerms = 'production resource,production personnel';
    ApplicationArea = Manufacturing;
    Caption = 'Machine Center List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Machine Center"; "Machine Center")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Work Center No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Machine_Center__TABLECAPTION_________MachineCenterFilter; TableCaption + ':' + MachineCenterFilter)
            {
            }
            column(MachineCenterFilter; MachineCenterFilter)
            {
            }
            column(Machine_Center__No__; "No.")
            {
            }
            column(Machine_Center_Name; Name)
            {
            }
            column(Machine_Center__Work_Center_No__; "Work Center No.")
            {
            }
            column(Machine_Center_Capacity; Capacity)
            {
            }
            column(Machine_Center_Efficiency; Efficiency)
            {
            }
            column(Machine_Center_ListCaption; Machine_Center_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Machine_Center__No__Caption; FieldCaption("No."))
            {
            }
            column(Machine_Center_NameCaption; FieldCaption(Name))
            {
            }
            column(Machine_Center__Work_Center_No__Caption; FieldCaption("Work Center No."))
            {
            }
            column(Machine_Center_CapacityCaption; FieldCaption(Capacity))
            {
            }
            column(Machine_Center_EfficiencyCaption; FieldCaption(Efficiency))
            {
            }

            trigger OnPreDataItem()
            begin
                MachineCenterFilter := GetFilters();
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
        MachineCenterFilter: Text;
        Machine_Center_ListCaptionLbl: Label 'Machine Center List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

