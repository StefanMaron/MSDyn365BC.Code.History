report 17470 "Export RSV form"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export RSV form';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Person; Person)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                Employee: Record Employee;
            begin
                Employee.SetRange("Person No.", "No.");
                if Employee.IsEmpty then
                    CurrReport.Skip();

                TempPerson := Person;
                TempPerson.Insert();
            end;

            trigger OnPostDataItem()
            var
                TempPackPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
                RSVExcelExport: Codeunit "RSV Excel Export";
                RSVDetailedXMLExport: Codeunit "RSV Detailed XML Export";
                RSVCommonXMLExport: Codeunit "RSV Common XML Export";
            begin
                case ExportType of
                    ExportType::Excel:
                        RSVExcelExport.ExportRSVToExcel(
                          TempPerson,
                          DatePeriod."Period Start",
                          DatePeriod."Period End",
                          InfoType);
                    ExportType::XML:
                        begin
                            RSVDetailedXMLExport.ExportDetailedXML(
                              TempPerson,
                              TempPackPayrollReportingBuffer,
                              DatePeriod."Period Start",
                              DatePeriod."Period End",
                              CreationDate,
                              InfoType,
                              FolderName);
                            RSVCommonXMLExport.ExportCommonXML(
                              TempPerson,
                              TempPackPayrollReportingBuffer,
                              DatePeriod."Period Start",
                              DatePeriod."Period End",
                              CreationDate,
                              FolderName);
                        end;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AccountingPeriod; AccountPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accounting Period';
                        ToolTip = 'Specifies the accounting period to include data for.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriod, true);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, true);
                            RequestOptionsPage.Update(false);
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, true);
                        end;
                    }
                    field(PeriodStartDate; DatePeriod."Period Start")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';
                        Editable = false;
                    }
                    field(PeriodEndDate; DatePeriod."Period End")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';
                        Editable = false;
                    }
                    field(InfoType; InfoType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Information Type';
                        OptionCaption = 'Initial,Corrective,Cancel';
                    }
                    field(CreationDate; CreationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Creation Date';
                        ToolTip = 'Specifies when the report data was created.';
                    }
                    field(ExportType; ExportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Type';
                        OptionCaption = 'Excel,XML';
                        ToolTip = 'Specifies how report requisite values are exported. Export types include Required, Non-required, Conditionally Required, and Set.';

                        trigger OnValidate()
                        begin
                            FolderNameEditable := ExportType = ExportType::XML;
                        end;
                    }
                    field(FolderName; FolderName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Folder Name';
                        Editable = FolderNameEditable;

#if not CLEAN17
                        trigger OnAssistEdit()
                        var
                            FileMgt: Codeunit "File Management";
                        begin
                            FolderName := FileMgt.BrowseForFolderDialog(SelectExportFolderTxt, '', true);
                        end;
#endif
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DatePeriod.SetRange("Period Type", 3); // quarter
            DatePeriod.SetRange("Period Start", 0D, WorkDate);
            if DatePeriod.FindLast then;

            CalendarPeriod.Copy(DatePeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, true);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, true);
        end;

        trigger OnOpenPage()
        begin
            if CreationDate = 0D then
                CreationDate := Today;
            FolderNameEditable := ExportType = ExportType::XML;
        end;
    }

    labels
    {
    }

    var
        TempPerson: Record Person temporary;
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        AccountPeriod: Text[30];
        FolderName: Text;
        [InDataSet]
        FolderNameEditable: Boolean;
        CreationDate: Date;
        InfoType: Option Initial,Corrective,Cancel;
        ExportType: Option Excel,XML;
        SelectExportFolderTxt: Label 'Select Export Folder';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewAccountPeriod: Text[30]; NewCreationDate: Date; NewExportType: Option; NewFolderName: Text)
    begin
        AccountPeriod := NewAccountPeriod;
        CreationDate := NewCreationDate;
        ExportType := NewExportType;
        FolderName := NewFolderName;
    end;
}

