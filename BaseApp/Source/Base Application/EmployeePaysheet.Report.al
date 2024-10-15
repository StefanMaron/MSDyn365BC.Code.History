report 17458 "Employee Paysheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Paysheet';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("Org. Unit Code", "Last Name", "First Name", "Middle Name") WHERE(Blocked = CONST(false));
            RequestFilterFields = "No.", "Org. Unit Code", "Global Dimension 1 Code", "Statistics Group Code";
            dataitem(CollectEntries; "Integer")
            {
                DataItemTableView = SORTING(Number);

                trigger OnAfterGetRecord()
                begin
                    if AddBuffer.FindSet then
                        repeat
                            if AddBuffer."Payroll Amount" <> 0 then begin
                                FillBody(AddBuffer);
                                TotalAdded += AddBuffer."Payroll Amount";
                                TotalDays += AddBuffer."Actual Days";
                                TotalHours += AddBuffer."Actual Hours";
                            end;
                        until AddBuffer.Next() = 0;

                    if DeductBuffer.FindSet then
                        repeat
                            if DeductBuffer."Payroll Amount" <> 0 then begin
                                FillBody(DeductBuffer);
                                TotalDeducted += DeductBuffer."Payroll Amount";
                                TotalDays += DeductBuffer."Actual Days";
                                TotalHours += DeductBuffer."Actual Hours";
                            end;
                        until DeductBuffer.Next() = 0;

                    if OtherGainBuffer.FindSet then
                        repeat
                            if OtherGainBuffer."Payroll Amount" <> 0 then begin
                                FillBody(OtherGainBuffer);
                                TotalDays += DeductBuffer."Actual Days";
                                TotalHours += DeductBuffer."Actual Hours";
                            end;
                        until OtherGainBuffer.Next() = 0;

                    if IncomeTaxBuffer.FindSet then
                        repeat
                            if IncomeTaxBuffer."Payroll Amount" <> 0 then begin
                                FillBody(IncomeTaxBuffer);
                                TotalDeducted += IncomeTaxBuffer."Payroll Amount";
                            end;
                        until IncomeTaxBuffer.Next() = 0;

                    FillTotals;
                    ExcelReportBuilderMgr.AddSection('DueTaxRedemptionSection');
                    ExcelReportBuilderMgr.AddSection('PaidTaxRedemptionSection');
                    ExcelReportBuilderMgr.AddSection('CompanyDebtSection');
                    ExcelReportBuilderMgr.AddSection('EmplDebtSection');
                    ExcelReportBuilderMgr.AddSection('Separator');
                    ExcelReportBuilderMgr.AddPagebreak;
                    CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not PayrollAmountExists then
                    CurrReport.Skip();

                FillInBuffers;
                FillHeader;
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
                    field(StartingDate; DateBegin)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';

                        trigger OnValidate()
                        begin
                            DateEnd := CalcDate('<CM>', DateBegin);
                        end;
                    }
                    field(EndingDate; DateEnd)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(DataSource; DataSource)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Source';
                        OptionCaption = 'Posted Entries,Payroll Documents';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            DateBegin := CalcDate('<-1M-CM>', WorkDate);
            DateEnd := CalcDate('<CM>', DateBegin);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if PayrollDocExist and (FileName <> '') then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            if PayrollDocExist then
                ExcelReportBuilderMgr.ExportData;
    end;

    trigger OnPreReport()
    begin
        InitReportTemplate;
    end;

    var
        PayrollDoc: Record "Payroll Document";
        PayrollDocLine: Record "Payroll Document Line";
        PostedPayrollDoc: Record "Posted Payroll Document";
        AddBuffer: Record "Payroll Document Line" temporary;
        DeductBuffer: Record "Payroll Document Line" temporary;
        OtherGainBuffer: Record "Payroll Document Line" temporary;
        IncomeTaxBuffer: Record "Payroll Document Line" temporary;
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollElement: Record "Payroll Element";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        DateBegin: Date;
        DateEnd: Date;
        DataSource: Option "Posted Entries","Payroll Documents";
        PayrollDocExist: Boolean;
        TotalAdded: Decimal;
        TotalDeducted: Decimal;
        TotalDays: Decimal;
        TotalHours: Decimal;
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        SheetName: Text;
    begin
        SheetName := 'Sheet1';
        ExcelReportBuilderMgr.InitTemplate(GetTemplateCode);
        ExcelReportBuilderMgr.SetSheet(SheetName);
    end;

    [Scope('OnPrem')]
    procedure FillHeader()
    begin
        ExcelReportBuilderMgr.AddSection('EmplHeader');
        ExcelReportBuilderMgr.AddDataToSection('PayPeriod', Format(DateEnd, 0, '<Month Text> <Year4>'));
        ExcelReportBuilderMgr.AddDataToSection('EmplId', Employee."No.");
        ExcelReportBuilderMgr.AddDataToSection('EmplName', Employee."First Name" + ' ' + Employee."Last Name");
        ExcelReportBuilderMgr.AddDataToSection('OrganizationId', Employee."Org. Unit Code");
        ExcelReportBuilderMgr.AddDataToSection('OrganizationName', Employee."Org. Unit Name");
        ExcelReportBuilderMgr.AddSection('EmplPageHeader');

        FillHeaderTitle;
    end;

    [Scope('OnPrem')]
    procedure FillHeaderTitle()
    begin
        ExcelReportBuilderMgr.AddSection('Header');
    end;

    [Scope('OnPrem')]
    procedure FillBody(var BufferLine: Record "Payroll Document Line" temporary)
    begin
        ExcelReportBuilderMgr.AddSection('Body');
        ExcelReportBuilderMgr.AddDataToSection('PayCType', BufferLine."Element Code");
        ExcelReportBuilderMgr.AddDataToSection('PayName', BufferLine.Description);
        ExcelReportBuilderMgr.AddDataToSection('SourceDate', BufferLine."Period Code");
        ExcelReportBuilderMgr.AddDataToSection('Days', StdRepMgt.FormatReportValue(BufferLine."Actual Days", 2));
        ExcelReportBuilderMgr.AddDataToSection('Hours', StdRepMgt.FormatReportValue(BufferLine."Actual Hours", 2));
        if BufferLine."Payroll Amount" > 0 then
            ExcelReportBuilderMgr.AddDataToSection('AddSum', StdRepMgt.FormatReportValue(BufferLine."Payroll Amount", 2))
        else
            ExcelReportBuilderMgr.AddDataToSection(
              'Deduction', StdRepMgt.FormatReportValue(Abs(BufferLine."Payroll Amount"), 2));
    end;

    [Scope('OnPrem')]
    procedure FillTotals()
    begin
        ExcelReportBuilderMgr.AddSection('Total');
        ExcelReportBuilderMgr.AddDataToSection('DaysTotal', StdRepMgt.FormatReportValue(TotalDays, 2));
        ExcelReportBuilderMgr.AddDataToSection('HoursTotal', StdRepMgt.FormatReportValue(TotalHours, 2));
        ExcelReportBuilderMgr.AddDataToSection('AddSumTotal', StdRepMgt.FormatReportValue(TotalAdded, 2));
        ExcelReportBuilderMgr.AddDataToSection('DeductionTotal', StdRepMgt.FormatReportValue(Abs(TotalDeducted), 2));
        ExcelReportBuilderMgr.AddDataToSection('SumOnHand', StdRepMgt.FormatReportValue(TotalAdded + TotalDeducted, 2));
    end;

    local procedure GetTemplateCode(): Code[10]
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Employee Paysheet Templ. Code");
        exit(HumanResourcesSetup."Employee Paysheet Templ. Code");
    end;

    [Scope('OnPrem')]
    procedure PayrollAmountExists(): Boolean
    begin
        case DataSource of
            DataSource::"Posted Entries":
                begin
                    PostedPayrollDoc.SetRange("Employee No.", Employee."No.");
                    PostedPayrollDoc.SetRange("Posting Date", DateBegin, DateEnd);
                    if PostedPayrollDoc.FindFirst then begin
                        PayrollDocExist := true;
                        exit(PayrollDocExist);
                    end;
                end;
            DataSource::"Payroll Documents":
                begin
                    PayrollDoc.SetRange("Employee No.", Employee."No.");
                    PayrollDoc.SetRange("Posting Date", DateBegin, DateEnd);
                    if PayrollDoc.FindFirst then begin
                        PayrollDocExist := true;
                        exit(PayrollDocExist);
                    end;
                end;
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FillInBuffers()
    begin
        AddBuffer.DeleteAll();
        DeductBuffer.DeleteAll();
        OtherGainBuffer.DeleteAll();
        IncomeTaxBuffer.DeleteAll();
        TotalAdded := 0;
        TotalDeducted := 0;
        TotalDays := 0;
        TotalHours := 0;

        case DataSource of
            DataSource::"Posted Entries":
                with PostedPayrollDocLine do begin
                    SetRange("Document No.", PostedPayrollDoc."No.");
                    if FindSet then
                        repeat
                            if PayrollElement.Get("Element Code") then
                                case "Element Type" of
                                    "Element Type"::Wage,
                                    "Element Type"::Bonus:
                                        begin
                                            AddBuffer.TransferFields(PostedPayrollDocLine);
                                            AddBuffer.Description := PayrollElement.Description;
                                            AddBuffer.Insert();
                                        end;
                                    "Element Type"::Deduction,
                                    "Element Type"::"Tax Deduction":
                                        begin
                                            DeductBuffer.TransferFields(PostedPayrollDocLine);
                                            DeductBuffer.Description := PayrollElement.Description;
                                            DeductBuffer.Insert();
                                        end;
                                    "Element Type"::Other:
                                        begin
                                            OtherGainBuffer.TransferFields(PostedPayrollDocLine);
                                            OtherGainBuffer.Description := PayrollElement.Description;
                                            OtherGainBuffer.Insert();
                                        end;
                                    "Element Type"::"Income Tax":
                                        begin
                                            IncomeTaxBuffer.TransferFields(PostedPayrollDocLine);
                                            IncomeTaxBuffer.Description := PayrollElement.Description;
                                            IncomeTaxBuffer.Insert();
                                        end;
                                end;
                        until Next() = 0;
                end;
            DataSource::"Payroll Documents":
                with PayrollDocLine do begin
                    SetRange("Document No.", PayrollDoc."No.");
                    if FindSet then
                        repeat
                            if PayrollElement.Get("Element Code") then
                                case "Element Type" of
                                    "Element Type"::Wage,
                                    "Element Type"::Bonus:
                                        begin
                                            AddBuffer.TransferFields(PayrollDocLine);
                                            AddBuffer.Description := PayrollElement.Description;
                                            AddBuffer.Insert();
                                        end;
                                    "Element Type"::Deduction,
                                    "Element Type"::"Tax Deduction":
                                        begin
                                            DeductBuffer.TransferFields(PayrollDocLine);
                                            DeductBuffer.Description := PayrollElement.Description;
                                            DeductBuffer.Insert();
                                        end;
                                    "Element Type"::Other:
                                        begin
                                            OtherGainBuffer.TransferFields(PayrollDocLine);
                                            OtherGainBuffer.Description := PayrollElement.Description;
                                            OtherGainBuffer.Insert();
                                        end;
                                    "Element Type"::"Income Tax":
                                        begin
                                            IncomeTaxBuffer.TransferFields(PayrollDocLine);
                                            IncomeTaxBuffer.Description := PayrollElement.Description;
                                            IncomeTaxBuffer.Insert();
                                        end;
                                end;
                        until Next() = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewDateBegin: Date; NewDateEnd: Date; NewDataSource: Option)
    begin
        DateBegin := NewDateBegin;
        DateEnd := NewDateEnd;
        DataSource := NewDataSource;
    end;
}

