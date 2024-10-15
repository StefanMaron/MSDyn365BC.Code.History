report 17461 "Export SPV-1 form"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export SPV-1 form';
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

                TempEmployee := Employee;
                TempEmployee.Insert;
            end;

            trigger OnPostDataItem()
            var
                FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4;
            begin
                PersonifiedAccountingMgt.CheckData(0, ExportType, StartDate, EndDate, CreationDate);

                case ExportType of
                    ExportType::Excel:
                        PersonifiedAccountingMgt.SVFormToExcel(
                          FormType::SPV_1,
                          TempEmployee,
                          StartDate,
                          EndDate,
                          CreationDate,
                          InfoType,
                          '',
                          0);
                    ExportType::XML:
                        PersonifiedAccountingMgt.SVFormToXML(
                          FormType::SPV_1,
                          TempEmployee,
                          StartDate,
                          EndDate,
                          CreationDate,
                          InfoType,
                          CompanyPackNo,
                          DepartmentNo,
                          DepartmentPackNo,
                          '',
                          0);
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';

                        trigger OnValidate()
                        begin
                            PersonifiedAccountingMgt.CheckStartDate(StartDate);
                            EndDate := PersonifiedAccountingMgt.CalcEndDate(StartDate);
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
                    field(CreationDate; CreationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Creation Date';
                        ToolTip = 'Specifies when the report data was created.';
                    }
                    field(InfoType; InfoType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Information Type';
                        OptionCaption = 'Initial,Corrective,Cancel';
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
        TempEmployee: Record Employee temporary;
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
        StartDate: Date;
        EndDate: Date;
        CreationDate: Date;
        InfoType: Option Initial,Corrective,Cancel;
        ExportType: Option Excel,XML;
        CompanyPackNo: Integer;
        DepartmentNo: Integer;
        DepartmentPackNo: Integer;
}

