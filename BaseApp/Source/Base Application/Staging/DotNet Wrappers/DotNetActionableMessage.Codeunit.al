codeunit 3023 DotNet_ActionableMessage
{

    trigger OnRun()
    begin
    end;

    var
        DotNetActionableMessage: DotNet ActionableMessage;

    procedure Create(MessageCardContext: Text; SenderEmail: Text; OpayCardOriginatorForNav: Text; OpayCardPrivateKey: Text): Text
    begin
        exit(DotNetActionableMessage.Create(MessageCardContext, SenderEmail, OpayCardOriginatorForNav, OpayCardPrivateKey))
    end;

    [Scope('OnPrem')]
    procedure GetActionableMessage(var DotNetActionableMessage2: DotNet ActionableMessage)
    begin
        DotNetActionableMessage2 := DotNetActionableMessage
    end;

    [Scope('OnPrem')]
    procedure SetActionableMessage(DotNetActionableMessage2: DotNet ActionableMessage)
    begin
        DotNetActionableMessage := DotNetActionableMessage2
    end;
}

