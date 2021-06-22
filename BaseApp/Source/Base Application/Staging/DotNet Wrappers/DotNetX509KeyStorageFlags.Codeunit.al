codeunit 3041 DotNet_X509KeyStorageFlags
{

    trigger OnRun()
    begin
    end;

    var
        DotNetX509KeyStorageFlags: DotNet X509KeyStorageFlags;

    [Scope('OnPrem')]
    procedure Exportable()
    begin
        DotNetX509KeyStorageFlags := DotNetX509KeyStorageFlags.Exportable;
    end;

    [Scope('OnPrem')]
    procedure GetX509KeyStorageFlags(var DotNetX509KeyStorageFlags2: DotNet X509KeyStorageFlags)
    begin
        DotNetX509KeyStorageFlags2 := DotNetX509KeyStorageFlags;
    end;

    [Scope('OnPrem')]
    procedure SetX509KeyStorageFlags(var DotNetX509KeyStorageFlags2: DotNet X509KeyStorageFlags)
    begin
        DotNetX509KeyStorageFlags := DotNetX509KeyStorageFlags2;
    end;
}

