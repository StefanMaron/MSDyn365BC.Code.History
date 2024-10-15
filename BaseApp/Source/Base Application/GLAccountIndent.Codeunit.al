codeunit 3 "G/L Account-Indent"
{

    trigger OnRun()
    begin
        if not Confirm(
          Text1100000 +
          Text1100001 +
          Text1100002 +
          Text1100003 +
          Text1100004 +
          Text1100005, true)
        then
            exit;

        Indent;
    end;

    var
        Text004: Label 'Indenting the Chart of Accounts #1##########';
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
        Text1100000: Label 'This function checks the consistency of and completes the Chart of Accounts:\\';
        Text1100001: Label '- Checks that a corresponding heading account exists for every posting account.\';
        Text1100002: Label '- Checks that all accounts comply with the Chart of Account account length requisites.\';
        Text1100003: Label '- Assigns values to the following fields: Income/Balance/Capital, Account Type, Indentation, Totaling and Debit/Credit.\';
        Text1100004: Label '- Checks that an Adjustment Account exists for every account of the Income Statement and Capital types. \\';
        Text1100005: Label 'Do you wish to check the Chart of Accounts?';
        GLAcc: Record "G/L Account";
        FindAcc: Record "G/L Account";
        Window: Dialog;
        AccNo: array[10] of Code[20];
        i: Integer;
        Text1100006: Label 'Checking the Chart of Accounts #1########## @2@@@@@@@@@@@@@';
        Text1100007: Label 'The length of a heading account cannot be greater than 8, account %1';
        Text1100008: Label ' Missing group %1 - Account No. %2';
        Text1100009: Label '..';
        Text1100010: Label ' Missing group %1 - Account No. %2';
        Text1100011: Label 'The length of account %1 cannot be different than the next ones';
        Text1100012: Label 'The Chart of Accounts is correct.';
        HidePrintDialog: Boolean;

    procedure Indent()
    var
        LineCounter: Integer;
        NoOfRecords: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIndent(GLAcc, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text1100006);

        with GLAcc do begin
            Reset;
            LineCounter := 0;
            NoOfRecords := Count;
            if NoOfRecords <> 0 then begin
                if Find('-') then
                    repeat
                        Window.Update(1, "No.");

                        TestField(Name);

                        if StrLen("No.") > 5 then
                            "Account Type" := "Account Type"::Posting
                        else
                            "Account Type" := "Account Type"::Heading;

                        if "Account Type" = "Account Type"::Heading then begin
                            //The length of a heading account cannot be greater than 9
                            if StrLen("No.") > 8 then
                                Error(Text1100007, "No.");
                            //a heading account must exist at the previous higher level
                            if StrLen("No.") > 1 then
                                if not FindAcc.Get(CopyStr("No.", 1, StrLen("No.") - 1)) then
                                    Error(Text1100008, CopyStr("No.", 1, StrLen("No.") - 1), "No.");
                            Totaling := "No." + Text1100009 + PadStr("No.", 20 - (StrLen("No.") + 2), '9');
                            Validate(Indentation, StrLen("No.") - 1);
                        end else begin
                            //the corresponding heading account must exist
                            if not FindAcc.Get(CopyStr("No.", 1, 3)) then
                                Error(Text1100010, CopyStr("No.", 1, 3), "No.");
                            //a posting account must be the same length as the next
                            FindAcc := GLAcc;
                            if FindAcc.Next <> 0 then
                                if (FindAcc."Account Type" = FindAcc."Account Type"::Posting) and
                                   (StrLen("No.") <> StrLen(FindAcc."No.")) then
                                    Error(Text1100011, "No.");

                            if CopyStr("No.", 1, 1) in ['6', '7'] then
                                "Income/Balance" := "Income/Balance"::"Income Statement"
                            else
                                if CopyStr("No.", 1, 1) in ['8', '9'] then
                                    "Income/Balance" := "Income/Balance"::Capital
                                else
                                    "Income/Balance" := "Income/Balance"::"Balance Sheet";

                            if "Income/Balance" in ["Income/Balance"::"Income Statement", "Income/Balance"::Capital] then
                                TestField("Income Stmt. Bal. Acc.")
                            else
                                "Income Stmt. Bal. Acc." := '';
                            Indentation := 5;
                        end;

                        Modify;
                        LineCounter := LineCounter + 1;
                        Window.Update(2, Round(LineCounter / NoOfRecords * 10000, 1));
                    until Next() = 0;
            end;
        end;

        Window.Close;
        if not HidePrintDialog then
            Message(Text1100012);

        OnAfterIndent;
    end;

    procedure RunICAccountIndent()
    begin
        if not
          Confirm(
            Text1100000 +
            Text1100001 +
            Text1100002 +
            Text1100003 +
            Text1100004 +
            Text1100005, true)
        then
            exit;

        IndentICAccount;
    end;

    local procedure IndentICAccount()
    var
        ICGLAcc: Record "IC G/L Account";
        LineCounter: Integer;
        NoOfRecords: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIndentICAccount(GLAcc, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text1100006);

        with ICGLAcc do begin
            Reset;
            LineCounter := 0;
            NoOfRecords := Count;
            if NoOfRecords <> 0 then begin
                if Find('-') then
                    repeat
                        Window.Update(1, "No.");

                        TestField(Name);

                        if StrLen("No.") > 5 then
                            "Account Type" := "Account Type"::Posting
                        else
                            "Account Type" := "Account Type"::Heading;

                        if "Account Type" = "Account Type"::Heading then begin
                            //The length of a heading account cannot be greater than 9
                            if StrLen("No.") > 8 then
                                Error(Text1100007, "No.");
                            //a heading account must exist at the previous higher level
                            if StrLen("No.") > 1 then
                                if not FindAcc.Get(CopyStr("No.", 1, StrLen("No.") - 1)) then
                                    Error(Text1100008, CopyStr("No.", 1, StrLen("No.") - 1), "No.");
                            Validate(Indentation, StrLen("No.") - 1);
                        end else begin
                            //the corresponding heading account must exist
                            if not FindAcc.Get(CopyStr("No.", 1, 3)) then
                                Error(Text1100010, CopyStr("No.", 1, 3), "No.");
                            //a posting account must be the same length as the next
                            FindAcc := GLAcc;
                            if FindAcc.Next <> 0 then
                                if (FindAcc."Account Type" = FindAcc."Account Type"::Posting) and
                                   (StrLen("No.") <> StrLen(FindAcc."No.")) then
                                    Error(Text1100011, "No.");

                            if CopyStr("No.", 1, 1) in ['6', '7'] then
                                "Income/Balance" := "Income/Balance"::"Income Statement"
                            else
                                "Income/Balance" := "Income/Balance"::"Balance Sheet";
                            Indentation := 4;
                        end;

                        Modify;
                        LineCounter := LineCounter + 1;
                        Window.Update(2, Round(LineCounter / NoOfRecords * 10000, 1));
                    until Next() = 0;
            end;
        end;
        Window.Close;
        if not HidePrintDialog then
            Message(Text1100012);
    end;

    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        HidePrintDialog := NewHidePrintDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIndent()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIndent(var GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIndentICAccount(var GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;
}

