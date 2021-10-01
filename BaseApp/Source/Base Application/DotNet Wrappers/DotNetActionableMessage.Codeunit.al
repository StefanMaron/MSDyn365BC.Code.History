#if not CLEAN19
codeunit 3023 DotNet_ActionableMessage
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit is obsolete.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    procedure Create(MessageCardContext: Text; SenderEmail: Text; OpayCardOriginatorForNav: Text; OpayCardPrivateKey: Text): Text
    begin 
        exit('');       
    end;
}
#endif