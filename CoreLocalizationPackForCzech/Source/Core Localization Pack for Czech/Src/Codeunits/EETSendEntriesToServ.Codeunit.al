codeunit 31119 "EET Send Entries To Serv. CZL"
{
    Permissions = TableData "EET Entry CZL" = r;

    trigger OnRun()
    begin
        EETEntryCZL.SetCurrentKey(EETEntryCZL."Status");
        EETEntryCZL.SetFilterToSending();
        if EETEntryCZL.FindSet() then
            repeat
                OutgoingEETEntryCZL.Get(EETEntryCZL."Entry No.");
                OutgoingEETEntryCZL.Send(false);
            until EETEntryCZL.Next() = 0;
    end;

    var
        EETEntryCZL: Record "EET Entry CZL";
        OutgoingEETEntryCZL: Record "EET Entry CZL";
}