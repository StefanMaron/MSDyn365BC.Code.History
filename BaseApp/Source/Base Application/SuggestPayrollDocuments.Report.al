report 17401 "Suggest Payroll Documents"
{
    Caption = 'Suggest Payroll Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", Status, "Org. Unit Code";
            dataitem("Payroll Calc Group Line"; "Payroll Calc Group Line")
            {
                DataItemTableView = SORTING("Payroll Calc Group", "Line No.");
                dataitem("Payroll Calc Type"; "Payroll Calc Type")
                {
                    DataItemLink = Code = FIELD("Payroll Calc Type");
                    DataItemTableView = SORTING(Code);
                    dataitem("Payroll Calc Type Line"; "Payroll Calc Type Line")
                    {
                        DataItemLink = "Calc Type Code" = FIELD(Code);
                        DataItemTableView = SORTING("Calc Type Code", "Line No.") WHERE(Activity = CONST(true));

                        trigger OnAfterGetRecord()
                        begin
                            PayrollElement.Get("Element Code");
                            case PayrollElement."Include into Calculation by" of
                                PayrollElement."Include into Calculation by"::"Action Period":
                                    begin
                                        EmplLedgEntry.Reset();
                                        EmplLedgEntry.SetRange("Employee No.", Employee."No.");
                                        EmplLedgEntry.SetRange("Element Code", PayrollElement.Code);
                                        EmplLedgEntry.SetRange("Action Starting Date",
                                          Employee."Employment Date", PayrollCalcPeriod."Ending Date");
                                        EmplLedgEntry.SetFilter("Action Ending Date", '%1|%2..', 0D, PayrollCalcPeriod."Starting Date");
                                        if EmplLedgEntry.FindSet then
                                            repeat
                                                InsertTempLine(
                                                  "Payroll Calc Type", "Payroll Calc Type Line",
                                                  PayrollCalcPeriod, Employee, PayrollElement, CalculationDate);
                                                UpdateTempLine(EmplLedgEntry);
                                            until EmplLedgEntry.Next() = 0
                                        else
                                            if "Payroll Calc Type"."Use in Calc" = "Payroll Calc Type"."Use in Calc"::Always then
                                                InsertTempLine(
                                                  "Payroll Calc Type", "Payroll Calc Type Line",
                                                  PayrollCalcPeriod, Employee, PayrollElement, CalculationDate);
                                    end;
                                PayrollElement."Include into Calculation by"::"Period Code":
                                    begin
                                        EmplLedgEntry.Reset();
                                        EmplLedgEntry.SetRange("Employee No.", Employee."No.");
                                        EmplLedgEntry.SetRange("Element Code", PayrollElement.Code);
                                        EmplLedgEntry.SetRange("Period Code", PayrollCalcPeriod.Code);
                                        if EmplLedgEntry.FindSet then
                                            repeat
                                                InsertTempLine(
                                                  "Payroll Calc Type", "Payroll Calc Type Line",
                                                  PayrollCalcPeriod, Employee, PayrollElement, CalculationDate);
                                                UpdateTempLine(EmplLedgEntry);
                                            until EmplLedgEntry.Next() = 0
                                        else
                                            if "Payroll Calc Type"."Use in Calc" = "Payroll Calc Type"."Use in Calc"::Always then
                                                InsertTempLine(
                                                  "Payroll Calc Type", "Payroll Calc Type Line",
                                                  PayrollCalcPeriod, Employee, PayrollElement, CalculationDate);
                                    end;
                            end;
                        end;

                        trigger OnPostDataItem()
                        begin
                            with PayrollStatus do begin
                                Get(PayrollCalcPeriod.Code, Employee."No.");
                                if (CalcGroupCode = '') and ("Payroll Status" = "Payroll Status"::" ") then
                                    "Payroll Status" := "Payroll Status"::Calculated;
                                UpdateCalculated(PayrollStatus);
                                Modify;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("Element Code", '<>%1', '');
                        end;
                    }
                }

                trigger OnPostDataItem()
                begin
                    with TempPayrollDocLine do begin
                        Reset;
                        if FindSet then
                            repeat
                                PayrollDocLine.Init();
                                PayrollDocLine := TempPayrollDocLine;
                                PayrollDocLine.CreateDim(DATABASE::"Payroll Element", "Element Code");
                                CombineDimensions("Dimension Set ID");
                                PayrollDocLine.Insert();
                            until Next() = 0;
                        DeleteAll();
                    end;

                    with PayrollDocLine do begin
                        Reset;
                        SetRange("Document No.", PayrollDocument."No.");
                        SetRange(Calculate, true);
                        if FindSet then
                            repeat
                                PayrollCalculation.Run(PayrollDocLine);
                            until Next() = 0;
                    end;

                    if CalcGroupCode = '' then begin
                        PayrollStatus.Get(PayrollCalcPeriod.Code, Employee."No.");
                        if PayrollStatus."Payroll Status" = PayrollStatus."Payroll Status"::" " then begin
                            PayrollStatus."Payroll Status" := PayrollStatus."Payroll Status"::Calculated;
                            PayrollStatus.Modify();
                        end;
                    end;

                    Commit();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Payroll Calc Group", PayrollCalcGr.Code);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CounterTotal := CounterTotal + 1;

                // check current period
                if not PayrollStatus.Get(PayrollCalcPeriod.Code, "No.") then begin
                    PayrollStatus.Init();
                    PayrollStatus."Period Code" := PayrollCalcPeriod.Code;
                    PayrollStatus."Employee No." := "No.";
                    PayrollStatus.Insert();
                end else
                    if CreateNewDocs and (CalcGroupCode = '') then
                        if PayrollStatus."Payroll Status" >= PayrollStatus."Payroll Status"::Calculated then begin
                            if ShowMessages then
                                Message(Text013, PayrollStatus."Payroll Status", "No.", PayrollStatus."Period Code");
                            CurrReport.Skip();
                        end;

                if CalcGroupCode = '' then
                    PayrollCalcGr.Get("Payroll Calc Group")
                else
                    PayrollCalcGr.Get(CalcGroupCode);

                if PayrollCalcGr.Type <> PayrollCalcGr.Type::Between then begin
                    if TimesheetStatus.Get(PayrollCalcPeriod.Code, "No.") then
                        if TimesheetStatus.Status <> TimesheetStatus.Status::Released then begin
                            if ShowMessages then
                                Message(Text014, TimesheetStatus.Status, "No.");
                            CurrReport.Skip();
                        end;

                    // check previous period
                    PayrollStatus.SetRange("Employee No.", "No.");
                    if PayrollStatus.Next(-1) <> 0 then
                        if PayrollStatus."Payroll Status" < PayrollStatus."Payroll Status"::Posted then begin
                            if ShowMessages then
                                Message(Text013, PayrollStatus."Payroll Status", "No.", PayrollStatus."Period Code");
                            CurrReport.Skip();
                        end;
                end;

                if Employee.Blocked then
                    CurrReport.Skip();

                HeaderExist := CreateHeader;
                if HeaderExist then
                    CounterOK := CounterOK + 1
                else begin
                    if ShowMessages then
                        Message(Text011,
                          PayrollDocument.TableCaption,
                          FieldCaption("No."), "No.",
                          PayrollCalcPeriod.FieldCaption(Code), PayrollCalcPeriod.Code);
                    CurrReport.Skip();
                end;

                Window.Update(1, "No.");
                Window.Update(2, CopyStr("Short Name", 1, 30));
                Window.Update(3, Round(CounterTotal / TotalEmployees * 10000, 1));

                EmployeeNumber := EmployeeNumber + 1;

                NextLineNo := 0;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;

                if ShowMessages then
                    Message(Text010, CounterOK, CounterTotal);
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Employment Date", '<=%1', PayrollCalcPeriod."Ending Date");

                NextTempLineNo := 0;
                TotalEmployees := Count;
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
                    field(CalcPeriodCode; CalcPeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Period';
                        TableRelation = "Payroll Period";

                        trigger OnValidate()
                        begin
                            PayrollCalcPeriod.Get(CalcPeriodCode);
                            PayrollCalcPeriod.TestField("Starting Date");
                            PayrollCalcPeriod.TestField("Ending Date");
                            CalculationDate := PayrollCalcPeriod."Ending Date";
                        end;
                    }
                    field(CalculationDate; CalculationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Date';
                    }
                    field(CalcGroupCode; CalcGroupCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Group Code';
                        TableRelation = "Payroll Calc Group";

                        trigger OnValidate()
                        begin
                            CalcGroupCodeOnAfterValidate;
                        end;
                    }
                    field(CreateNewDocs; CreateNewDocs)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create New Documents';

                        trigger OnValidate()
                        begin
                            if not CreateNewDocs then
                                if CalcGroupCode <> '' then
                                    Error(Text012);
                        end;
                    }
                    field(ShowMessages; ShowMessages)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Messages';

                        trigger OnValidate()
                        begin
                            if not CreateNewDocs and (CalcGroupCode <> '') then
                                Error(Text012);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if CalculationDate = 0D then
                CalculationDate := PayrollCalcPeriod."Ending Date";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        EmployeeNumber := 0;

        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Payroll Document Nos.");

        ACYRate := 1;

        if CalculationDate = 0D then
            Error(Text008);

        PayrollCalcPeriod.TestField("Starting Date");
        PayrollCalcPeriod.TestField("Ending Date");

        if Date2DMY(CalculationDate, 2) <> Date2DMY(PayrollCalcPeriod."Ending Date", 2) then begin
            if not Confirm(Text006, false) then
                Error(Text007);
        end;

        Window.Open(Text001 + Text002 + Text003);
    end;

    var
        PayrollDocument: Record "Payroll Document";
        PayrollDocLine: Record "Payroll Document Line";
        TempPayrollDocLine: Record "Payroll Document Line" temporary;
        PstdPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollElement: Record "Payroll Element";
        PayrollPeriod: Record "Payroll Period";
        PayrollCalcPeriod: Record "Payroll Period";
        PayrollWagePeriod: Record "Payroll Period";
        PayrollPostingGr: Record "Payroll Posting Group";
        PayrollCalcGr: Record "Payroll Calc Group";
        EmplLedgEntry: Record "Employee Ledger Entry";
        HumanResourcesSetup: Record "Human Resources Setup";
        TimesheetStatus: Record "Timesheet Status";
        PayrollStatus: Record "Payroll Status";
        PayrollCalculation: Codeunit "Payroll Document - Calculate";
        Window: Dialog;
        CalculationDate: Date;
        CreateNewDocs: Boolean;
        EmployeeNumber: Integer;
        ACYRate: Decimal;
        Text001: Label 'Employee No.        #1##################\';
        Text002: Label 'Short Name          #2############################\';
        Text003: Label '                    @3@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        Text004: Label '%1, payroll charge for %2';
        Text006: Label 'G/L posting date differs from calculation period. Continue?';
        Text007: Label 'Calculation Date should be within Calculation Period.';
        Text008: Label 'You should enter Calculation Date.';
        NextTempLineNo: Integer;
        NextLineNo: Integer;
        Text010: Label '%1 employees out of a total of %2 have now been calculated.';
        CounterOK: Integer;
        CounterTotal: Integer;
        TotalEmployees: Integer;
        ShowMessages: Boolean;
        HeaderExist: Boolean;
        CalcPeriodCode: Code[10];
        CalcGroupCode: Code[20];
        Text011: Label '%1 for %2 %3 %4 %5 does not exist.';
        Text012: Label 'Create New Documents must be set if Calculation Group Code is not empty.';
        Text013: Label 'Payroll Status is %1 for employee %2 in payroll period %3.';
        Text014: Label 'Timesheet Status is %1 for employee %2.';

    [Scope('OnPrem')]
    procedure Set(NewCalcPeriodCode: Code[10]; NewCalcGroupCode: Code[10]; NewCalcDate: Date; NewHideDialog: Boolean)
    begin
        if NewCalcPeriodCode = '' then
            NewCalcPeriodCode := PayrollCalcPeriod.PeriodByDate(WorkDate);

        PayrollCalcPeriod.Get(NewCalcPeriodCode);
        PayrollCalcPeriod.TestField("Starting Date");
        PayrollCalcPeriod.TestField("Ending Date");
        CalcPeriodCode := PayrollCalcPeriod.Code;
        if NewCalcDate <> 0D then
            CalculationDate := NewCalcDate
        else
            CalculationDate := PayrollCalcPeriod."Ending Date";
        CalcGroupCode := NewCalcGroupCode;
        ShowMessages := not NewHideDialog;
    end;

    local procedure InsertTempLine(PayrollCalcType: Record "Payroll Calc Type"; PayrollCalcTypeLine: Record "Payroll Calc Type Line"; PayrollPeriod: Record "Payroll Period"; Employee: Record Employee; PayrollElement: Record "Payroll Element"; PostingDate: Date)
    begin
        with TempPayrollDocLine do begin
            Init;
            "Document No." := PayrollDocument."No.";
            NextLineNo := NextLineNo + 10000;
            "Line No." := NextLineNo;
            "Period Code" := PayrollPeriod.Code;

            CopyEmployeeToPayrollDocLine(Employee, TempPayrollDocLine);
            CopyElementToPayrollDocLine(PayrollElement, TempPayrollDocLine);
            CopyCalcTypeToPayrollDocLine(PayrollCalcType, TempPayrollDocLine);

            "Wage Period From" := "Period Code";
            "Wage Period To" := "Period Code";

            if PayrollCalcTypeLine."Payroll Posting Group" <> '' then
                "Posting Group" := PayrollCalcTypeLine."Payroll Posting Group";
            if "Posting Group" = '' then
                "Posting Group" := Employee."Posting Group";
            if (PayrollElement.Description = '') or (PayrollElement.Type = PayrollElement.Type::"Netto Salary") then
                Description := Employee.GetFullNameOnDate(CalculationDate);

            Insert;
        end;
    end;

    local procedure UpdateTempLine(EmplLedgEntry: Record "Employee Ledger Entry")
    var
        DeleteDocLine: Boolean;
    begin
        TempPayrollDocLine.FindLast;
        with TempPayrollDocLine do begin
            EmplLedgEntry.TestField("Entry No.");
            "Employee Ledger Entry No." := EmplLedgEntry."Entry No.";
            "Document Type" := EmplLedgEntry."Document Type";
            "HR Order No." := EmplLedgEntry."HR Order No.";
            "HR Order Date" := EmplLedgEntry."HR Order Date";
            "Time Activity Code" := EmplLedgEntry."Time Activity Code";
            if EmplLedgEntry."Wage Period From" <> '' then
                "Wage Period From" := EmplLedgEntry."Wage Period From";
            if EmplLedgEntry."Wage Period To" <> '' then
                "Wage Period To" := EmplLedgEntry."Wage Period To";
            PayrollWagePeriod.Get("Wage Period From");
            if EmplLedgEntry."Action Starting Date" < PayrollWagePeriod."Starting Date" then
                "Action Starting Date" := PayrollWagePeriod."Starting Date"
            else
                "Action Starting Date" := EmplLedgEntry."Action Starting Date";
            PayrollWagePeriod.Get("Wage Period To");
            if EmplLedgEntry."Action Ending Date" = 0D then
                "Action Ending Date" := PayrollWagePeriod."Ending Date"
            else
                if EmplLedgEntry."Action Ending Date" > PayrollWagePeriod."Ending Date" then
                    "Action Ending Date" := PayrollWagePeriod."Ending Date"
                else
                    "Action Ending Date" := EmplLedgEntry."Action Ending Date";
            Amount := EmplLedgEntry.Amount;
            Quantity := EmplLedgEntry.Quantity;
            "Payment Percent" := EmplLedgEntry."Payment Percent";
            "Payment Days" := EmplLedgEntry."Payment Days";
            "Payment Hours" := EmplLedgEntry."Payment Hours";
            "Payment Source" := EmplLedgEntry."Payment Source";
            "Days Not Paid" := EmplLedgEntry."Days Not Paid";
            "Salary Indexation" := EmplLedgEntry."Salary Indexation";
            "Depends on Salary Element" := EmplLedgEntry."Depends on Salary Element";
            "AE Period From" := EmplLedgEntry."AE Period From";
            "AE Period To" := EmplLedgEntry."AE Period To";
            if (EmplLedgEntry."Sick Leave Type" <> 0) and
               (EmplLedgEntry."Payment Source" = EmplLedgEntry."Payment Source"::Employeer)
            then begin
                Employee.TestField("Int. Fnds Sick Leave Post. Gr.");
                "Posting Group" := Employee."Int. Fnds Sick Leave Post. Gr.";
            end;
            if EmplLedgEntry."Document Type" = EmplLedgEntry."Document Type"::Vacation then begin
                PayrollPeriod.Get(EmplLedgEntry."Period Code");
                if EmplLedgEntry."Action Starting Date" > PayrollPeriod."Ending Date" then begin
                    Employee.TestField("Future Period Vacat. Post. Gr.");
                    "Posting Group" := Employee."Future Period Vacat. Post. Gr.";
                end;
            end;
            "Dimension Set ID" := EmplLedgEntry."Dimension Set ID";
            if (PayrollCalcGr.Type = PayrollCalcGr.Type::Between) and
               ("Employee Ledger Entry No." <> 0)
            then begin
                PstdPayrollDocLine.Reset();
                PstdPayrollDocLine.SetCurrentKey("Employee No.", "Period Code");
                PstdPayrollDocLine.SetRange("Employee No.", "Employee No.");
                PstdPayrollDocLine.SetRange("Period Code", "Period Code");
                PstdPayrollDocLine.SetRange("Employee Ledger Entry No.", "Employee Ledger Entry No.");
                if PstdPayrollDocLine.FindSet then
                    repeat
                        if DocWithoutCorrection(PstdPayrollDocLine."Document No.") then
                            DeleteDocLine := true;
                    until PstdPayrollDocLine.Next() = 0;
                if DeleteDocLine then
                    Delete
                else
                    Modify;
            end else
                Modify;
        end;
    end;

    local procedure CreateHeader(): Boolean
    begin
        if not CreateNewDocs then begin
            PayrollDocument.Reset();
            PayrollDocument.SetCurrentKey("Employee No.");
            PayrollDocument.SetRange("Employee No.", Employee."No.");
            PayrollDocument.SetRange("Period Code", PayrollCalcPeriod.Code);
            if PayrollDocument.FindFirst then begin
                PayrollDocLine.Reset();
                PayrollDocLine.SetRange("Document No.", PayrollDocument."No.");
                PayrollDocLine.DeleteAll(true);
                exit(true);
            end;
        end;

        PayrollDocument.Init();
        PayrollDocument."No." := '';
        PayrollDocument.Insert(true);
        PayrollDocument.Validate("Employee No.", Employee."No.");
        PayrollDocument."Posting Date" := CalculationDate;
        PayrollDocument."Period Code" := PayrollCalcPeriod.Code;
        PayrollDocument."Calc Group Code" := PayrollCalcGr.Code;
        PayrollDocument."Posting Description" :=
          CopyStr(
            StrSubstNo(
              Text004,
              Employee."Short Name",
              Format(PayrollCalcPeriod."Ending Date", 0, '<Month Text> <Year4>')),
            1,
            MaxStrLen(PayrollDocument."Posting Description"));
        PayrollDocument.Modify();

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CopyEmployeeToPayrollDocLine(Employee: Record Employee; var PayrollDocLine: Record "Payroll Document Line")
    begin
        with PayrollDocLine do begin
            "Employee No." := Employee."No.";
            "Calc Group" := Employee."Payroll Calc Group";
            "Calendar Code" := Employee."Calendar Code";
            "Org. Unit Code" := Employee."Org. Unit Code";
            "Employee Posting Group" := Employee."Posting Group";
            "Org. Unit Code" := Employee."Org. Unit Code";
            "Shortcut Dimension 1 Code" := Employee."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := Employee."Global Dimension 2 Code";
            if PayrollPostingGr.Get(Employee."Posting Group") then
                if "Employee Account No." = '' then
                    "Employee Account No." := PayrollPostingGr."Account No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyCalcTypeToPayrollDocLine(PayrollCalcType: Record "Payroll Calc Type"; var PayrollDocLine: Record "Payroll Document Line")
    begin
        with PayrollDocLine do begin
            "Calc Type Code" := PayrollCalcType.Code;
            Priority := PayrollCalcType.Priority;
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyElementToPayrollDocLine(PayrollElement: Record "Payroll Element"; var PayrollDocLine: Record "Payroll Document Line")
    var
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
    begin
        with PayrollDocLine do begin
            "Element Code" := PayrollElement.Code;
            "Element Type" := PayrollElement.Type;
            "Posting Type" := PayrollElement."Posting Type";
            Calculate := PayrollElement.Calculate;
            "Print in Pay-Sheet" := PayrollElement."Print in Pay-Sheet";
            if PayrollElement."Payroll Posting Group" <> '' then
                "Posting Group" := PayrollElement."Payroll Posting Group";
            Description := PayrollElement.Description;
            "Element Group" := PayrollElement."Element Group";
            "Directory Code" := PayrollElement."Directory Code";
            "FSI Base" := PayrollElement."FSI Base";
            "Federal FMI Base" := PayrollElement."Federal FMI Base";
            "Territorial FMI Base" := PayrollElement."Territorial FMI Base";
            "Pension Fund Base" := PayrollElement."PF Base";
            "Income Tax Base" := PayrollElement."Income Tax Base";
            "FSI Injury Base" := PayrollElement."FSI Injury Base";
            "Print Priority" := PayrollElement."Print Priority";
            "Pay Type" := PayrollElement."Pay Type";
            "Source Pay" := PayrollElement."Source Pay";
            "Bonus Type" := PayrollElement."Bonus Type";

            // ÅàÉàìÄæ ÉÇæòÄäìÄâÄ æùàÆÇ
            PayrollCalcTypeLine.Reset();
            PayrollCalcTypeLine.SetRange("Element Code", PayrollElement.Code);
            if PayrollCalcTypeLine.FindFirst then
                if PayrollCalcTypeLine."Payroll Posting Group" <> '' then begin
                    PayrollPostingGr.Reset();
                    PayrollPostingGr.SetRange(Code, PayrollCalcTypeLine."Payroll Posting Group");
                    if PayrollPostingGr.FindFirst then begin
                        if PayrollPostingGr."Account No." <> '' then
                            "Employee Account No." := PayrollPostingGr."Account No.";
                    end;
                end;
        end;
    end;

    local procedure CalcGroupCodeOnAfterValidate()
    begin
        CreateNewDocs := (CalcGroupCode <> '');
    end;

    local procedure CombineDimensions(DimSetID: Integer): Integer
    var
        DimMgt: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        with PayrollDocLine do begin
            DimensionSetIDArr[1] := "Dimension Set ID";
            DimensionSetIDArr[2] := DimSetID;
            "Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    local procedure DocWithoutCorrection(DocNo: Code[20]): Boolean
    var
        PstdPayrollDocument: Record "Posted Payroll Document";
    begin
        PstdPayrollDocument.Get(DocNo);
        if not PstdPayrollDocument.Reversed then
            exit(true);
        exit(false);
    end;
}

