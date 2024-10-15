report 17492 "Vacation Schedule T-7"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vacation Schedule T-7';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Vacation Schedule Name"; "Vacation Schedule Name")
        {
            DataItemTableView = SORTING(Year);
            RequestFilterFields = Year;
            dataitem("Vacation Schedule Line"; "Vacation Schedule Line")
            {
                DataItemLink = Year = FIELD(Year);
                DataItemTableView = SORTING(Year, "Org. Unit Code");
                RequestFilterFields = "Employee No.", "Org. Unit Code", "Job Title Code";

                trigger OnAfterGetRecord()
                begin
                    Employee.Get("Employee No.");

                    ExcelMgt.CopyRow(RowNo);

                    if OrgUnitCode <> "Org. Unit Code" then begin
                        ExcelMgt.CopyRow(RowNo);
                        ExcelMgt.FillCell('A' + Format(RowNo), "Org. Unit Code");
                        ExcelMgt.FillCell('F' + Format(RowNo), "Org. Unit Name");
                        RowNo += 1;
                    end;

                    ExcelMgt.FillCell('A' + Format(RowNo), "Org. Unit Name");
                    ExcelMgt.FillCell('F' + Format(RowNo), "Job Title Name");
                    ExcelMgt.FillCell('P' + Format(RowNo), Employee.GetFullNameOnDate("Vacation Schedule Name"."Document Date"));
                    ExcelMgt.FillCell('Y' + Format(RowNo), "Employee No.");
                    ExcelMgt.FillCell('AB' + Format(RowNo), Format("Calendar Days"));
                    ExcelMgt.FillCell('AE' + Format(RowNo), Format("Start Date"));
                    ExcelMgt.FillCell('AH' + Format(RowNo), Format("Actual Start Date"));
                    ExcelMgt.FillCell('AL' + Format(RowNo), "Carry Over Reason");
                    ExcelMgt.FillCell('AP' + Format(RowNo), Format("Estimated Start Date"));
                    ExcelMgt.FillCell('AS' + Format(RowNo), Comments);

                    OrgUnitCode := "Org. Unit Code";
                    RowNo += 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if RowNo > 23 then
                    CurrReport.Skip();

                ExcelMgt.SetSheetName(FieldCaption(Year) + ' ' + Format(Year));

                ExcelMgt.FillCell('A6', CompanyInfo.Name + ' ' + CompanyInfo."Name 2");
                ExcelMgt.FillCell('AR6', CompanyInfo."OKPO Code");
                ExcelMgt.FillCell('C11', LocMgt.Date2Text("Union Document Date"));
                ExcelMgt.FillCell('O11', "Union Document No.");
                ExcelMgt.FillCell('AA12', Format("Document Date"));
                ExcelMgt.FillCell('AG12', Format(Year));

                if Director.Get("Approver No.") then begin
                    ExcelMgt.FillCell('AP10', Director.GetJobTitleName);
                    ExcelMgt.FillCell('AP12', Director.GetNameInitials);
                end;

                // footer
                if HRManager.Get("HR Manager No.") then begin
                    ExcelMgt.FillCell('AF25', HRManager.GetNameInitials);
                    ExcelMgt.FillCell('Q25', HRManager.GetJobTitleName);
                end;
            end;

            trigger OnPreDataItem()
            begin
                FileName := ExcelTemplate.OpenTemplate(HumResSetup."T-7 Template Code");

                ExcelMgt.OpenBookForUpdate(FileName);

                ExcelMgt.OpenSheet('1');

                RowNo := 23;
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

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."T-7 Template Code"));
    end;

    trigger OnPreReport()
    begin
        HumResSetup.Get();
        HumResSetup.TestField("T-7 Template Code");
        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        HumResSetup: Record "Human Resources Setup";
        Employee: Record Employee;
        Director: Record Employee;
        HRManager: Record Employee;
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        LocMgt: Codeunit "Localisation Management";
        FileName: Text[1024];
        OrgUnitCode: Code[10];
        RowNo: Integer;
}

