codeunit 3044 DotNet_SecureString
{

    trigger OnRun()
    begin
    end;

    var
        DotNetSecureString: DotNet SecureString;

    procedure SecureString()
    begin
        DotNetSecureString := DotNetSecureString.SecureString;
    end;

    procedure AppendChar(C: Char)
    begin
        DotNetSecureString.AppendChar(C);
    end;

    [Scope('OnPrem')]
    procedure GetSecureString(var DotNetSecureString2: DotNet SecureString)
    begin
        DotNetSecureString2 := DotNetSecureString;
    end;

    [Scope('OnPrem')]
    procedure SetSecureString(var DotNetSecureString2: DotNet SecureString)
    begin
        DotNetSecureString := DotNetSecureString2;
    end;
}

