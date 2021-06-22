codeunit 9995 "Env. Info Proxy"
{
    [Obsolete('Microsoft Invoicing is not supported on Business Central','15.0')]
    procedure IsInvoicing(): Boolean;
    begin
        exit(false);
    end;
}