codeunit 131105 "Library - SMTP Mail Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        RunOnAfterTrySendSubscriber: Boolean;
        SenderAddressGlobal: Text;
        SenderNameGlobal: Text;
        DisableSending: Boolean;

    [Scope('OnPrem')]
    procedure AddOnAfterTrySendIgnoringError(IgnoringErrorText: Text)
    begin
        TempNameValueBuffer.Name := CopyStr(IgnoringErrorText, 1, MaxStrLen(TempNameValueBuffer.Name));
        TempNameValueBuffer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ActivateOnAfterTrySendSubscriber()
    begin
        RunOnAfterTrySendSubscriber := true;
    end;

    [Scope('OnPrem')]
    procedure SetSenderAddress(SenderAddress: Text)
    begin
        SenderAddressGlobal := SenderAddress;
    end;

    [Scope('OnPrem')]
    procedure SetSenderName(SenderName: Text)
    begin
        SenderNameGlobal := SenderName;
    end;

    [Scope('OnPrem')]
    procedure SetDisableSending(NewDisableSending: Boolean)
    begin
        DisableSending := NewDisableSending;
    end;

    [Scope('OnPrem')]
    procedure DeactivateOnAfterTrySendSubscriber()
    begin
        RunOnAfterTrySendSubscriber := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, 400, 'OnAfterSend', '', false, false)]
    local procedure TrackResultOnAfterTrySend(var SendResult: Text)
    begin
        if not RunOnAfterTrySendSubscriber then
            exit;

        TempNameValueBuffer.SetRange(Name, LibraryUtility.ConvertCRLFToBackSlash(SendResult));
        if not TempNameValueBuffer.IsEmpty then
            SendResult := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, 9520, 'OnBeforeDoSending', '', false, false)]
    local procedure CancelSendingOnBeforeDoSending(var CancelSending: Boolean)
    begin
        CancelSending := DisableSending;
    end;

    [EventSubscriber(ObjectType::Codeunit, 400, 'OnBeforeCreateMessage', '', false, false)]
    local procedure SetSenderInfoOnBeforeCreateMessage(var FromName: Text; var FromAddress: Text; var Recipients: List of [Text]; var Subject: Text; var Body: Text)
    begin
        FromName := SenderNameGlobal;
        FromAddress := SenderAddressGlobal;
    end;
}

