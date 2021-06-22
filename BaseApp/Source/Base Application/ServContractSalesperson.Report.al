report 5978 "Serv. Contract - Salesperson"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ServContractSalesperson.rdlc';
    ApplicationArea = Service;
    Caption = 'Serv. Contract - Salesperson';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = SORTING("Salesperson Code", Status) WHERE("Contract Type" = CONST(Contract));
            RequestFilterFields = "Salesperson Code", Status, "Contract No.", "Starting Date";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ServCntrctFlt_ServContract; TableCaption + ': ' + ServContractFilter)
            {
            }
            column(ServContractFilter; ServContractFilter)
            {
            }
            column(SlspersonCod_ServContract; "Salesperson Code")
            {
                IncludeCaption = true;
            }
            column(ContractNo_ServContract; "Contract No.")
            {
                IncludeCaption = true;
            }
            column(CustomerNo_ServContract; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(Name_ServContract; Name)
            {
                IncludeCaption = true;
            }
            column(StartingDate_ServContract; Format("Starting Date"))
            {
            }
            column(AnnualAmount_ServContract; "Annual Amount")
            {
                IncludeCaption = true;
            }
            column(ShiptoCode_ServContract; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(CntrctGrCode_ServContract; "Contract Group Code")
            {
                IncludeCaption = true;
            }
            column(NextInvoDt_ServContract; Format("Next Invoice Date"))
            {
            }
            column(TtlFldCptnSalespersonCode; Text000 + FieldCaption("Salesperson Code"))
            {
            }
            column(TotalFor; TotalForLbl)
            {
            }
            column(ServContrctSalepersonCptn; ServContrctSalepersonCptnLbl)
            {
            }
            column(CurrReportPageNoCaptn; CurrReportPageNoCaptnLbl)
            {
            }
            column(ServContractStrtgDtCptn; ServContractStrtgDtCptnLbl)
            {
            }
            column(ServCntrctNxtInvDtCptn; ServCntrctNxtInvDtCptnLbl)
            {
            }
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
        ServContractFilter := "Service Contract Header".GetFilters;
    end;

    var
        Text000: Label 'Total for ';
        ServContractFilter: Text;
        TotalForLbl: Label 'Total ';
        ServContrctSalepersonCptnLbl: Label 'Service Contract - Salesperson';
        CurrReportPageNoCaptnLbl: Label 'Page';
        ServContractStrtgDtCptnLbl: Label 'Starting Date';
        ServCntrctNxtInvDtCptnLbl: Label 'Next Invoice Date';
}

