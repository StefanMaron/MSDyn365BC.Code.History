codeunit 901 "Assembly-Post (Yes/No)"
{
    TableNo = "Assembly Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        AssemblyHeader.Copy(Rec);
        Code();
        Rec := AssemblyHeader;
    end;

    var
        AssemblyHeader: Record "Assembly Header";
        Text000: Label 'Do you want to post the %1?';

    local procedure "Code"()
    begin
        with AssemblyHeader do begin
            if not Confirm(Text000, false, "Document Type") then
                exit;

            CODEUNIT.Run(CODEUNIT::"Assembly-Post", AssemblyHeader);
        end;
    end;

    procedure Preview(var AssemblyHeaderToPreview: Record "Assembly Header")
    var
        AssemblyPostYesNo: Codeunit "Assembly-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(AssemblyPostYesNo);
        GenJnlPostPreview.Preview(AssemblyPostYesNo, AssemblyHeaderToPreview);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        AssemblyHeaderToPreview: Record "Assembly Header";
        AssemblyPost: Codeunit "Assembly-Post";
    begin
        AssemblyHeaderToPreview.Copy(RecVar);
        AssemblyPost.SetSuppressCommit(true);
        AssemblyPost.SetPreviewMode(true);
        Result := AssemblyPost.Run(AssemblyHeaderToPreview);
    end;
}

