codeunit 11400 "Local Functionality Mgt."
{
    // General functions for Local Functionality.


    trigger OnRun()
    begin
    end;

    var
        Text1000031: Label 'PG0123456789';
        Text1000032: Label 'P';
        Text1000033: Label 'G';
        Text1000034: Label 'PG';

    [Scope('OnPrem')]
    procedure CheckBankAccNo(Acc: Text[30]; CountryCode: Code[10]; var AccountNo: Text[30]) Result: Boolean
    var
        Len: Integer;
        BaseLen: Integer;
        FirstCharacter: Char;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBankAccNo(Acc, CountryCode, AccountNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        AccountNo := Acc;
        if CountryCode <> '' then
            exit(true);
        Acc := CharacterFilter(UpperCase(Acc), Text1000031);
        Acc := DelChr(Acc, '>', Text1000034);
        BaseLen := StrLen(Acc);
        if (StrPos(Acc, Text1000032) = 1) or
           (StrPos(Acc, Text1000033) = 1)
        then begin
            FirstCharacter := Acc[1];
            Acc := CharacterFilter(Acc, '0123456789');
            if BaseLen <> StrLen(Acc) + 1 then
                exit(false);
            Len := StrLen(Acc);
            if (Len < 1) or (Len > 9) then
                exit(false);
            if Len = 1 then
                if Acc[1] = '0' then
                    exit(false);
            Clear(AccountNo);
            AccountNo[1] := FirstCharacter;
            AccountNo := AccountNo + Acc;
            exit(true);
        end;

        Acc := DelChr(Acc, '=', Text1000034);
        case StrLen(Acc) of
            9:
                Acc := '00' + Acc;
            10:
                Acc := CopyStr(Acc, 1, 1) + Acc;
            else
                exit(false)
        end;
        if BaseLen < 12 then
            AccountNo := CopyStr(Acc, 12 - BaseLen);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CharacterFilter(Text: Text[250]; "Filter": Text[250]) Res: Text[250]
    begin
        exit(DelChr(Text, '=', DelChr(Text, '=', Filter)));
    end;

    [Scope('OnPrem')]
    procedure ConvertPhoneNumber(PhoneNumber: Text[20]) Res: Text[20]
    begin
        Res := CopyStr(CharacterFilter(PhoneNumber, '+0123456789'), 1, 20);

        if CopyStr(Res, 1, 3) <> '+31' then begin
            if CopyStr(Res, 1, 4) = '0031' then
                Res := '+31' + CopyStr(Res, 5)
            else
                Res := '+31' + CopyStr(Res, 2);
        end;

        if Res[4] = '0' then
            Res := '+31' + CopyStr(Res, 5);
    end;

    [Scope('OnPrem')]
    procedure GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory: Record "Payment History"; var PaymentHistoryLine: Record "Payment History Line"; var TotalAmount: Text[50]; var LineCount: Text[20])
    begin
        with PaymentHistoryLine do begin
            SetRange("Our Bank", PaymentHistory."Our Bank");
            SetRange("Run No.", PaymentHistory."Run No.");
            SetFilter(Status, '%1|%2|%3', Status::New, Status::Transmitted, Status::"Request for Cancellation");
            CalcSums(Amount);

            TotalAmount := Format(Abs(Amount), 0, '<Precision,2:2><Standard Format,9>');
            LineCount := Format(Count);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPmtHistLineCountAndAmtPmtInf(var TotalAmount: Text[50]; var LineCount: Text[20]; PaymentHistory: Record "Payment History"; GroupPaymentHistoryLine: Record "Payment History Line")
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.Reset;
        PaymentHistoryLine.SetCurrentKey(Date, "Sequence Type");
        PaymentHistoryLine.SetRange(Date, GroupPaymentHistoryLine.Date);
        PaymentHistoryLine.SetRange("Sequence Type", GroupPaymentHistoryLine."Sequence Type");
        GetPmtHistLineCountAndAmt(PaymentHistoryLine, TotalAmount, LineCount, PaymentHistory);
    end;

    [Scope('OnPrem')]
    procedure GetPmtHistLineCountAndAmt(var PaymentHistoryLine: Record "Payment History Line"; var TotalAmount: Text[50]; var LineCount: Text[20]; PaymentHistory: Record "Payment History")
    begin
        GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankAccNo(Acc: Text[30]; CountryCode: Code[10]; var AccountNo: Text[30]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

