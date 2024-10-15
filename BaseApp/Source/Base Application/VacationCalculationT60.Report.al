report 17364 "Vacation Calculation T-60"
{
    Caption = 'Vacation Calculation T-60';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Posted Absence Header"; "Posted Absence Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Vacation));
            RequestFilterFields = "No.";
            dataitem("Posted Absence Line"; "Posted Absence Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    PayrollDocLine: Record "Payroll Document Line";
                    PayrollCalculation: Record "Payroll Calculation";
                    PayrollCalcLineRounding: Record "Payroll Calculation Line";
                    PayrollDocLineCalc: Record "Payroll Document Line Calc.";
                    PayrollDocCalculate: Codeunit "Payroll Document - Calculate";
                    IncomeTaxAmount: Decimal;
                begin

                    TimeActivity.Get("Time Activity Code");

                    EmplAbsenceEntry.Reset;
                    EmplAbsenceEntry.SetCurrentKey("Employee No.");
                    EmplAbsenceEntry.SetRange("Employee No.", "Employee No.");
                    EmplAbsenceEntry.SetRange("Time Activity Code", "Time Activity Code");
                    EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Usage);
                    EmplAbsenceEntry.SetRange("Document Type", "Document Type");
                    EmplAbsenceEntry.SetRange("Document No.", "Document No.");

                    if "Vacation Type" < "Vacation Type"::Additional then begin
                        if EmplAbsenceEntry.FindFirst then begin
                            if EmplAbsenceEntry2.Get(EmplAbsenceEntry."Accrual Entry No.") then begin
                                ExcelMgt.FillCell('V22', LocMgt.Date2Text(EmplAbsenceEntry2."Start Date"));
                                ExcelMgt.FillCell('V22', LocMgt.Date2Text(EmplAbsenceEntry2."End Date"));
                            end;
                        end;
                        ExcelMgt.FillCell('E24', Format("Calendar Days"));
                        ExcelMgt.FillCell('D27', LocMgt.Date2Text("Start Date"));
                        ExcelMgt.FillCell('AQ27', LocMgt.Date2Text("End Date"));
                    end else begin
                        ExcelMgt.FillCell('BI29', Format("Calendar Days"));
                        FillLastVacations("Employee No.");
                    end;

                    ExcelMgt.FillCell('BI40', Format("Calendar Days"));
                    ExcelMgt.FillCell('D43', LocMgt.Date2Text("Start Date"));
                    ExcelMgt.FillCell('AQ43', LocMgt.Date2Text("End Date"));

                    FirstLine := true;
                    PostedPayrollDocLine.Reset;
                    PostedPayrollDocLine.SetCurrentKey("Document Type", "HR Order No.");
                    PostedPayrollDocLine.SetRange("Document Type", "Document Type" + 1);
                    PostedPayrollDocLine.SetRange("HR Order No.", "Document No.");
                    PostedPayrollDocLine.SetRange("Employee No.", "Employee No.");
                    PostedPayrollDocLine.SetRange("Element Code", "Element Code");
                    if PostedPayrollDocLine.FindSet then begin
                        repeat
                            if not CalcGroupTypeIsBetween(PostedPayrollDocLine."Document No.") then begin
                                if FirstLine then begin
                                    // ¬«½-ó« ¬á½Ñ¡ñáÓ¡ÙÕ ñ¡Ñ® ÓáßþÑÔ¡«ú« »ÑÓ¿«ñá
                                    PostedPayrollDocLine.CalcFields("AE Total Days", "AE Total Earnings");
                                    ExcelMgt.FillCell('BL52', Format(PostedPayrollDocLine."AE Total Days"));
                                    // ßÓÑñ¡¿® ñ¡Ñó¡«® ºáÓáí«Ô«¬
                                    ExcelMgt.FillCell('DB52', Format(PostedPayrollDocLine."AE Daily Earnings"));
                                    // ¿Ô«ú«
                                    ExcelMgt.FillCell('AF64', Format(PostedPayrollDocLine."AE Total Earnings"));

                                    RowNo := 52;
                                    PostedPayrollPeriodAE.SetRange("Document No.", PostedPayrollDocLine."Document No.");
                                    PostedPayrollPeriodAE.SetRange("Line No.", PostedPayrollDocLine."Line No.");
                                    if PostedPayrollPeriodAE.FindSet then
                                        repeat
                                            ExcelMgt.FillCell('A' + Format(RowNo), Format(PostedPayrollPeriodAE.Year));
                                            ExcelMgt.FillCell('Q' + Format(RowNo), Format(PostedPayrollPeriodAE.Month));
                                            ExcelMgt.FillCell('AF' + Format(RowNo),
                                              Format(PostedPayrollPeriodAE."Salary Amount" + PostedPayrollPeriodAE."Bonus Amount"));
                                            RowNo += 1;
                                        until PostedPayrollPeriodAE.Next = 0;
                                    // çá ÔÑ¬ÒÚ¿® ¼Ñß´µ
                                    ExcelMgt.FillCell('K67', LocMgt.GetMonthName("Start Date", true));
                                    if "End Date" <= CalcDate('<CM>', "Posted Absence Line"."Start Date") then
                                        CurrMonthDate := "End Date"
                                    else
                                        CurrMonthDate := CalcDate('<CM>', "Posted Absence Line"."Start Date");
                                    CurrMonthDays :=
                                      CalendarMgt.GetPeriodInfo(PostedPayrollDocLine."Calendar Code",
                                      "Posted Absence Line"."Start Date", CurrMonthDate, 1) -
                                      CalendarMgt.GetPeriodInfo(PostedPayrollDocLine."Calendar Code",
                                      "Posted Absence Line"."Start Date", CurrMonthDate, 4);
                                    ExcelMgt.FillCell('A72', Format(CurrMonthDays));
                                    ExcelMgt.FillCell('P72', Format(CurrMonthDays * PostedPayrollDocLine."AE Daily Earnings"));
                                    FirstAmt := PostedPayrollDocLine."Payroll Amount";
                                end;
                                FirstLine := not FirstLine;
                                // éßÑú« ¡áþ¿ß½Ñ¡«
                                TotalAmt += PostedPayrollDocLine."Payroll Amount";
                            end;
                        until PostedPayrollDocLine.Next = 0;

                        PayrollDocLine."Element Code" := HRSetup."Income Tax 13%";
                        PayrollDocLine."Period Code" := PostedPayrollDocLine."Period Code";
                        PayrollDocLine."Corr. Amount" := TotalAmt;
                        IncomeTaxAmount := PayrollDocCalculate.Withholding(PayrollDocLine, TotalAmt);
                        PayrollCalculation.SetRange("Element Code", HRSetup."Income Tax 13%");
                        PayrollCalculation.SetRange("Period Code", '', PayrollDocLine."Period Code");
                        if PayrollCalculation.FindLast then begin
                            PayrollCalcLineRounding.SetRange("Element Code", PayrollCalculation."Element Code");
                            PayrollCalcLineRounding.SetRange("Period Code", PayrollCalculation."Period Code");
                            if PayrollCalcLineRounding.FindLast then begin
                                PayrollDocLineCalc."Rounding Precision" := PayrollCalcLineRounding."Rounding Precision";
                                PayrollDocLineCalc."Rounding Type" := PayrollCalcLineRounding."Rounding Type";
                                IncomeTaxAmount := PayrollDocLineCalc.Rounding(IncomeTaxAmount);
                            end;
                        end;
                        ExcelMgt.FillCell('A77', Format(IncomeTaxAmount));
                        ExcelMgt.FillCell('CD77', Format(IncomeTaxAmount));
                        ExcelMgt.FillCell('CR77', Format(TotalAmt - IncomeTaxAmount));
                    end;

                    // çá ß½ÑñÒ¯Ú¿® ¼Ñß´µ
                    ExcelMgt.FillCell('AZ72', Format("Posted Absence Line"."Calendar Days" - CurrMonthDays));
                    ExcelMgt.FillCell('BN72',
                      Format(TotalAmt - FirstAmt));
                    if Date2DMY("Start Date", 2) < Date2DMY("End Date", 2) then
                        ExcelMgt.FillCell('BJ67', LocMgt.GetMonthName("End Date", true));
                    ExcelMgt.FillCell('S79', LocMgt.Amount2Text('', TotalAmt - IncomeTaxAmount));
                    ExcelMgt.FillCell('CX72', Format(TotalAmt));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Employee.Get("Employee No.");
                with Employee do begin
                    ExcelMgt.FillCell('A7', CompanyInfo.Name + ' ' + CompanyInfo."Name 2");
                    ExcelMgt.FillCell('DA7', CompanyInfo."OKPO Code");

                    ExcelMgt.FillCell('BH11', "HR Order No.");
                    ExcelMgt.FillCell('BZ11', Format("HR Order Date"));

                    ExcelMgt.FillCell('A15', GetFullName);
                    ExcelMgt.FillCell('CY15', "No.");

                    ExcelMgt.FillCell('A17', "Org. Unit Name");
                    ExcelMgt.FillCell('A19', "Job Title");

                    if HRManager.Get(CompanyInfo."HR Manager No.") then begin
                        ExcelMgt.FillCell('AF44', HRManager."Job Title");
                        ExcelMgt.FillCell('CI44', HRManager.GetNameInitials);
                    end;
                    if Accountant.Get(CompanyInfo."Accountant No.") then
                        ExcelMgt.FillCell('AI85', Accountant."Job Title" + ' ' + Accountant.GetNameInitials);
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
                    field(PaymentSheetNo; PaymentSheetNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Sheet No.';
                    }
                    field(PaymentSheetDate; PaymentSheetDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Sheet Date';
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

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HRSetup."T-60 Template Code"));
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get;

        HRSetup.Get;
        HRSetup.TestField("T-60 Template Code");
        FileName := ExcelTemplate.OpenTemplate(HRSetup."T-60 Template Code");

        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('Sheet1');
    end;

    var
        Employee: Record Employee;
        HRSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        ExcelTemplate: Record "Excel Template";
        HRManager: Record Employee;
        Accountant: Record Employee;
        EmplAbsenceEntry: Record "Employee Absence Entry";
        EmplAbsenceEntry2: Record "Employee Absence Entry";
        TimeActivity: Record "Time Activity";
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
        ExcelMgt: Codeunit "Excel Management";
        LocMgt: Codeunit "Localisation Management";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        PaymentSheetNo: Code[10];
        PaymentSheetDate: Date;
        FileName: Text[1024];
        RowNo: Integer;
        CurrMonthDays: Decimal;
        CurrMonthDate: Date;
        FirstLine: Boolean;
        TotalAmt: Decimal;
        FirstAmt: Decimal;

    [Scope('OnPrem')]
    procedure FillLastVacations(EmployeeNo: Code[10])
    begin
        with EmplAbsenceEntry do begin
            if FindSet then begin
                if Count > 4 then
                    Next(Count - 4);

                RowNo := 35;
                repeat
                    ExcelMgt.FillCell('A' + Format(RowNo), Format(TimeActivity.Description));
                    ExcelMgt.FillCell('AG' + Format(RowNo), Format("Time Activity Code"));
                    ExcelMgt.FillCell('AW' + Format(RowNo), Format("Calendar Days"));
                    ExcelMgt.FillCell('BQ' + Format(RowNo), Format("Start Date"));
                    ExcelMgt.FillCell('CC' + Format(RowNo), Format("End Date"));
                    ExcelMgt.FillCell('CQ' + Format(RowNo), Description);

                    RowNo += 1;
                until Next = 0;
            end
        end
    end;

    [Scope('OnPrem')]
    procedure CalcGroupTypeIsBetween(DocumentNo: Code[20]): Boolean
    var
        PostedPayrollDoc: Record "Posted Payroll Document";
        PayrollCalcGroup: Record "Payroll Calc Group";
    begin
        PostedPayrollDoc.Get(DocumentNo);
        PayrollCalcGroup.Get(PostedPayrollDoc."Calc Group Code");
        exit(PayrollCalcGroup.Type = PayrollCalcGroup.Type::Between);
    end;
}

