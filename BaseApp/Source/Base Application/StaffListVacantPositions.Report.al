report 17372 "Staff List Vacant Positions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './StaffListVacantPositions.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Staffing List - Vacancies';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Staff List Archive"; "Staff List Archive")
        {
            DataItemTableView = SORTING("Document No.");
            RequestFilterFields = "Document No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Staff_List_Archive__Staff_List_Date_; "Staff List Date")
            {
            }
            column(Staff_List_Archive__Document_No__; "Document No.")
            {
            }
            column(Staff_List_Line_Archive___Staff_Positions_; "Staff List Line Archive"."Staff Positions")
            {
            }
            column(Staff_List_Line_Archive___Occupied_Staff_Positions_; "Staff List Line Archive"."Occupied Staff Positions")
            {
            }
            column(Staff_List_Line_Archive___Vacant_Staff_Positions_; "Staff List Line Archive"."Vacant Staff Positions")
            {
            }
            column(Staffing_List___VacanciesCaption; Staffing_List___VacanciesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Staff_List_Archive__Staff_List_Date_Caption; FieldCaption("Staff List Date"))
            {
            }
            column(Staff_List_Archive__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(TOTALCaption; TOTALCaptionLbl)
            {
            }
            dataitem("Staff List Line Archive"; "Staff List Line Archive")
            {
                DataItemLink = "Document No." = FIELD("Document No.");
                DataItemTableView = SORTING("Document No.", "Org. Unit Code", "Job Title Code");
                column(Staff_List_Line_Archive__Org__Unit_Name_; "Org. Unit Name")
                {
                }
                column(Staff_List_Line_Archive__Job_Title_Name_; "Job Title Name")
                {
                }
                column(Staff_List_Line_Archive__Staff_Positions_; "Staff Positions")
                {
                }
                column(Staff_List_Line_Archive__Staff_Base_Salary_; "Staff Base Salary")
                {
                }
                column(Staff_List_Line_Archive__Occupied_Staff_Positions_; "Occupied Staff Positions")
                {
                }
                column(Staff_List_Line_Archive__Vacant_Staff_Positions_; "Vacant Staff Positions")
                {
                }
                column(Staff_List_Line_Archive__Staff_Base_Salary_Caption; FieldCaption("Staff Base Salary"))
                {
                }
                column(Staff_List_Line_Archive__Staff_Positions_Caption; FieldCaption("Staff Positions"))
                {
                }
                column(Staff_List_Line_Archive__Job_Title_Name_Caption; FieldCaption("Job Title Name"))
                {
                }
                column(Staff_List_Line_Archive__Org__Unit_Name_Caption; FieldCaption("Org. Unit Name"))
                {
                }
                column(Staff_List_Line_Archive__Occupied_Staff_Positions_Caption; FieldCaption("Occupied Staff Positions"))
                {
                }
                column(Staff_List_Line_Archive__Vacant_Staff_Positions_Caption; FieldCaption("Vacant Staff Positions"))
                {
                }
                column(Staff_List_Line_Archive_Document_No_; "Document No.")
                {
                }
                column(Staff_List_Line_Archive_Org__Unit_Code; "Org. Unit Code")
                {
                }
                column(Staff_List_Line_Archive_Job_Title_Code; "Job Title Code")
                {
                }
            }

            trigger OnPreDataItem()
            begin
                FilterText := GetFilters;
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
        FilterText: Text[250];
        Staffing_List___VacanciesCaptionLbl: Label 'Staffing List - Vacancies';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TOTALCaptionLbl: Label 'TOTAL';
}

