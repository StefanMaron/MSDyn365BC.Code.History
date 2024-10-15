/// <summary>
/// If an automatic inventory adjustment takes place during the sale/purchase posting then the counter (NextEntryNo) in codeunit 12 is not updated. 
/// This codeunit ensures that the last g/l entry number is obtained before the posting starts.
/// </summary>
codeunit 31139 "Get Last G/L Entry No. CZZ"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnCodeOnAfterStartOrContinuePosting', '', false, false)]
    local procedure UpdateNextEntryNoOnCodeOnAfterStartOrContinuePosting(var NextEntryNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.Get(NextEntryNo) then
            if GLEntry.FindLast() then
                NextEntryNo := GLEntry."Entry No." + 1;
    end;
}