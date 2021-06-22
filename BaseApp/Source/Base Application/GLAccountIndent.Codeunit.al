codeunit 3 "G/L Account-Indent"
{

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(GLAccIndentQst, true) then
            exit;

        Indent;
    end;

    var
        GLAccIndentQst: Label 'This function updates the indentation of all the G/L accounts in the chart of accounts. All accounts between a Begin-Total and the matching End-Total are indented one level. The Totaling for each End-total is also updated.\\Do you want to indent the chart of accounts?';
        ICAccIndentQst: Label 'This function updates the indentation of all the G/L accounts in the chart of accounts. All accounts between a Begin-Total and the matching End-Total are indented one level. \\Do you want to indent the chart of accounts?';
        Text004: Label 'Indenting the Chart of Accounts #1##########';
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
        ArrayExceededErr: Label 'You can only indent %1 levels for accounts of the type Begin-Total.', Comment = '%1 = A number bigger than 1';
        GLAcc: Record "G/L Account";
        Window: Dialog;
        AccNo: array[10] of Code[20];
        i: Integer;

    procedure Indent()
    begin
        Window.Open(Text004);

        with GLAcc do
            if Find('-') then
                repeat
                    Window.Update(1, "No.");

                    if "Account Type" = "Account Type"::"End-Total" then begin
                        if i < 1 then
                            Error(
                              Text005,
                              "No.");
                        if Totaling = '' then
                            Totaling := AccNo[i] + '..' + "No.";
                        i := i - 1;
                    end;

                    Validate(Indentation, i);
                    Modify;

                    if "Account Type" = "Account Type"::"Begin-Total" then begin
                        i := i + 1;
                        if i > ArrayLen(AccNo) then
                            Error(ArrayExceededErr, ArrayLen(AccNo));
                        AccNo[i] := "No.";
                    end;
                until Next = 0;

        Window.Close;

        OnAfterIndent;
    end;

    procedure RunICAccountIndent()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(ICAccIndentQst, true) then
            exit;

        IndentICAccount;
    end;

    local procedure IndentICAccount()
    var
        ICGLAcc: Record "IC G/L Account";
    begin
        Window.Open(Text004);
        with ICGLAcc do
            if Find('-') then
                repeat
                    Window.Update(1, "No.");

                    if "Account Type" = "Account Type"::"End-Total" then begin
                        if i < 1 then
                            Error(
                              Text005,
                              "No.");
                        i := i - 1;
                    end;

                    Validate(Indentation, i);
                    Modify;

                    if "Account Type" = "Account Type"::"Begin-Total" then begin
                        i := i + 1;
                        AccNo[i] := "No.";
                    end;
                until Next = 0;
        Window.Close;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIndent()
    begin
    end;
}

