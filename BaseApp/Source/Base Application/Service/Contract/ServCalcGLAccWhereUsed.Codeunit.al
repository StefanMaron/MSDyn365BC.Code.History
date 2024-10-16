namespace Microsoft.Service.Contract;

using Microsoft.Finance.GeneralLedger.Account;
using System.Utilities;

codeunit 5958 "Serv. Calc. G/L Acc.Where-Used"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnShowExtensionPage', '', false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    var
        ServiceContractAccGr: Record "Service Contract Account Group";
    begin
        if GLAccountWhereUsed."Table ID" = Database::"Service Contract Account Group" then begin
            ServiceContractAccGr.Code := CopyStr(GLAccountWhereUsed."Key 1", 1, MaxStrLen(ServiceContractAccGr.Code));
            PAGE.Run(0, ServiceContractAccGr);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnAfterFillTableBuffer', '', false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    begin
        AddTable(TableBuffer, Database::"Service Contract Account Group");
    end;

    local procedure AddTable(var TableBuffer: Record "Integer"; TableID: Integer)
    begin
        if not TableBuffer.Get(TableID) then begin
            TableBuffer.Number := TableID;
            TableBuffer.Insert();
        end;
    end;
}