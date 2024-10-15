#if not CLEAN17
codeunit 11799 "Registration No. Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        RegNoEnteredCustMsg: Label 'This %1 has already been entered for the following customers:\ %2.', Comment = '%1=fieldcaption, %2=customer number list';
        NumberList: Text[250];
        RegNoEnteredVendMsg: Label 'This %1 has already been entered for the following vendors:\ %2.', Comment = '%1=fieldcaption, %2=vendor number list';
        RegNoEnteredContMsg: Label 'This %1 has already been entered for the following contacts:\ %2.', Comment = '%1=fieldcaption, %2=contact number list';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.0')]
    procedure CheckRegistrationNo(RegNo: Text[20]; Number: Code[20]; TableID: Option): Boolean
    begin
        if RegNo = '' then
            exit(false);

        CheckDuplicity(RegNo, Number, TableID, false);
        exit(true);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.0')]
    procedure CheckTaxRegistrationNo(RegNo: Text[20]; Number: Code[20]; TableID: Option): Boolean
    begin
        if RegNo = '' then
            exit(false);

        CheckDuplicity(RegNo, Number, TableID, true);
        exit(true);
    end;

    local procedure CheckDuplicity(RegNo: Text[20]; Number: Code[20]; TableID: Option; IsTax: Boolean)
    begin
        case TableID of
            DATABASE::Customer:
                CheckCustDuplicity(RegNo, Number, IsTax);
            DATABASE::Vendor:
                CheckVendorDuplicity(RegNo, Number, IsTax);
            DATABASE::Contact:
                CheckContactDuplicity(RegNo, Number, IsTax);
        end;
    end;

    local procedure CheckCustDuplicity(RegNo: Text[20]; Number: Code[20]; IsTax: Boolean)
    var
        Cust: Record Customer;
        Finish: Boolean;
    begin
        if not IsTax then begin
            Cust.SetCurrentKey("Registration No.");
            Cust.SetRange("Registration No.", RegNo);
        end else
            Cust.SetRange("Tax Registration No.", RegNo);
        Cust.SetFilter("No.", '<>%1', Number);
        if Cust.FindSet then
            repeat
                Finish := not AddToNumberList(Cust."No.");
            until (Cust.Next() = 0) or Finish;

        if Cust.Count > 0 then
            Message(RegNoEnteredCustMsg, GetFieldCaption(IsTax), NumberList);
    end;

    local procedure CheckVendorDuplicity(RegNo: Text[20]; Number: Code[20]; IsTax: Boolean)
    var
        Vend: Record Vendor;
        Finish: Boolean;
    begin
        if not IsTax then begin
            Vend.SetCurrentKey("Registration No.");
            Vend.SetRange("Registration No.", RegNo);
        end else
            Vend.SetRange("Tax Registration No.", RegNo);
        Vend.SetFilter("No.", '<>%1', Number);
        if Vend.FindSet then
            repeat
                Finish := not AddToNumberList(Vend."No.");
            until (Vend.Next() = 0) or Finish;

        if Vend.Count > 0 then
            Message(RegNoEnteredVendMsg, GetFieldCaption(IsTax), NumberList);
    end;

    local procedure CheckContactDuplicity(RegNo: Text[20]; Number: Code[20]; IsTax: Boolean)
    var
        Cont: Record Contact;
        Finish: Boolean;
    begin
        if not IsTax then begin
            Cont.SetCurrentKey("Registration No.");
            Cont.SetRange("Registration No.", RegNo);
        end else
            Cont.SetRange("Tax Registration No.", RegNo);
        Cont.SetFilter("No.", '<>%1', Number);
        if Cont.FindSet then
            repeat
                Finish := not AddToNumberList(Cont."No.");
            until (Cont.Next() = 0) or Finish;

        if Cont.Count > 0 then
            Message(RegNoEnteredContMsg, GetFieldCaption(IsTax), NumberList);
    end;

    local procedure AddToNumberList(NewNumber: Code[20]): Boolean
    begin
        if NumberList = '' then
            NumberList := NewNumber
        else
            if StrLen(NumberList) + StrLen(NewNumber) + 5 <= MaxStrLen(NumberList) then
                NumberList += ', ' + NewNumber
            else begin
                NumberList += '...';
                exit(false);
            end;

        exit(true);
    end;

    local procedure GetFieldCaption(IsTax: Boolean): Text
    var
        Cust: Record Customer;
    begin
        if not IsTax then
            exit(Cust.FieldCaption("Registration No."));
        exit(Cust.FieldCaption("Tax Registration No."));
    end;
}


#endif