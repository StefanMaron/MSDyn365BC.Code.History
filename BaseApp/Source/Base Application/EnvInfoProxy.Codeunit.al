#if not CLEAN22
namespace System.Environment;
codeunit 9995 "Env. Info Proxy"
{
    ObsoleteReason = 'Microsoft Invoicing is not supported on Business Central';
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '15.0';
#pragma warning restore AS0072

    [Obsolete('Microsoft Invoicing is not supported on Business Central', '15.0')]
    procedure IsInvoicing(): Boolean;
    begin
        exit(false);
    end;
}
#endif