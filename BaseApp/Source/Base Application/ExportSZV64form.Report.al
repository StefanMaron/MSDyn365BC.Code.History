report 17464 "Export SZV-6-4 form"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export SZV-6-4 form';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if not PersonifiedAccountingMgt.CheckEmployeeLaborContract(Employee, StartDate, EndDate) then
                    CurrReport.Skip;

                TempEmployee_SZV6_4 := Employee;
                TempEmployee_SZV6_4.Insert;
            end;

            trigger OnPostDataItem()
            var
                FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4;
            begin
                PersonifiedAccountingMgt.CheckData(1, ExportType, StartDate, EndDate, CreationDate);
                StartDate := CalcDate('<-CM-2M>', EndDate);

                case ExportType of
                    ExportType::Excel:
                        PersonifiedAccountingMgt.SVFormToExcel(
                          FormType::SZV_6_4,
                          TempEmployee_SZV6_4,
                          StartDate,
                          EndDate,
                          CreationDate,
                          InfoType,
                          CurrentReportName,
                          0);
                    ExportType::XML:
                        begin
                            PersonifiedAccountingMgt.SVFormToXML(
                              FormType::SZV_6_4,
                              TempEmployee_SZV6_4,
                              StartDate,
                              EndDate,
                              CreationDate,
                              InfoType,
                              CompanyPackNo,
                              DepartmentNo,
                              DepartmentPackNo,
                              CurrentReportName,
                              0);
                            CompanyPackNo += 1;
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';

                        trigger OnValidate()
                        begin
                            PersonifiedAccountingMgt.CheckStartDate(StartDate);
                            StartDateOnAfterValidate;
                        end;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';

                        trigger OnValidate()
                        begin
                            PersonifiedAccountingMgt.CheckEndDate(EndDate);
                        end;
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

        trigger OnOpenPage()
        begin
            CreationDate := Today;
        end;
    }

    labels
    {
    }

    var
        TempEmployee_SZV6_4: Record Employee temporary;
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        CreationDate: Date;
        InfoType: Option Initial,Corrective,Cancel;
        ExportType: Option Excel,XML;
        CurrentReportName: Code[10];
        StartDate: Date;
        EndDate: Date;
        CompanyPackNo: Integer;
        DepartmentNo: Integer;
        DepartmentPackNo: Integer;

    local procedure StartDateOnAfterValidate()
    begin
        EndDate := PersonifiedAccountingMgt.CalcEndDate(StartDate);
    end;
}

