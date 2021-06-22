codeunit 5344 "CRM Product Name"
{

    trigger OnRun()
    begin
    end;

    procedure SHORT(): Text
    begin
        exit('Dynamics 365 Sales');
    end;

    procedure FULL(): Text
    begin
        exit('Microsoft Dynamics 365 Sales');
    end;
}

