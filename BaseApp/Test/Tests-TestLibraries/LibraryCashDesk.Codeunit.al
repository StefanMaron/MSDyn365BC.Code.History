codeunit 143010 "Library - Cash Desk"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryEET: Codeunit "Library - EET";
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateCashDesk(var BankAcc: Record "Bank Account")
    begin
        BankAcc.Init();
        BankAcc."Account Type" := BankAcc."Account Type"::"Cash Desk";
        BankAcc.Insert(true);

        BankAcc.Name := BankAcc."No.";
        BankAcc.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCashDeskEvent(var CashDeskEvent: Record "Cash Desk Event"; CashDeskNo: Code[20]; CashDocType: Option; AccountType: Option; AccountNo: Code[20])
    begin
        CashDeskEvent.Init();
        CashDeskEvent.Validate(Code, LibraryUtility.GenerateRandomCode(CashDeskEvent.FieldNo(Code), DATABASE::"Cash Desk Event"));
        CashDeskEvent.Insert(true);

        CashDeskEvent.Validate("Cash Desk No.", CashDeskNo);
        CashDeskEvent.Validate("Cash Document Type", CashDocType);
        CashDeskEvent.Validate("Account Type", AccountType);
        CashDeskEvent.Validate("Account No.", AccountNo);
        CashDeskEvent.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCashDeskUser(var CashDeskUser: Record "Cash Desk User"; CashDeskNo: Code[20]; Create: Boolean; Issue: Boolean; Post: Boolean)
    begin
        CashDeskUser.Init();
        CashDeskUser.Validate("Cash Desk No.", CashDeskNo);
        CashDeskUser.Validate("User ID", UserId);
        CashDeskUser.Insert(true);

        CashDeskUser.Validate(Create, Create);
        CashDeskUser.Validate(Issue, Issue);
        CashDeskUser.Validate(Post, Post);
        CashDeskUser.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateEETCashDesk(var BankAcc: Record "Bank Account")
    var
        EETBusinessPremises: Record "EET Business Premises";
        EETCashRegister: Record "EET Cash Register";
    begin
        CreateCashDesk(BankAcc);

        LibraryEET.CreateEETBusinessPremises(
          EETBusinessPremises, LibraryEET.GetDefaultBusinessPremisesIdentification);
        LibraryEET.CreateEETCashRegister(
          EETCashRegister, EETBusinessPremises.Code, EETCashRegister."Register Type"::"Cash Desk", BankAcc."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateEETCashDeskEvent(var CashDeskEvent: Record "Cash Desk Event"; CashDeskNo: Code[20]; CashDocType: Option; AccountType: Option; AccountNo: Code[20])
    begin
        CreateCashDeskEvent(CashDeskEvent, CashDeskNo, CashDocType, AccountType, AccountNo);
        CashDeskEvent.Validate("EET Transaction", true);
        CashDeskEvent.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateRoundingMethod(var RoundingMethod: Record "Rounding Method")
    begin
        RoundingMethod.Init();
        RoundingMethod.Code := LibraryUtility.GenerateRandomCode(RoundingMethod.FieldNo(Code), DATABASE::"Rounding Method");
        RoundingMethod.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCashDocumentHeader(var CashDocHdr: Record "Cash Document Header"; CashDocType: Option; CashDeskNo: Code[20])
    begin
        CashDocHdr.Init();
        CashDocHdr.Validate("Cash Desk No.", CashDeskNo);
        CashDocHdr.Validate("Cash Document Type", CashDocType);
        CashDocHdr.Insert(true);

        CashDocHdr."Payment Purpose" := CashDocHdr."No.";
        CashDocHdr.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCashDocumentLine(var CashDocLn: Record "Cash Document Line"; CashDocHdr: Record "Cash Document Header"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal)
    begin
        InsertCashDocumentLine(CashDocLn, CashDocHdr);

        CashDocLn.Validate("Account Type", AccountType);
        CashDocLn.Validate("Account No.", AccountNo);
        if Amount <> 0 then
            CashDocLn.Validate(Amount, Amount);
        CashDocLn.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCashDocumentLineWithCashDeskEvent(var CashDocLn: Record "Cash Document Line"; CashDocHdr: Record "Cash Document Header"; CashDeskEventCode: Code[10]; Amount: Decimal)
    var
        CashDocument: TestPage "Cash Document";
    begin
        // Created through the Test Page for validation "Cash Desk Event"

        CashDocument.OpenEdit;
        CashDocument.FILTER.SetFilter("Cash Desk No.", CashDocHdr."Cash Desk No.");
        CashDocument.FILTER.SetFilter("No.", CashDocHdr."No.");

        CashDocument.CashDocLines.Last;
        CashDocument.CashDocLines.Next;
        CashDocument.CashDocLines."Cash Desk Event".SetValue(CashDeskEventCode);
        if Amount <> 0 then
            CashDocument.CashDocLines.Amount.SetValue(Amount);

        CashDocument.OK.Invoke;

        CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
        CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
        CashDocLn.FindLast;
        CashDocLn.Reset();
    end;

    local procedure InsertCashDocumentLine(var CashDocLn: Record "Cash Document Line"; CashDocHdr: Record "Cash Document Header")
    var
        RecRef: RecordRef;
    begin
        CashDocLn.Init();
        CashDocLn.Validate("Cash Desk No.", CashDocHdr."Cash Desk No.");
        CashDocLn.Validate("Cash Document No.", CashDocHdr."No.");
        RecRef.GetTable(CashDocLn);
        CashDocLn.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, CashDocLn.FieldNo("Line No.")));
        CashDocLn.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ReleaseCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Cash Document-Release", CashDocHdr);
    end;

    [Scope('OnPrem')]
    procedure PostCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Cash Document-Post (Yes/No)", CashDocHdr);
    end;

    [Scope('OnPrem')]
    procedure PrintCashDocument(var CashDocHdr: Record "Cash Document Header"; ShowRequestPage: Boolean)
    var
        CashDocHdr2: Record "Cash Document Header";
    begin
        CashDocHdr2 := CashDocHdr;
        CashDocHdr2.SetRecFilter;
        CashDocHdr2.PrintRecords(ShowRequestPage);
    end;

    [Scope('OnPrem')]
    procedure PrintPostedCashDocument(var PostedCashDocHdr: Record "Posted Cash Document Header"; ShowRequestPage: Boolean)
    var
        PostedCashDocHdr2: Record "Posted Cash Document Header";
    begin
        PostedCashDocHdr2 := PostedCashDocHdr;
        PostedCashDocHdr2.SetRecFilter;
        PostedCashDocHdr2.PrintRecords(ShowRequestPage);
    end;

    [Scope('OnPrem')]
    procedure PrintCashDeskBook(ShowRequestPage: Boolean)
    begin
        REPORT.RunModal(REPORT::"Cash Desk Book", ShowRequestPage, false);
    end;
}

