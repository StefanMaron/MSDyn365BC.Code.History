codeunit 132474 "Graph Contact Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [EventSubscriber(ObjectType::Table, 5450, 'OnBeforeModifyEvent', '', false, false)]
    procedure GenerateNewChangeKeyOnBeforeGraphContactModify(var Rec: Record "Graph Contact"; var xRec: Record "Graph Contact"; RunTrigger: Boolean)
    begin
        Rec.ChangeKey := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Rec.ChangeKey)), 1, MaxStrLen(Rec.ChangeKey));
    end;
}

