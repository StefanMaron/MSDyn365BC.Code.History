codeunit 15000230 TestEmpolyeesUnlimited
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure TestNoOfEmployees(): Boolean
    begin
        exit(true);
    end;
}

