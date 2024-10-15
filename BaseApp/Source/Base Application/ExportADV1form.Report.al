report 17460 "Export ADV-1 form"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export ADV-1 form';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.";

            trigger OnPostDataItem()
            begin
                case ExportType of
                    ExportType::Excel:
                        PersonifiedAccountingMgt.ADV1toExcel(Employee, FillingDate);
                    ExportType::XML:
                        PersonifiedAccountingMgt.ADV1toXML(
                          Employee,
                          FillingDate,
                          CompanyPackNo,
                          DepartmentNo,
                          DepartmentPackNo);
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
                    field(FillingDate; FillingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Filling Date';
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
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if FillingDate = 0D then
            FillingDate := Today;
    end;

    var
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
        ExportType: Option Excel,XML;
        CompanyPackNo: Integer;
        DepartmentNo: Integer;
        DepartmentPackNo: Integer;
        FillingDate: Date;
}

