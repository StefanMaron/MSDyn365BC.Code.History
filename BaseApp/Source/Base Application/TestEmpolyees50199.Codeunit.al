codeunit 15000220 "TestEmpolyees50-199"
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

