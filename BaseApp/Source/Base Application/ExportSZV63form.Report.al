report 17463 "Export SZV-6-3 form"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export SZV-6-3 form';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if InfoType = InfoType::Initial then begin
                    if not PersonifiedAccountingMgt.CheckEmployeeLaborContract(Employee, DMY2Date(1, 1, PeriodYear), DMY2Date(31, 12, PeriodYear)) then
                        CurrReport.Skip();
                end else
                    if not PersonifiedAccountingMgt.CheckEmployeeLaborContract(
                         Employee, DMY2Date(1, 1, CorrectionalPeriodYear), DMY2Date(31, 12, CorrectionalPeriodYear))
                    then
                        CurrReport.Skip();

                TempEmployee_SZV6_3 := Employee;
                TempEmployee_SZV6_3.Insert();
            end;

            trigger OnPostDataItem()
            var
                FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4;
            begin
                PersonifiedAccountingMgt.CheckData(1, ExportType, PeriodStartDate, PeriodEndDate, CreationDate);

                case ExportType of
                    ExportType::Excel:
                        PersonifiedAccountingMgt.SVFormToExcel(
                          FormType::SZV_6_3,
                          TempEmployee_SZV6_3,
                          PeriodStartDate,
                          PeriodEndDate,
                          CreationDate,
                          InfoType,
                          CurrentReportName,
                          CorrectionalPeriodYear);
                    ExportType::XML:
                        begin
                            PersonifiedAccountingMgt.SVFormToXML(
                              FormType::SZV_6_3,
                              TempEmployee_SZV6_3,
                              PeriodStartDate,
                              PeriodEndDate,
                              CreationDate,
                              InfoType,
                              CompanyPackNo,
                              DepartmentNo,
                              DepartmentPackNo,
                              CurrentReportName,
                              CorrectionalPeriodYear);
                            CompanyPackNo += 1;
                        end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                PeriodStartDate := DMY2Date(1, 1, PeriodYear);
                PeriodEndDate := DMY2Date(31, 12, PeriodYear);
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
                    field(CurrentReportName; CurrentReportName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Analysis Report Name';
                        ToolTip = 'Specifies the name of the analysis report.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PayrollAnalysisReportMgt.LookupReportName(CurrentReportName) then begin
                                Text := CurrentReportName;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            PayrollAnalysisReportMgt.CheckReportName(CurrentReportName);
                        end;
                    }
                    field(PeriodYear; PeriodYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Year';
                    }
                    field(InfoType; InfoType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Information Type';
                        OptionCaption = 'Initial,Corrective,Cancel';

                        trigger OnValidate()
                        begin
                            InfoTypeOnAfterValidate;
                        end;
                    }
                    field(CorrPeriodYearControl; CorrectionalPeriodYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Correctional Period Year';
                        Enabled = CorrPeriodYearControlEnable;
                    }
                    field(CreationDate; CreationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Creation Date';
                        ToolTip = 'Specifies when the report data was created.';
                    }
                    field(CompanyPackNo; CompanyPackNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Pack No.';
                    }
                    field(DepartmentNo; DepartmentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Department No.';
                    }
                    field(DepartmentPackNo; DepartmentPackNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Department Pack No.';
                    }
                    field(ExportType; ExportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Type';
                        OptionCaption = 'Excel,XML';
                        ToolTip = 'Specifies how report requisite values are exported. Export types include Required, Non-required, Conditionally Required, and Set.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CorrPeriodYearControlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            CreationDate := Today;
            PeriodYear := Date2DMY(Today, 3);
            CorrectionalPeriodYear := Date2DMY(Today, 3);
            UpdateControls;
        end;
    }

    labels
    {
    }

    var
        TempEmployee_SZV6_3: Record Employee temporary;
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        CreationDate: Date;
        InfoType: Option Initial,Corrective,Cancel;
        ExportType: Option Excel,XML;
        PeriodYear: Integer;
        CorrectionalPeriodYear: Integer;
        CurrentReportName: Code[10];
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        [InDataSet]
        CorrPeriodYearControlEnable: Boolean;
        CompanyPackNo: Integer;
        DepartmentNo: Integer;
        DepartmentPackNo: Integer;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        PageUpdateControls;
    end;

    local procedure InfoTypeOnAfterValidate()
    begin
        UpdateControls;
    end;

    local procedure PageUpdateControls()
    begin
        CorrPeriodYearControlEnable := InfoType <> InfoType::Initial;
    end;
}

