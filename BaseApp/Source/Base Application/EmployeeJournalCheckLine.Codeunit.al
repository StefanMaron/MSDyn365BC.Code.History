codeunit 17381 "Employee Journal - Check Line"
{
    TableNo = "Employee Journal Line";

    trigger OnRun()
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if EmptyLine then
            exit;

        TestField("Employee No.");
        TestField("Posting Date");
        if "Post Action" = "Post Action"::Add then
            TestField("Starting Date");
        if "Post Action" = "Post Action"::Close then
            TestField("Ending Date");
        TestField("Contract No.");
        TestField("Posting Group");
        TestField("Calendar Code");
        TestField("Payroll Calc Group");

        if ("Element Code" = '') and ("Time Activity Code" = '') then
            Error(Text002, FieldCaption("Element Code"), FieldCaption("Time Activity Code"));

        if "Post Action" <> "Post Action"::Add then
            TestField("Applies-to Entry");

        if "Post Action" = "Post Action"::Add then begin
            PayrollElement.Get("Element Code");
            if PayrollElement."Amount Mandatory" then
                TestField(Amount);
            if PayrollElement."Quantity Mandatory" then
                TestField(Quantity);
            if PayrollElement."Bonus Type" <> 0 then begin
                TestField("Wage Period From");
                TestField("Wage Period To");
            end;
            if PayrollElement.IsAECalc then begin
                TestField("Document Type");
                TestField("AE Period From");
                TestField("AE Period To");
            end;
        end;

        PayrollPeriod.Get("Period Code");

        if ("Time Activity Code" <> '') and (not Terminated) then begin
            TimesheetStatus.Get("Period Code", "Employee No.");
            TimesheetStatus.TestField(Status, TimesheetStatus.Status::Open);
        end;

        if "Posting Date" <> NormalDate("Posting Date") then
            FieldError("Posting Date", Text000);

        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            if UserId <> '' then
                if UserSetup.Get(UserId) then begin
                    AllowPostingFrom := UserSetup."Allow Posting From";
                    AllowPostingTo := UserSetup."Allow Posting To";
                end;
            if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                GLSetup.Get();
                AllowPostingFrom := GLSetup."Allow Posting From";
                AllowPostingTo := GLSetup."Allow Posting To";
            end;
            if AllowPostingTo = 0D then
                AllowPostingTo := 99991231D;
        end;
        if ("Posting Date" < AllowPostingFrom) or ("Posting Date" > AllowPostingTo) then
            FieldError("Posting Date", Text001);

        if "Document Date" <> 0D then
            if "Document Date" <> NormalDate("Document Date") then
                FieldError("Document Date", Text000);

        if not DimMgt.CheckDimIDComb("Dimension Set ID") then
            Error(
              Text003,
              TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
              DimMgt.GetDimCombErr);

        TableID[1] := DATABASE::Employee;
        No[1] := "Employee No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
            if "Line No." <> 0 then
                Error(
                  Text004,
                  TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                  DimMgt.GetDimValuePostingErr)
            else
                Error(DimMgt.GetDimValuePostingErr);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        PayrollPeriod: Record "Payroll Period";
        TimesheetStatus: Record "Timesheet Status";
        PayrollElement: Record "Payroll Element";
        DimMgt: Codeunit DimensionManagement;
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        Text000: Label 'cannot be a closing date';
        Text001: Label 'is not within your range of allowed posting dates';
        Text002: Label '%1 or %2 should be entered';
        Text003: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text004: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
}

