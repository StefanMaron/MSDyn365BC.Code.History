codeunit 1713 "Exp. Positive Pay Handler"
{
    EventSubscriberInstance = Manual;

    procedure SetCheckLedgerEntryView(CheckLedgerEntryView: Text)
    begin
        GlobalCheckLedgerEntryView := CheckLedgerEntryView;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exp. Pre-Mapping Det Pos. Pay", 'OnGetFiltersBeforePreparingPosPayDetails', '', false, false)]
    local procedure GetFiltersBeforePreparingPosPayDetails(var CheckLedgerEntryView: Text)
    begin
        CheckLedgerEntryView := GlobalCheckLedgerEntryView;
    end;

    var
        GlobalCheckLedgerEntryView: Text;
}