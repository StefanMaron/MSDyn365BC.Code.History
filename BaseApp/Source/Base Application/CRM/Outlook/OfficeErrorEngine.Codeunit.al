namespace Microsoft.CRM.Outlook;

codeunit 1632 "Office Error Engine"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ErrorMessage: Text;

    procedure ShowError(Message: Text)
    begin
        ErrorMessage := Message;
        PAGE.Run(PAGE::"Office Error Dlg");
    end;

    procedure GetError(): Text
    begin
        exit(ErrorMessage);
    end;
}

