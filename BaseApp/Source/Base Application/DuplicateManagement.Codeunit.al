codeunit 5060 DuplicateManagement
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Duplicate Contacts were found. Would you like to process these?';
        RMSetup: Record "Marketing Setup";
        DuplicateContactExistMsg: Label 'There are duplicate contacts.';
        OpenContactDuplicatesPageLbl: Label 'Show';

    procedure MakeContIndex(Cont: Record Contact)
    var
        DuplSearchStringSetup: Record "Duplicate Search String Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnMakeContIndex(Cont, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();

        RemoveContIndex(Cont, true);

        if DuplSearchStringSetup.Find('-') then
            repeat
                InsDuplContIndex(Cont, DuplSearchStringSetup);
            until DuplSearchStringSetup.Next = 0;

        InsDuplCont(Cont, RMSetup."Search Hit %");
    end;

    procedure RemoveContIndex(Cont: Record Contact; KeepAccepted: Boolean)
    var
        DuplContSearchString: Record "Cont. Duplicate Search String";
        DuplCont: Record "Contact Duplicate";
    begin
        DuplContSearchString.SetRange("Contact Company No.", Cont."No.");
        if DuplContSearchString.FindFirst then
            DuplContSearchString.DeleteAll();

        DuplCont.FilterGroup(-1);
        DuplCont.SetRange("Contact No.", Cont."No.");
        DuplCont.SetRange("Duplicate Contact No.", Cont."No.");
        DuplCont.FilterGroup(0);
        if KeepAccepted then
            DuplCont.SetRange("Separate Contacts", false);
        DuplCont.DeleteAll(true);
    end;

    procedure DuplicateExist(Cont: Record Contact): Boolean
    var
        DuplCont: Record "Contact Duplicate";
    begin
        RMSetup.Get();
        if not RMSetup."Autosearch for Duplicates" then
            exit(false);
        DuplCont.FilterGroup(-1);
        DuplCont.SetRange("Contact No.", Cont."No.");
        DuplCont.SetRange("Duplicate Contact No.", Cont."No.");
        DuplCont.FilterGroup(0);
        DuplCont.SetRange("Separate Contacts", false);
        exit(DuplCont.Find('=<>'));
    end;

    procedure LaunchDuplicateForm(Cont: Record Contact)
    var
        DuplCont: Record "Contact Duplicate";
    begin
        if Confirm(Text000, true) then begin
            DuplCont.SetRange("Contact No.", Cont."No.");
            PAGE.RunModal(PAGE::"Contact Duplicates", DuplCont);
        end
    end;

    local procedure InsDuplContIndex(Cont: Record Contact; DuplSearchStringSetup: Record "Duplicate Search String Setup")
    var
        DuplContSearchString: Record "Cont. Duplicate Search String";
        ContactRecRef: RecordRef;
    begin
        ContactRecRef.GetTable(Cont);

        DuplContSearchString.Init();
        DuplContSearchString."Contact Company No." := Cont."No.";
        DuplContSearchString."Field No." := DuplSearchStringSetup."Field No.";
        DuplContSearchString."Part of Field" := DuplSearchStringSetup."Part of Field";
        DuplContSearchString."Search String" :=
          ComposeIndexString(
            ContactRecRef, DuplContSearchString."Field No.",
            DuplSearchStringSetup."Part of Field", DuplSearchStringSetup.Length);

        if DuplContSearchString."Search String" <> '' then
            DuplContSearchString.Insert();
    end;

    local procedure InsDuplCont(Cont: Record Contact; HitRatio: Integer)
    var
        DuplContSearchString: Record "Cont. Duplicate Search String";
        DuplContSearchString2: Record "Cont. Duplicate Search String";
        DuplCont: Record "Contact Duplicate" temporary;
        DuplCont2: Record "Contact Duplicate";
        DuplSearchStringSetup: Record "Duplicate Search String Setup";
    begin
        DuplContSearchString.SetRange("Contact Company No.", Cont."No.");
        if DuplContSearchString.Find('-') then
            repeat
                DuplContSearchString2.SetCurrentKey("Field No.", "Part of Field", "Search String");
                DuplContSearchString2.SetRange("Field No.", DuplContSearchString."Field No.");
                DuplContSearchString2.SetRange("Part of Field", DuplContSearchString."Part of Field");
                DuplContSearchString2.SetRange("Search String", DuplContSearchString."Search String");
                DuplContSearchString2.SetFilter("Contact Company No.", '<>%1', DuplContSearchString."Contact Company No.");
                if DuplContSearchString2.Find('-') then
                    repeat
                        if DuplCont.Get(DuplContSearchString."Contact Company No.", DuplContSearchString2."Contact Company No.") then begin
                            if not DuplCont."Separate Contacts" then begin
                                DuplCont."No. of Matching Strings" := DuplCont."No. of Matching Strings" + 1;
                                DuplCont.Modify();
                            end;
                        end else begin
                            DuplCont."Contact No." := DuplContSearchString."Contact Company No.";
                            DuplCont."Duplicate Contact No." := DuplContSearchString2."Contact Company No.";
                            DuplCont."Separate Contacts" := false;
                            DuplCont."No. of Matching Strings" := 1;
                            DuplCont.Insert();
                        end;
                    until DuplContSearchString2.Next = 0;
            until DuplContSearchString.Next = 0;

        DuplCont.SetFilter("No. of Matching Strings", '>=%1', Round(DuplSearchStringSetup.Count * HitRatio / 100, 1, '>'));
        if DuplCont.Find('-') then begin
            repeat
                DuplCont2 := DuplCont;
                if not DuplCont2.Get(DuplCont."Contact No.", DuplCont."Duplicate Contact No.") and
                   not DuplCont2.Get(DuplCont."Duplicate Contact No.", DuplCont."Contact No.")
                then
                    DuplCont2.Insert(true);
            until DuplCont.Next = 0;
            DuplCont.DeleteAll();
        end;
    end;

    local procedure ComposeIndexString(var RecRef: RecordRef; FieldNo: Integer; "Part": Option First,Last; ChrToCopy: Integer): Text[10]
    var
        FieldRef: FieldRef;
        InString: Text[260];
    begin
        FieldRef := RecRef.Field(FieldNo);
        InString := Format(FieldRef.Value);
        InString := DelChr(InString, '=', ' +"&/,.;:-_(){}#!£$\');

        if StrLen(InString) < ChrToCopy then
            ChrToCopy := StrLen(InString);

        if ChrToCopy > 0 then
            if Part = Part::First then
                InString := CopyStr(InString, 1, ChrToCopy)
            else
                InString := CopyStr(InString, StrLen(InString) - ChrToCopy + 1, ChrToCopy);

        exit(UpperCase(InString));
    end;

    procedure Notify()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DuplicateContNotification: Notification;
        DummyRecID: RecordId;
    begin
        DuplicateContNotification.Message(DuplicateContactExistMsg);
        DuplicateContNotification.AddAction(OpenContactDuplicatesPageLbl, Codeunit::DuplicateManagement, 'RunModalContactDuplicates');
        NotificationLifecycleMgt.SendNotification(DuplicateContNotification, DummyRecID);
    end;

    procedure RunModalContactDuplicates(Notification: Notification)
    begin
        PAGE.RunModal(PAGE::"Contact Duplicates");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeContIndex(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;
}

