report 17363 "Reward Order T-11a"
{
    Caption = 'Reward Order T-11a';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Orders; "Employee Journal Line")
        {
            DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Document No.";

            trigger OnAfterGetRecord()
            var
                Employee: Record Employee;
                OrgUnit: Record "Organizational Unit";
                ReasonCode: Record "Reason Code";
            begin
                if RowNo = 32 then begin
                    ExcelMgt.FillCell('AI13', "HR Order No.");
                    ExcelMgt.FillCell('AV13', Format("HR Order Date"));

                    if ReasonCode.Get("Reason Code") then
                        ExcelMgt.FillCell('A18', ReasonCode.Description);
                end;

                ExcelMgt.CopyRow(RowNo);

                Employee.Get("Employee No.");
                ExcelMgt.FillCell('A' + Format(RowNo), Employee.GetFullNameOnDate("HR Order Date"));
                ExcelMgt.FillCell('R' + Format(RowNo), "Employee No.");
                OrgUnit.Get(Employee."Org. Unit Code");
                ExcelMgt.FillCell('Y' + Format(RowNo), OrgUnit.Name);
                ExcelMgt.FillCell('AI' + Format(RowNo), Employee.GetJobTitleName);

                ExcelMgt.FillCell('AS' + Format(RowNo), Format(Round(Amount, 0.01), 0, 1));
            end;

            trigger OnPreDataItem()
            begin
                RowNo := 32;
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
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."T-11a Template Code"));
    end;

    trigger OnPreReport()
    var
        FileName: Text[1024];
        Employee: Record Employee;
    begin
        HumResSetup.Get;
        HumResSetup.TestField("T-11a Template Code");

        FileName := ExcelTemplate.OpenTemplate(HumResSetup."T-11a Template Code");

        CompanyInfo.Get;

        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('Sheet1');

        ExcelMgt.FillCell('A7', CompanyInfo.Name + ' ' + CompanyInfo."Name 2");
        ExcelMgt.FillCell('AS7', CompanyInfo."OKPO Code");

        Employee.Get(CompanyInfo."Director No.");
        ExcelMgt.FillCell('J40', Employee.GetJobTitleName);
        ExcelMgt.FillCell('AP40', Employee.GetNameInitials);
    end;

    var
        CompanyInfo: Record "Company Information";
        HumResSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        RowNo: Integer;
}

