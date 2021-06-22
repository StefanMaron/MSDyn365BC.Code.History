codeunit 911 "Pstd. Assembly - Undo (Yes/No)"
{
    TableNo = "Posted Assembly Header";

    trigger OnRun()
    begin
        PostedAsmHeader.Copy(Rec);
        Code;
        Rec := PostedAsmHeader;
    end;

    var
        PostedAsmHeader: Record "Posted Assembly Header";
        Text000: Label 'Do you want to undo posting of the posted assembly order?';
        Text001: Label 'Do you want to recreate the assembly order from the posted assembly order?';

    local procedure "Code"()
    var
        AsmHeader: Record "Assembly Header";
        AsmPost: Codeunit "Assembly-Post";
        DoRecreateAsmOrder: Boolean;
    begin
        if not Confirm(Text000, false) then
            exit;

        if not AsmHeader.Get(AsmHeader."Document Type"::Order, PostedAsmHeader."Order No.") then
            DoRecreateAsmOrder := Confirm(Text001);

        AsmPost.Undo(PostedAsmHeader, DoRecreateAsmOrder);
        Commit();
    end;
}

