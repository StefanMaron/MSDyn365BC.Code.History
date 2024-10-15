codeunit 11733 "Cash Document-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Cash Document Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        CashDocumentHeader.Copy(Rec);
        Code;
        Rec := CashDocumentHeader;
    end;

    var
        CashDocumentHeader: Record "Cash Document Header";
        PostingConfirmQst: Label 'Do you want to post %1 %2?', Comment = '%1 = table caption of cash document header; %2 = number of cash document';

    local procedure "Code"()
    begin
        if not Confirm(PostingConfirmQst, false, CashDocumentHeader.TableCaption, CashDocumentHeader."No.") then
            Error('');

        CODEUNIT.Run(CODEUNIT::"Cash Document-Post", CashDocumentHeader);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure Preview(CashDocumentHeader: Record "Cash Document Header")
    var
        CashDocumentPostYesNo: Codeunit "Cash Document-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(CashDocumentPostYesNo);
        GenJnlPostPreview.Preview(CashDocumentPostYesNo, CashDocumentHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentPost: Codeunit "Cash Document-Post";
    begin
        CashDocumentHeader.Copy(RecVar);
        CashDocumentPost.SetPreviewMode(true);
        Result := CashDocumentPost.Run(CashDocumentHeader);
    end;
}

