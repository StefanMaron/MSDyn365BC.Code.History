codeunit 5344 "CRM Product Name"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure UNIQUE(): Text
    begin
        exit('MicrosoftDynamicsNavIntegration');
    end;

    procedure SHORT(): Text
    begin
        exit('Dynamics 365 Sales');
    end;

    procedure FULL(): Text
    begin
        exit('Microsoft Dynamics 365 Sales');
    end;

    [Scope('Cloud')]
    procedure CDSServiceName(): Text
    begin
        exit('Dataverse');
    end;
}

