namespace Microsoft.Finance.FinancialReports;

report 39 "Copy Financial Report"
{
    Caption = 'Copy Financial Report';
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourceFinancialReport; "Financial Report")
        {
            DataItemTableView = sorting(Name) order(ascending);

            trigger OnAfterGetRecord()
            var
                FinancialReport: Record "Financial Report";
            begin
                FinancialReport.Get(CopySourceFinancialReportName);
                CreateNewFinancialReport(NewFinancialReportName, FinancialReport);
            end;

            trigger OnPreDataItem()
            begin
                AssertNewFinancialReportNotEmpty();
                AssertNewFinancialReportNotExisting();
                AssertSourceFinancialReportNotEmpty();
                AssertSourceFinancialReportExists(SourceFinancialReport);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewFinancialReportNameField; NewFinancialReportName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Financial Report Name';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new financial report after copying.';
                    }
                    field(SourceAccountScheduleName; CopySourceFinancialReportName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Financial Report Name';
                        Enabled = false;
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the existing financial report to copy from.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            AssertSourceFinancialReportOnlyOne(SourceFinancialReport);

            if SourceFinancialReport.FindFirst() then
                CopySourceFinancialReportName := SourceFinancialReport.Name;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(CopySuccessMsg);
    end;

    var
        NewFinancialReportName: Code[10];
        CopySuccessMsg: Label 'The new financial report has been created successfully.';
        MissingSourceErr: Label 'Could not find a financial report with the specified name to copy from.';
        NewNameExistsErr: Label 'The new financial report already exists.';
        NewNameMissingErr: Label 'You must specify a name for the new financial report.';
        CopySourceFinancialReportName: Code[10];
        CopySourceNameMissingErr: Label 'You must specify a valid name for the source financial report to copy from.';
        MultipleSourcesErr: Label 'You can only copy one financial report at a time.';

    local procedure AssertNewFinancialReportNotEmpty()
    begin
        if IsEmptyName(NewFinancialReportName) then
            Error(NewNameMissingErr);
    end;

    local procedure AssertNewFinancialReportNotExisting()
    var
        FinancialReport: Record "Financial Report";
    begin
        if FinancialReport.Get(NewFinancialReportName) then
            Error(NewNameExistsErr);
    end;

    local procedure CreateNewFinancialReport(NewName: Code[10]; FinancialReportName: Record "Financial Report")
    var
        FinancialReport: Record "Financial Report";
    begin
        if FinancialReport.Get(NewName) then
            exit;

        FinancialReport.Init();
        FinancialReport.TransferFields(FinancialReportName);
        FinancialReport.Name := NewName;
        FinancialReport.Insert();
    end;

    local procedure IsEmptyName(ScheduleName: Code[10]) IsEmpty: Boolean
    begin
        IsEmpty := ScheduleName = '';
    end;

    local procedure AssertSourceFinancialReportNotEmpty()
    begin
        if IsEmptyName(CopySourceFinancialReportName) then
            Error(CopySourceNameMissingErr);
    end;

    local procedure AssertSourceFinancialReportExists(FinancialReportName: Record "Financial Report")
    begin
        if not FinancialReportName.Get(CopySourceFinancialReportName) then
            Error(MissingSourceErr);
    end;

    local procedure AssertSourceFinancialReportOnlyOne(var FinancialReportName: Record "Financial Report")
    var
        FinancialReport: Record "Financial Report";
    begin
        FinancialReport.CopyFilters(FinancialReportName);

        if FinancialReport.Count > 1 then
            Error(MultipleSourcesErr);
    end;
}

