codeunit 7000007 "Document-Misc"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Bill Group" = imd,
                  TableData "Closed Bill Group" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text1100000: Label 'This document is included in a posted bill group. Its %1 cannot be modified.';
        Text1100001: Label 'This document is closed. Its %1 cannot be modified.';
        Text1100002: Label 'This document is included in a posted payment order. Its %1 cannot be modified.';
        Text1100003: Label '%1 cannot be used in CSB Electronics Norms Exports.';
        Text1100004: Label '%1 cannot be used in CSB Electronic Norm Export No. 34./Norm Export No. 34.1';
        Text1100005: Label '%1 is not correct. Do you want to have it corrected?';
        Text1100006: Label 'This account has no control digit. Do you want to have it calculated?';
        Text1100007: Label 'Partial Bill settlement %1/%2';
        Text1100008: Label 'Partial Document settlement %1 Customer No. %2';
        Text1100009: Label 'Partial Document settlement %1';

    [Scope('OnPrem')]
    procedure UpdateReceivableDueDate(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        Doc: Record "Cartera Doc.";
    begin
        with CustLedgEntry do begin
            if "Document Situation" = "Document Situation"::" " then
                exit;
            case "Document Situation" of
                "Document Situation"::"BG/PO", "Document Situation"::Cartera:
                    begin
                        Doc.Get(Doc.Type::Receivable, "Entry No.");
                        Doc.Validate("Due Date", "Due Date");
                        Doc.Modify;
                    end;
                "Document Situation"::"Posted BG/PO":
                    Error(
                      Text1100000,
                      FieldCaption("Due Date"));
                "Document Situation"::"Closed BG/PO", "Document Situation"::"Closed Documents":
                    Error(
                      Text1100001,
                      FieldCaption("Due Date"));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePayableDueDate(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        Doc: Record "Cartera Doc.";
    begin
        with VendLedgEntry do begin
            if "Document Situation" = "Document Situation"::" " then
                exit;
            case "Document Situation" of
                "Document Situation"::"BG/PO", "Document Situation"::Cartera:
                    begin
                        Doc.Get(Doc.Type::Payable, "Entry No.");
                        Doc."Due Date" := "Due Date";
                        Doc.Modify;
                    end;
                "Document Situation"::"Posted BG/PO":
                    Error(
                      Text1100002,
                      FieldCaption("Due Date"));
                "Document Situation"::"Closed BG/PO", "Document Situation"::"Closed Documents":
                    Error(
                      Text1100001,
                      FieldCaption("Due Date"));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DocType(PmtMethodCode: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        with PaymentMethod do begin
            Get(PmtMethodCode);
            case "Bill Type" of
                "Bill Type"::"Bill of Exchange":
                    exit('1');
                "Bill Type"::Receipt:
                    exit('2');
                "Bill Type"::IOU:
                    exit('3');
                else
                    Error(Text1100003, PmtMethodCode);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DocType2(PmtMethodCode: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        with PaymentMethod do begin
            Get(PmtMethodCode);
            case "Bill Type" of
                "Bill Type"::Check:
                    exit('4');
                "Bill Type"::Transfer:
                    exit('5');
                else
                    Error(Text1100004, PmtMethodCode);
            end;
        end;
    end;

    local procedure CalcControlDigit(Branch: Text[30]; Bank: Text[30]): Text[2]
    var
        CarteraSetup: Record "Cartera Setup";
        Weight: Text[30];
        Digit1: Integer;
        Digit2: Integer;
        i: Integer;
        BranchDigit: Integer;
        BankDigit: Integer;
        WeightDigit: Integer;
    begin
        CarteraSetup.Get;
        Weight := CarteraSetup."CCC Ctrl Digits Check String";
        Digit1 := 0;
        Digit2 := 0;

        for i := 1 to StrLen(Branch) do begin
            Evaluate(BranchDigit, CopyStr(Branch, StrLen(Branch) - i + 1, 1));
            case i of
                1 .. 4:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 1));
                5:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 2));
                6 .. 11:
                    Evaluate(WeightDigit, CopyStr(Weight, i + 1, 1));
            end;
            Digit1 := Digit1 + (BranchDigit * WeightDigit);
        end;
        Digit1 := 11 - (Digit1 mod 11);

        if Digit1 = 10 then
            Digit1 := 1;
        if Digit1 = 11 then
            Digit1 := 0;

        for i := 1 to StrLen(Bank) do begin
            Evaluate(BankDigit, CopyStr(Bank, StrLen(Bank) - i + 1, 1));
            case i of
                1 .. 4:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 1));
                5:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 2));
                6 .. 11:
                    Evaluate(WeightDigit, CopyStr(Weight, i + 1, 1));
            end;
            Digit2 := Digit2 + (BankDigit * WeightDigit);
        end;
        Digit2 := 11 - (Digit2 mod 11);

        if Digit2 = 10 then
            Digit2 := 1;
        if Digit2 = 11 then
            Digit2 := 0;

        exit(Format(Digit1) + Format(Digit2));
    end;

    [Scope('OnPrem')]
    procedure CheckControlDigit(var CustCCCControlDigits: Text[2]; CustCCCBankBranchNo: Text[30]; CustCCCAccNo: Text[30]; Cust2: Text[30])
    var
        CarteraSetup: Record "Cartera Setup";
        CustBankAcc: Record "Customer Bank Account";
        MessageTxt: Text[150];
    begin
        CarteraSetup.Get;
        if CarteraSetup."CCC Ctrl Digits Check String" <> '' then
            if CustCCCControlDigits <> '' then begin
                if CalcControlDigit(CustCCCBankBranchNo + Cust2, CustCCCAccNo) <> CustCCCControlDigits then begin
                    MessageTxt := StrSubstNo(
                        Text1100005,
                        CustBankAcc.FieldCaption("CCC Control Digits"));
                    if not Confirm(MessageTxt) then
                        CustCCCControlDigits := '**'
                    else
                        CustCCCControlDigits := CalcControlDigit(CustCCCBankBranchNo + Cust2, CustCCCAccNo);
                end
            end else
                if not Confirm(Text1100006) then
                    CustCCCControlDigits := '**'
                else
                    CustCCCControlDigits := CalcControlDigit(CustCCCBankBranchNo + Cust2, CustCCCAccNo)
        else
            if CustCCCControlDigits = '' then
                CustCCCControlDigits := '**';
    end;

    [Scope('OnPrem')]
    procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; AccNo: Code[20]; DocNo: Code[20]; BillNo: Code[20]; TypeDoc: Option Bill,Invoice; CustAccNo: Code[20])
    var
        Description2: Text[50];
    begin
        with GLEntry do begin
            SetCurrentKey("G/L Account No.", Description);
            SetRange("G/L Account No.", AccNo);
            if TypeDoc = TypeDoc::Bill then
                Description2 := CopyStr(
                    StrSubstNo(Text1100007, DocNo, BillNo),
                    1, MaxStrLen(Description))
            else
                if CustAccNo <> '' then
                    Description2 := CopyStr(
                        StrSubstNo(Text1100008,
                          DocNo,
                          CustAccNo), 1, MaxStrLen(Description))
                else
                    Description2 := CopyStr(
                        StrSubstNo(Text1100009, DocNo),
                        1, MaxStrLen(Description));
            SetRange(Description, Description2);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRegisterCode(CurrCode: Code[10]; var RegisterCode: Integer; var RegisterString: Text[2]): Boolean
    var
        CarteraSetup: Record "Cartera Setup";
    begin
        with CarteraSetup do begin
            Get;
            if CurrCode = "Euro Currency Code" then begin
                RegisterCode := 50;
                RegisterString := '65';
                exit(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckBankSuffix(SuffixBankAccNo: Code[20]; BillGrBankAccNo: Code[20]): Boolean
    begin
        if SuffixBankAccNo <> BillGrBankAccNo then
            exit(false);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 86, 'OnAfterInsertAllSalesOrderLines', '', false, false)]
    local procedure RecalculateDiscountOnAfterInsertAllSalesOrderLines(var SalesOrderLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
        if SalesQuoteHeader."Payment Discount %" <> 0 then
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, 96, 'OnAfterInsertAllPurchOrderLines', '', false, false)]
    local procedure RecalculateDiscountOnAfterInsertAllPurchOrderLines(var PurchOrderLine: Record "Purchase Line"; PurchQuoteHeader: Record "Purchase Header")
    begin
        if PurchQuoteHeader."Payment Discount %" <> 0 then
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchOrderLine);
    end;
}

