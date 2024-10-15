report 17456 "Paysheet T-51"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Paysheet T-51';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);

            trigger OnAfterGetRecord()
            var
                PayrollDocCalc: Codeunit "Payroll Document - Calculate";
                TotalCharged: Decimal;
                TotalDeduction: Decimal;
                WageAmount: Decimal;
                BonusAmount: Decimal;
                OtherGainAmount: Decimal;
                IncomeTaxAmount: Decimal;
                DeductionAmount: Decimal;
                AmountToPay: Decimal;
                WorkMode: Integer;
            begin
                if Number = 1 then
                    EmployeeList.FindFirst
                else
                    EmployeeList.Next;

                if Counter >= TemplateRowsQty then
                    ExcelMgt.CopyRow(RowNo);

                WorkMode := GetWorkMode(EmployeeList."No.");

                ExcelMgt.FillCell('A' + Format(RowNo), Format(Counter));
                ExcelMgt.FillCell('K' + Format(RowNo), EmployeeList."No.");
                ExcelMgt.FillCell('X' + Format(RowNo), EmployeeList."Last Name & Initials");
                ExcelMgt.FillCell('BF' + Format(RowNo), EmployeeList."Appointment Name");

                // tariff rate (salary)
                ExcelMgt.FillCell('BT' + Format(RowNo), Format(GetSalary(EmployeeList."No.")));

                // work days
                ExcelMgt.FillCell(
                  'CM' + Format(RowNo),
                  Format(
                    TimesheetMgt.GetTimesheetInfo(
                      EmployeeList."No.",
                      HumanResSetup."Work Time Group Code",
                      PayrollPeriod."Starting Date",
                      PayrollPeriod."Ending Date",
                      WorkMode)));

                // holidays days
                ExcelMgt.FillCell(
                  'CZ' + Format(RowNo),
                  Format(
                    TimesheetMgt.GetTimesheetInfo(
                      EmployeeList."No.",
                      HumanResSetup."Holiday Work Group",
                      PayrollPeriod."Starting Date",
                      PayrollPeriod."Ending Date",
                      WorkMode)));

                case DataSource of
                    DataSource::"Posted Entries":
                        begin
                            Employee.SetRange("Employee No. Filter", EmployeeList."No.");
                            Employee.SetRange("Payroll Period Filter", PayrollPeriod.Code);
                            Employee.SetRange("Element Type Filter", Employee."Element Type Filter"::Wage);
                            Employee.CalcFields("Payroll Amount");
                            WageAmount := Employee."Payroll Amount";

                            Employee.SetRange("Element Type Filter", Employee."Element Type Filter"::Bonus);
                            Employee.CalcFields("Payroll Amount");
                            BonusAmount := Employee."Payroll Amount";

                            Employee.SetRange("Element Type Filter", Employee."Element Type Filter"::Other);
                            Employee.CalcFields("Payroll Amount");
                            OtherGainAmount := Employee."Payroll Amount";

                            Employee.SetRange("Element Type Filter", Employee."Element Type Filter"::"Income Tax");
                            Employee.CalcFields("Payroll Amount");
                            IncomeTaxAmount := Employee."Payroll Amount";

                            Employee.SetRange("Element Type Filter", Employee."Element Type Filter"::Deduction);
                            Employee.CalcFields("Payroll Amount");
                            DeductionAmount := Employee."Payroll Amount";
                        end;
                    DataSource::"Payroll Documents":
                        begin
                            PayrollDoc.SetRange("Employee No.", EmployeeList."No.");
                            PayrollDoc.SetRange("Posting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
                            if PayrollDoc.FindSet then
                                repeat
                                    PayrollDocLine.Reset();
                                    PayrollDocLine.SetCurrentKey("Element Type", "Employee No.", "Period Code", "Posting Type");
                                    PayrollDocLine.SetRange("Document No.", PayrollDoc."No.");
                                    PayrollDocLine.SetRange(
                                      "Posting Type",
                                      PayrollDocLine."Posting Type"::Charge,
                                      PayrollDocLine."Posting Type"::Liability);
                                    PayrollDocLine.SetRange("Element Type", PayrollDocLine."Element Type"::Wage);
                                    PayrollDocLine.CalcSums("Payroll Amount");
                                    WageAmount += PayrollDocLine."Payroll Amount";

                                    PayrollDocLine.SetRange("Element Type", PayrollDocLine."Element Type"::Bonus);
                                    PayrollDocLine.CalcSums("Payroll Amount");
                                    BonusAmount += PayrollDocLine."Payroll Amount";

                                    PayrollDocLine.SetRange("Element Type", PayrollDocLine."Element Type"::Other);
                                    PayrollDocLine.CalcSums("Payroll Amount");
                                    OtherGainAmount += PayrollDocLine."Payroll Amount";

                                    PayrollDocLine.SetRange("Element Type", PayrollDocLine."Element Type"::"Income Tax");
                                    PayrollDocLine.CalcSums("Payroll Amount");
                                    IncomeTaxAmount += PayrollDocLine."Payroll Amount";

                                    PayrollDocLine.SetRange("Element Type", PayrollDocLine."Element Type"::Deduction);
                                    PayrollDocLine.CalcSums("Payroll Amount");
                                    DeductionAmount += PayrollDocLine."Payroll Amount";
                                until PayrollDoc.Next = 0;
                        end;
                end;

                TotalCharged := WageAmount + BonusAmount + OtherGainAmount;
                TotalDeduction := IncomeTaxAmount + DeductionAmount;

                // wage
                FillCell('DV', WageAmount);

                // bonus
                FillCell('EF', BonusAmount);

                // other gain
                FillCell('EZ', OtherGainAmount);

                // total
                FillCell('FO', TotalCharged);

                // income tax
                FillCell('FY', Abs(IncomeTaxAmount));

                // deduction
                FillCell('GJ', Abs(DeductionAmount));

                // total deduction
                FillCell('GT', Abs(TotalDeduction));

                // starting balance
                Employee.Get(EmployeeList."No.");
                Employee.TestField("Person No.");
                Person.Get(Employee."Person No.");
                Person.TestField("Vendor No.");
                Vendor.Get(Person."Vendor No.");
                Vendor.SetFilter("Date Filter", '..%1', CalcDate('<-CM - 1D>', PayrollPeriod."Ending Date"));
                Vendor.CalcFields("Net Change (LCY)");

                // debt
                if Vendor."Net Change (LCY)" < 0 then
                    // employee's debt
                    FillCell('HR', -Vendor."Net Change (LCY)")
                else
                    if Vendor."Net Change (LCY)" > 0 then
                        // company's debt
                        FillCell('HD', Vendor."Net Change (LCY)");

                // amount to pay
                AmountToPay := PayrollDocCalc.RoundAmountToPay(TotalCharged + TotalDeduction + Vendor."Net Change (LCY)");
                FillCell('IE', AmountToPay);

                RowNo += 1;
                Counter += 1;
            end;

            trigger OnPostDataItem()
            begin
                if Counter >= TemplateRowsQty then
                    ExcelMgt.DeleteRows(RowNo, RowNo);
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, EmployeeList.Count);
                Counter := 1;
                RowNo := 8;
                TemplateRowsQty := 29;

                EmployeeList.SetCurrentKey("Last Name & Initials");
                ExcelMgt.OpenSheet('Sheet2');
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
                    field(PeriodCode; PeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pay Period';
                        TableRelation = "Payroll Period";

                        trigger OnValidate()
                        begin
                            PeriodCodeOnAfterValidate;
                        end;
                    }
                    field(PreviewMode; PreviewMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
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
            PeriodCode := PeriodByDate(WorkDate);
            if PeriodCode <> '' then begin
                PayrollPeriod.Get(PeriodCode);
                DocNo :=
                  CopyStr(
                    Format(Date2DMY(PayrollPeriod."Starting Date", 3)), 3, 2) +
                  Format(Date2DMY(PayrollPeriod."Ending Date", 2)) + '-';
            end;

            RequestOptionsPage.Update;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TestMode then
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-51 Template Code"))
        else
            ExcelMgt.CloseBook;
    end;

    trigger OnPreReport()
    begin
        if PayrollDocLine.GetFilter("Org. Unit Code") <> '' then
            if Department.Get(PayrollDocLine.GetFilter("Org. Unit Code")) then
                DepartmentName := Department.Name;

        CompanyInfo.Get();

        HumanResSetup.Get();
        HumanResSetup.TestField("T-51 Template Code");
        HumanResSetup.TestField("Work Time Group Code");
        HumanResSetup.TestField("Holiday Work Group");

        case DataSource of
            DataSource::"Posted Entries":
                begin
                    PostedPayrollDoc.SetRange("Posting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
                    if PostedPayrollDoc.FindSet then
                        repeat
                            if not EmployeeBuffer.Get(PostedPayrollDoc."Employee No.") then begin
                                EmployeeBuffer."No." := PostedPayrollDoc."Employee No.";
                                EmployeeBuffer.Insert();
                            end;
                        until PostedPayrollDoc.Next = 0;
                end;
            DataSource::"Payroll Documents":
                begin
                    PayrollDoc.SetRange("Posting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
                    if PayrollDoc.FindSet then
                        repeat
                            if not EmployeeBuffer.Get(PayrollDoc."Employee No.") then begin
                                EmployeeBuffer."No." := PayrollDoc."Employee No.";
                                EmployeeBuffer.Insert();
                            end;
                        until PayrollDoc.Next = 0;
                end;
        end;

        if EmployeeBuffer.Find('-') then
            repeat
                Employee.Get(EmployeeBuffer."No.");

                EmployeeList."No." := EmployeeBuffer."No.";
                EmployeeList."Last Name & Initials" := Employee."Last Name" + ' ' + Employee.Initials;
                EmployeeList."Appointment Name" := Employee."Job Title";
                EmployeeList.Insert();
            until EmployeeBuffer.Next = 0;

        if PreviewMode then
            DocNo := 'XXXXXXXXXX'
        else begin
            HumanResSetup.TestField("Calculation Sheet Nos.");
            DocNo := NoSeriesMgt.GetNextNo(HumanResSetup."Calculation Sheet Nos.", WorkDate, true);
        end;

        FileName := ExcelTemplate.OpenTemplate(HumanResSetup."T-51 Template Code");
        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('Sheet1');
        ExcelMgt.FillCell('A7', CompanyInfo.Name + ' ' + CompanyInfo."Name 2");
        if DepartmentName <> '' then
            ExcelMgt.FillCell('A9', DepartmentName);
        ExcelMgt.FillCell('DE7', CompanyInfo."OKPO Code");
        ExcelMgt.FillCell('BF14', DocNo);
        ExcelMgt.FillCell('BY14', Format(Today));
        ExcelMgt.FillCell('CV14', Format(PayrollPeriod."Starting Date"));
        ExcelMgt.FillCell('DI14', Format(PayrollPeriod."Ending Date"));
    end;

    var
        Employee: Record Employee;
        Person: Record Person;
        Vendor: Record Vendor;
        EmployeeBuffer: Record Employee temporary;
        ExcelTemplate: Record "Excel Template";
        Department: Record "Organizational Unit";
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        PayrollDoc: Record "Payroll Document";
        PayrollDocLine: Record "Payroll Document Line";
        PostedPayrollDoc: Record "Posted Payroll Document";
        EmployeeList: Record "Payroll Calc List Line" temporary;
        PayrollPeriod: Record "Payroll Period";
        ExcelMgt: Codeunit "Excel Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        TimesheetMgt: Codeunit "Timesheet Management RU";
        PeriodCode: Code[10];
        FileName: Text[1024];
        DepartmentName: Text[250];
        DocNo: Code[10];
        Counter: Integer;
        PreviewMode: Boolean;
        RowNo: Integer;
        TemplateRowsQty: Integer;
        DataSource: Option "Posted Entries","Payroll Documents";
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure FillCell(ColumnCode: Code[10]; Amount: Decimal)
    begin
        if Amount <> 0 then
            ExcelMgt.FillCell(ColumnCode + Format(RowNo), Format(Amount));
    end;

    [Scope('OnPrem')]
    procedure GetWorkMode(EmployeeNo: Code[20]): Integer
    var
        EmplLedgerEntry: Record "Employee Ledger Entry";
    begin
        if HumanResSetup."Element Code Salary Days" <> '' then
            if FindEmplLedgerEntry(EmployeeNo, HumanResSetup."Element Code Salary Days", EmplLedgerEntry) then
                exit(4);

        if HumanResSetup."Element Code Salary Hours" <> '' then
            if FindEmplLedgerEntry(EmployeeNo, HumanResSetup."Element Code Salary Hours", EmplLedgerEntry) then
                exit(3);

        if HumanResSetup."Element Code Salary Amount" <> '' then
            if FindEmplLedgerEntry(EmployeeNo, HumanResSetup."Element Code Salary Amount", EmplLedgerEntry) then
                exit(3);

        exit(4);
    end;

    [Scope('OnPrem')]
    procedure GetSalary(EmployeeNo: Code[20]): Decimal
    var
        EmplLedgerEntry: Record "Employee Ledger Entry";
    begin
        if HumanResSetup."Element Code Salary Days" <> '' then
            if FindEmplLedgerEntry(EmployeeNo, HumanResSetup."Element Code Salary Days", EmplLedgerEntry) then
                exit(EmplLedgerEntry.Amount);

        if HumanResSetup."Element Code Salary Hours" <> '' then
            if FindEmplLedgerEntry(EmployeeNo, HumanResSetup."Element Code Salary Hours", EmplLedgerEntry) then
                exit(EmplLedgerEntry.Amount);

        if HumanResSetup."Element Code Salary Amount" <> '' then
            if FindEmplLedgerEntry(EmployeeNo, HumanResSetup."Element Code Salary Amount", EmplLedgerEntry) then
                exit(EmplLedgerEntry.Amount);
    end;

    [Scope('OnPrem')]
    procedure FindEmplLedgerEntry(EmployeeNo: Code[20]; ElementCode: Code[20]; var EmplLedgerEntry: Record "Employee Ledger Entry"): Boolean
    begin
        EmplLedgerEntry.SetCurrentKey("Employee No.", "Action Starting Date", "Action Ending Date", "Element Code");
        EmplLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmplLedgerEntry.SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
        EmplLedgerEntry.SetFilter("Action Ending Date", '%1|%2..', 0D, PayrollPeriod."Starting Date");
        EmplLedgerEntry.SetRange("Element Code", ElementCode);
        exit(EmplLedgerEntry.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure PeriodByDate(Date: Date): Code[10]
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Reset();
        PayrollPeriod.SetFilter("Ending Date", '%1..', Date);
        if PayrollPeriod.FindFirst then
            if PayrollPeriod."Starting Date" <= Date then
                exit(PayrollPeriod.Code);

        exit('');
    end;

    local procedure PeriodCodeOnAfterValidate()
    begin
        PayrollPeriod.Get(PeriodCode);
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean; NewPeriodCode: Code[10]; NewDataSource: Option)
    begin
        TestMode := NewTestMode;
        PeriodCode := NewPeriodCode;
        DataSource := NewDataSource;
    end;
}

