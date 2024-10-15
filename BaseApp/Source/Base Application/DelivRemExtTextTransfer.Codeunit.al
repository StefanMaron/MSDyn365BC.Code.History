codeunit 5005272 "Deliv.-Rem. Ext. Text Transfer"
{

    trigger OnRun()
    begin
    end;

    var
        Text1140000: Label 'There is not enough space to insert extended text lines.';
        GLAcc: Record "G/L Account";
        TmpExtTextLine: Record "Extended Text Line" temporary;
        NextLineNo: Integer;
        LineSpacing: Integer;
        MakeUpdateRequired: Boolean;
        AutoText: Boolean;

    [Scope('OnPrem')]
    procedure ReminderCheckIfAnyExtText(var DeliveryReminderLine: Record "Delivery Reminder Line"; Unconditionally: Boolean): Boolean
    var
        DeliveryReminder: Record "Delivery Reminder Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if DeliveryReminderLine."Line No." <> 0 then
            MakeUpdateRequired := DeleteDellivReminLine(DeliveryReminderLine);

        if Unconditionally then
            AutoText := true
        else
            case DeliveryReminderLine.Type of
                DeliveryReminderLine.Type::" ":
                    AutoText := true;
                DeliveryReminderLine.Type::"Account (G/L)":
                    if GLAcc.Get(DeliveryReminderLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        if AutoText then begin
            DeliveryReminderLine.TestField("Document No.");
            DeliveryReminder.Get(DeliveryReminderLine."Document No.");
            ExtTextHeader.SetRange("Table Name", DeliveryReminderLine.Type);
            ExtTextHeader.SetRange("No.", DeliveryReminderLine."No.");
            ExtTextHeader.SetRange("Delivery Reminder", true);
            exit(ReadLines(ExtTextHeader, DeliveryReminder."Document Date", DeliveryReminder."Language Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure DelivReminInsertExtendedText(var DeliveryReminderLine: Record "Delivery Reminder Line")
    var
        ForDeliveryReminderLine: Record "Delivery Reminder Line";
    begin
        ForDeliveryReminderLine.Reset;
        ForDeliveryReminderLine.SetRange("Document No.", DeliveryReminderLine."Document No.");
        ForDeliveryReminderLine := DeliveryReminderLine;
        if ForDeliveryReminderLine.Find('>') then begin
            LineSpacing :=
              (ForDeliveryReminderLine."Line No." - DeliveryReminderLine."Line No.") div
              (1 + TmpExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text1140000);
        end else
            LineSpacing := 10000;

        NextLineNo := DeliveryReminderLine."Line No." + LineSpacing;

        TmpExtTextLine.Reset;
        if TmpExtTextLine.Find('-') then begin
            repeat
                ForDeliveryReminderLine.Init;
                ForDeliveryReminderLine."Document No." := DeliveryReminderLine."Document No.";
                ForDeliveryReminderLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ForDeliveryReminderLine.Description := TmpExtTextLine.Text;
                ForDeliveryReminderLine."Attached to Line No." := DeliveryReminderLine."Line No.";
                ForDeliveryReminderLine.Insert;
            until TmpExtTextLine.Next = 0;
            MakeUpdateRequired := true;
        end;
        TmpExtTextLine.DeleteAll;
    end;

    [Scope('OnPrem')]
    procedure DeleteDellivReminLine(var DeliveryReminderLine: Record "Delivery Reminder Line"): Boolean
    var
        DeliveryReminderLine2: Record "Delivery Reminder Line";
    begin
        DeliveryReminderLine2.SetRange("Document No.", DeliveryReminderLine."Document No.");
        DeliveryReminderLine2.SetRange("Attached to Line No.", DeliveryReminderLine."Line No.");
        DeliveryReminderLine2 := DeliveryReminderLine;
        if DeliveryReminderLine2.Find('>') then begin
            repeat
                DeliveryReminderLine2.Delete;
            until DeliveryReminderLine2.Next = 0;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure MakeUpdate(): Boolean
    begin
        exit(MakeUpdateRequired);
    end;

    local procedure ReadLines(var ExtTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]): Boolean
    var
        ExtTextLine: Record "Extended Text Line";
    begin
        ExtTextHeader.SetCurrentKey(
          "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
        ExtTextHeader.SetRange("Starting Date", 0D, DocDate);
        ExtTextHeader.SetFilter("Ending Date", '%1..|%2', DocDate, 0D);
        if LanguageCode = '' then begin
            ExtTextHeader.SetRange("Language Code", '');
            if not ExtTextHeader.Find('+') then
                exit;
        end else begin
            ExtTextHeader.SetRange("Language Code", LanguageCode);
            if not ExtTextHeader.Find('+') then begin
                ExtTextHeader.SetRange("All Language Codes", true);
                ExtTextHeader.SetRange("Language Code", '');
                if not ExtTextHeader.Find('+') then
                    exit;
            end;
        end;

        ExtTextLine.SetRange("Table Name", ExtTextHeader."Table Name");
        ExtTextLine.SetRange("No.", ExtTextHeader."No.");
        ExtTextLine.SetRange("Language Code", ExtTextHeader."Language Code");
        ExtTextLine.SetRange("Text No.", ExtTextHeader."Text No.");
        if ExtTextLine.Find('-') then begin
            TmpExtTextLine.DeleteAll;
            repeat
                TmpExtTextLine := ExtTextLine;
                TmpExtTextLine.Insert;
            until ExtTextLine.Next = 0;
            exit(true);
        end;
    end;
}

