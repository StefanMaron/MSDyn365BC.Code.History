codeunit 17407 "Release Payroll Document"
{
    TableNo = "Payroll Document";

    trigger OnRun()
    var
        PayrollDocLine: Record "Payroll Document Line";
        PayrollCalcGroup: Record "Payroll Calc Group";
    begin
        if Status = Status::Released then
            exit;

        if "Posting Type" = "Posting Type"::Calculation then
            if not PayrollStatus.Get("Period Code", "Employee No.") then begin
                PayrollStatus.Init();
                PayrollStatus."Period Code" := PayrollDocLine."Period Code";
                PayrollStatus."Employee No." := PayrollDocLine."Employee No.";
                PayrollStatus.Insert();
            end else
                if Correction then begin
                    if not (("Calc Group Code" <> '') and
                            PayrollCalcGroup.Get("Calc Group Code") and
                            (PayrollCalcGroup.Type = PayrollCalcGroup.Type::Between))
                    then
                        PayrollStatus.TestField("Payroll Status", PayrollStatus."Payroll Status"::Posted);
                end else
                    if PayrollStatus."Payroll Status" = PayrollStatus."Payroll Status"::Posted then
                        PayrollStatus.FieldError("Payroll Status");

        PayrollDocLine.SetRange("Document No.", "No.");
        if PayrollDocLine.IsEmpty then
            Error(Text001, "No.");

        Status := Status::Released;

        Modify(true);
    end;

    var
        Text001: Label 'There is nothing to release for payroll document %1.';
        PayrollStatus: Record "Payroll Status";

    [Scope('OnPrem')]
    procedure Reopen(var PayrollDoc: Record "Payroll Document")
    begin
        with PayrollDoc do begin
            if Status = Status::Open then
                exit;

            Status := Status::Open;
            Modify(true);
        end;
    end;
}

