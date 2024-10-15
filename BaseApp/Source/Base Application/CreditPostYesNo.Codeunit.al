#if not CLEAN18
codeunit 31051 "Credit - Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Credit Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
        CreditHeader.Copy(Rec);
        Code;
        Rec := CreditHeader;
    end;

    var
        PostQst: Label 'Do you want to post credit?';
        CreditHeader: Record "Credit Header";

    [Scope('OnPrem')]
    procedure "Code"()
    begin
        if not Confirm(PostQst, false) then
            Error('');

        CODEUNIT.Run(CODEUNIT::"Credit - Post", CreditHeader);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure Preview(CreditHeader: Record "Credit Header")
    var
        CreditPostYesNo: Codeunit "Credit - Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(CreditPostYesNo);
        GenJnlPostPreview.Preview(CreditPostYesNo, CreditHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        CreditHeader: Record "Credit Header";
        CreditPost: Codeunit "Credit - Post";
    begin
        CreditHeader.Copy(RecVar);
        CreditPost.SetPreviewMode(true);
        Result := CreditPost.Run(CreditHeader);
    end;
}
#endif