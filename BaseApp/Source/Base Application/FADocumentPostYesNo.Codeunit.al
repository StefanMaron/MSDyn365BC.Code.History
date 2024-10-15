codeunit 12470 "FA Document-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "FA Document Header";

    trigger OnRun()
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        FADocumentHeader.Copy(Rec);
        Code(FADocumentHeader);
        Rec := FADocumentHeader;
    end;

    var
        Text000: Label 'Do you want to post the %1?';
        Text001: Label 'Document %1 posted successfully.';
        PreviewMode: Boolean;

    local procedure "Code"(FADocumentHeader: Record "FA Document Header")
    var
        FADocPost: Codeunit "FA Document-Post";
    begin
        if not PreviewMode then
            if not Confirm(Text000, false, FADocumentHeader."Document Type") then
                exit;

        FADocPost.SetPreviewMode(PreviewMode);
        FADocPost.Run(FADocumentHeader);

        if not PreviewMode then
            Message(Text001, FADocumentHeader."Document Type");
    end;

    [Scope('OnPrem')]
    procedure Preview(var FADocumentHeader: Record "FA Document Header")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        FADocumentPostYesNo: Codeunit "FA Document-Post (Yes/No)";
    begin
        BindSubscription(FADocumentPostYesNo);
        GenJnlPostPreview.Preview(FADocumentPostYesNo, FADocumentHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        FADocumentPostYesNo: Codeunit "FA Document-Post (Yes/No)";
    begin
        PreviewMode := true;
        FADocumentPostYesNo := Subscriber;
        Result := FADocumentPostYesNo.Run(RecVar);
    end;
}

