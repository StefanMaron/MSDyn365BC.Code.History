report 5211 "Employee - Unions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './EmployeeUnions.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Unions';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Union; Union)
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Union_TABLECAPTION__________UnionFilter; TableCaption + ': ' + UnionFilter)
            {
            }
            column(UnionFilter; UnionFilter)
            {
            }
            column(Union_Code; Code)
            {
            }
            column(Union_Name; Name)
            {
            }
            column(Employee___UnionsCaption; Employee___UnionsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Full_NameCaption; Full_NameCaptionLbl)
            {
            }
            column(Employee__No__Caption; Employee.FieldCaption("No."))
            {
            }
            dataitem(Employee; Employee)
            {
                DataItemLink = "Union Code" = FIELD(Code);
                DataItemTableView = SORTING(Status, "Union Code");
                column(Employee__No__; "No.")
                {
                }
                column(FullName; FullName())
                {
                }
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
        UnionFilter := Union.GetFilters();
    end;

    var
        UnionFilter: Text;
        Employee___UnionsCaptionLbl: Label 'Employee - Unions';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
}

