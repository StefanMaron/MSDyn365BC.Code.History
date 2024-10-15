#if not CLEAN17
codeunit 11730 CashDeskManagement
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        CashDeskNotExistErr: Label 'There are no Cash Desk accounts.';
        NotPermToPostErr: Label 'You don''t have permission to post %1.', Comment = '%1=CashDocHeader.TABLECAPTION';
        NotPermToPostToBankAccountErr: Label 'You don''t have permission to post to bank account %1.', Comment = '%1=number of bank account';
        NotPermToIssueErr: Label 'You don''t have permission to issue %1.', Comment = '%1=CashDocHeader.TABLECAPTION';
        NotPermToCreateErr: Label 'You don''t have permission to create %1.', Comment = '%1=CashDocHeader.TABLECAPTION';
        NotCashDeskUserErr: Label 'User %1 is not Cash Desk User.', Comment = '%1 = USERID';
        NotCashDeskUserOfCashDeskErr: Label 'User %1 is not Cash Desk User of %2.', Comment = '%1 = USERID, %2 = Cash Desk No.';
        NotCashDeskUserInRespCenterErr: Label 'User %1 is not Cash Desk User in set up Responsibility Center %2.', Comment = '%1 = USERID; %2 = Responsibility Center';
        NotCashDeskUserOfCashDeskInRespCenterErr: Label 'User %1 is not Cash Desk User of %2 is set up Responsibility Center %3.', Comment = '%1 = USERID; %2 = Cash Desk No.; %3 = Responsibility Center';
        EETDocReleaseDeniedErr: Label 'Cash desk %1 is set up as EET cash register. Cash documents for this EET cash register is not possible release only.\Cash document status must not be set up to value "Release" or "Release and Print".', Comment = '%1 = cash desk code';
        OneTxt: Label 'one';
        TwoTxt: Label 'two';
        TwoATxt: Label 'two';
        ThreeTxt: Label 'three';
        FourTxt: Label 'four';
        FiveTxt: Label 'five';
        SixTxt: Label 'six';
        SevenTxt: Label 'seven';
        EightTxt: Label 'eight';
        NineTxt: Label 'nine';
        TenTxt: Label 'ten';
        ElevenTxt: Label 'eleven';
        TwelveTxt: Label 'twelve';
        ThirteenTxt: Label 'thirteen';
        FourteenTxt: Label 'fourteen';
        FifteenTxt: Label 'fifteen';
        SixteenTxt: Label 'sixteen';
        SeventeenTxt: Label 'seventeen';
        EighteenTxt: Label 'eighteen';
        NineteenTxt: Label 'nineteen';
        TwentyTxt: Label 'twenty';
        ThirtyTxt: Label 'thirty';
        FortyTxt: Label 'forty';
        FiftyTxt: Label 'fifty';
        SixtyTxt: Label 'sixty';
        SeventyTxt: Label 'seventy';
        EightyTxt: Label 'eighty';
        NinetyTxt: Label 'ninety';
        OneHundredTxt: Label 'hundred';
        TwoHundredTxt: Label 'twohundred';
        ThreeHundredTxt: Label 'threehundred';
        FourHundredTxt: Label 'fourhundred';
        FiveHundredTxt: Label 'fivehundred';
        SixHundredTxt: Label 'sixhundred';
        SevenHundredTxt: Label 'sevenhundred';
        EightHundredTxt: Label 'eighthundred';
        NineHundredTxt: Label 'ninehundred';
        MilionTxt: Label 'million';
        MilionATxt: Label 'million';
        MilionBTxt: Label 'million';
        ThousandTxt: Label 'thousand';
        ThousandATxt: Label 'thousand';
        ThousandBTxt: Label 'thousand';
        UserSetupMgt: Codeunit "User Setup Management";
        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CashDocumentSelection(var CashDocumentHeader: Record "Cash Document Header"; var CashDeskSelected: Boolean)
    var
        BankAcc: Record "Bank Account";
        CashDeskFilter: Text;
    begin
        CashDeskSelected := true;

        CheckCashDesks;
        CashDeskFilter := GetCashDesksFilter;

        BankAcc.Reset();
        BankAcc.FilterGroup(2);
        if CashDeskFilter <> '' then
            BankAcc.SetFilter("No.", CashDeskFilter);
        BankAcc.FilterGroup(0);
        case BankAcc.Count of
            0:
                Error(CashDeskNotExistErr);
            1:
                BankAcc.FindFirst;
            else
                CashDeskSelected := PAGE.RunModal(PAGE::"Cash Desk List", BankAcc) = ACTION::LookupOK;
        end;
        if CashDeskSelected then begin
            CashDocumentHeader.FilterGroup(2);
            CashDocumentHeader.SetRange("Cash Desk No.", BankAcc."No.");
            CashDocumentHeader.FilterGroup(0);
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure FromAmountToDescription(FromAmount: Decimal) ToDescription: Text
    var
        ThreeFigure: Decimal;
        DecPlaces: Text[20];
    begin
        if FromAmount = Round(FromAmount, 1) then
            DecPlaces := ''
        else
            DecPlaces := ' + 0' + Format(FromAmount, 0, '<Decimal,3>');

        ThreeFigure := Round(FromAmount / 1000000, 1, '<');
        if ThreeFigure > 1 then begin
            ToDescription := ToDescription + ConvertBy100(ThreeFigure);
            if ThreeFigure > 4 then
                ToDescription := ToDescription + MilionBTxt
            else
                ToDescription := ToDescription + MilionATxt;
        end else
            if ThreeFigure = 1 then
                ToDescription := ToDescription + MilionTxt;
        FromAmount := FromAmount - ThreeFigure * 1000000;

        ThreeFigure := Round(FromAmount / 1000, 1, '<');
        if ThreeFigure > 1 then begin
            ToDescription := ToDescription + ConvertBy100(ThreeFigure);
            if ThreeFigure > 4 then
                ToDescription := ToDescription + ThousandBTxt
            else
                ToDescription := ToDescription + ThousandTxt;
        end else
            if ThreeFigure = 1 then
                ToDescription := ToDescription + ThousandATxt;
        FromAmount := FromAmount - ThreeFigure * 1000;

        ToDescription := ToDescription + ConvertBy100(Round(FromAmount, 1, '<'));

        if StrLen(ToDescription) = StrLen(TwoATxt) then
            if ToDescription = TwoATxt then
                ToDescription := TwoTxt;

        ToDescription := ToDescription + DecPlaces;
        ToDescription := UpperCase(CopyStr(ToDescription, 1, 1)) + CopyStr(ToDescription, 2) + '.';
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ConvertBy100(Hundred: Integer) ToDescription: Text[250]
    var
        From1To20: array[19] of Text[30];
        From10To90: array[9] of Text[30];
        From100To900: array[9] of Text[30];
        StrNo: Text[3];
        NoPos: Integer;
        i: Integer;
    begin
        From1To20[1] := OneTxt;
        From1To20[2] := TwoATxt;
        From1To20[3] := ThreeTxt;
        From1To20[4] := FourTxt;
        From1To20[5] := FiveTxt;
        From1To20[6] := SixTxt;
        From1To20[7] := SevenTxt;
        From1To20[8] := EightTxt;
        From1To20[9] := NineTxt;
        From1To20[10] := TenTxt;
        From1To20[11] := ElevenTxt;
        From1To20[12] := TwelveTxt;
        From1To20[13] := ThirteenTxt;
        From1To20[14] := FourteenTxt;
        From1To20[15] := FifteenTxt;
        From1To20[16] := SixteenTxt;
        From1To20[17] := SeventeenTxt;
        From1To20[18] := EighteenTxt;
        From1To20[19] := NineteenTxt;

        From10To90[1] := TenTxt;
        From10To90[2] := TwentyTxt;
        From10To90[3] := ThirtyTxt;
        From10To90[4] := FortyTxt;
        From10To90[5] := FiftyTxt;
        From10To90[6] := SixtyTxt;
        From10To90[7] := SeventyTxt;
        From10To90[8] := EightyTxt;
        From10To90[9] := NinetyTxt;

        From100To900[1] := OneHundredTxt;
        From100To900[2] := TwoHundredTxt;
        From100To900[3] := ThreeHundredTxt;
        From100To900[4] := FourHundredTxt;
        From100To900[5] := FiveHundredTxt;
        From100To900[6] := SixHundredTxt;
        From100To900[7] := SevenHundredTxt;
        From100To900[8] := EightHundredTxt;
        From100To900[9] := NineHundredTxt;

        StrNo := SelectStr(1, Format(Hundred));
        i := StrLen(StrNo);
        if i = 1 then
            StrNo := '00' + StrNo;
        if i = 2 then
            StrNo := '0' + StrNo;
        for i := 1 to 3 do begin
            Evaluate(NoPos, CopyStr(StrNo, i, 1));
            if (i = 1) and (NoPos <> 0) then
                ToDescription := ToDescription + From100To900[NoPos];
            if (i = 2) and (NoPos <> 0) then
                if NoPos = 1 then begin
                    Evaluate(NoPos, CopyStr(StrNo, i + 1, 1));
                    ToDescription := ToDescription + From1To20[NoPos + 10];
                end else
                    ToDescription := ToDescription + From10To90[NoPos];
            if (i = 3) and (NoPos <> 0) then
                if StrNo[i - 1] <> '1' then
                    ToDescription := ToDescription + From1To20[NoPos];
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentFromSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CashDocumentHeader: Record "Cash Document Header";
        DummyCashDocumentLine: Record "Cash Document Line";
        BankAccount: Record "Bank Account";
    begin
        if SalesInvoiceHeader."Cash Document Status" = SalesInvoiceHeader."Cash Document Status"::" " then
            exit;

        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        if SalesInvoiceHeader."Amount Including VAT" = 0 then
            exit;

        BankAccount.Get(SalesInvoiceHeader."Cash Desk Code");
        BankAccount.TestField("Currency Code", SalesInvoiceHeader."Currency Code");

        with CashDocumentHeader do begin
            "Cash Desk No." := SalesInvoiceHeader."Cash Desk Code";
            "Cash Document Type" := "Cash Document Type"::Receipt;
            Insert(true);

            CopyFromSalesInvoiceHeader(SalesInvoiceHeader);
            Modify(true);

            CreateCashDocumentLine(
              CashDocumentHeader,
              DummyCashDocumentLine."Account Type"::Customer, SalesInvoiceHeader."Bill-to Customer No.",
              DummyCashDocumentLine."Applies-To Doc. Type"::Invoice, SalesInvoiceHeader."No.");

            RunCashDocumentAction(CashDocumentHeader, SalesInvoiceHeader."Cash Document Status");
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentFromSalesCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CashDocumentHeader: Record "Cash Document Header";
        DummyCashDocumentLine: Record "Cash Document Line";
        BankAccount: Record "Bank Account";
    begin
        if SalesCrMemoHeader."Cash Document Status" = SalesCrMemoHeader."Cash Document Status"::" " then
            exit;

        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        if SalesCrMemoHeader."Amount Including VAT" = 0 then
            exit;

        BankAccount.Get(SalesCrMemoHeader."Cash Desk Code");
        BankAccount.TestField("Currency Code", SalesCrMemoHeader."Currency Code");

        with CashDocumentHeader do begin
            "Cash Desk No." := SalesCrMemoHeader."Cash Desk Code";
            "Cash Document Type" := "Cash Document Type"::Withdrawal;
            Insert(true);

            CopyFromSalesCrMemoHeader(SalesCrMemoHeader);
            Modify(true);

            CreateCashDocumentLine(
              CashDocumentHeader,
              DummyCashDocumentLine."Account Type"::Customer, SalesCrMemoHeader."Bill-to Customer No.",
              DummyCashDocumentLine."Applies-To Doc. Type"::"Credit Memo", SalesCrMemoHeader."No.");

            RunCashDocumentAction(CashDocumentHeader, SalesCrMemoHeader."Cash Document Status");
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentFromPurchaseInvoice(PurchInvHeader: Record "Purch. Inv. Header")
    var
        CashDocumentHeader: Record "Cash Document Header";
        DummyCashDocumentLine: Record "Cash Document Line";
        BankAccount: Record "Bank Account";
    begin
        if PurchInvHeader."Cash Document Status" = PurchInvHeader."Cash Document Status"::" " then
            exit;

        PurchInvHeader.CalcFields("Amount Including VAT");
        if PurchInvHeader."Amount Including VAT" = 0 then
            exit;

        BankAccount.Get(PurchInvHeader."Cash Desk Code");
        BankAccount.TestField("Currency Code", PurchInvHeader."Currency Code");

        with CashDocumentHeader do begin
            "Cash Desk No." := PurchInvHeader."Cash Desk Code";
            "Cash Document Type" := "Cash Document Type"::Withdrawal;
            Insert(true);

            CopyFromPurchInvHeader(PurchInvHeader);
            Modify(true);

            CreateCashDocumentLine(
              CashDocumentHeader,
              DummyCashDocumentLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.",
              DummyCashDocumentLine."Applies-To Doc. Type"::Invoice, PurchInvHeader."No.");

            RunCashDocumentAction(CashDocumentHeader, PurchInvHeader."Cash Document Status");
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentFromPurchaseCrMemo(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        CashDocumentHeader: Record "Cash Document Header";
        DummyCashDocumentLine: Record "Cash Document Line";
        BankAccount: Record "Bank Account";
    begin
        if PurchCrMemoHdr."Cash Document Status" = PurchCrMemoHdr."Cash Document Status"::" " then
            exit;

        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        if PurchCrMemoHdr."Amount Including VAT" = 0 then
            exit;

        BankAccount.Get(PurchCrMemoHdr."Cash Desk Code");
        BankAccount.TestField("Currency Code", PurchCrMemoHdr."Currency Code");

        with CashDocumentHeader do begin
            "Cash Desk No." := PurchCrMemoHdr."Cash Desk Code";
            "Cash Document Type" := "Cash Document Type"::Receipt;
            Insert(true);

            CopyFromPurchCrMemoHeader(PurchCrMemoHdr);
            Modify(true);

            CreateCashDocumentLine(
              CashDocumentHeader,
              DummyCashDocumentLine."Account Type"::Vendor, PurchCrMemoHdr."Buy-from Vendor No.",
              DummyCashDocumentLine."Applies-To Doc. Type"::"Credit Memo", PurchCrMemoHdr."No.");

            RunCashDocumentAction(CashDocumentHeader, PurchCrMemoHdr."Cash Document Status");
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentFromServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        CashDocumentHeader: Record "Cash Document Header";
        DummyCashDocumentLine: Record "Cash Document Line";
        BankAccount: Record "Bank Account";
    begin
        if ServiceInvoiceHeader."Cash Document Status" = ServiceInvoiceHeader."Cash Document Status"::" " then
            exit;

        ServiceInvoiceHeader.CalcFields("Amount Including VAT");
        if ServiceInvoiceHeader."Amount Including VAT" = 0 then
            exit;

        BankAccount.Get(ServiceInvoiceHeader."Cash Desk Code");
        BankAccount.TestField("Currency Code", ServiceInvoiceHeader."Currency Code");

        with CashDocumentHeader do begin
            "Cash Desk No." := ServiceInvoiceHeader."Cash Desk Code";
            "Cash Document Type" := "Cash Document Type"::Receipt;
            Insert(true);

            CopyFromServiceInvoiceHeader(ServiceInvoiceHeader);
            Modify(true);

            CreateCashDocumentLine(
              CashDocumentHeader,
              DummyCashDocumentLine."Account Type"::Customer, ServiceInvoiceHeader."Bill-to Customer No.",
              DummyCashDocumentLine."Applies-To Doc. Type"::Invoice, ServiceInvoiceHeader."No.");

            RunCashDocumentAction(CashDocumentHeader, ServiceInvoiceHeader."Cash Document Status");
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentFromServiceCrMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        CashDocumentHeader: Record "Cash Document Header";
        DummyCashDocumentLine: Record "Cash Document Line";
        BankAccount: Record "Bank Account";
    begin
        if ServiceCrMemoHeader."Cash Document Status" = ServiceCrMemoHeader."Cash Document Status"::" " then
            exit;

        ServiceCrMemoHeader.CalcFields("Amount Including VAT");
        if ServiceCrMemoHeader."Amount Including VAT" = 0 then
            exit;

        BankAccount.Get(ServiceCrMemoHeader."Cash Desk Code");
        BankAccount.TestField("Currency Code", ServiceCrMemoHeader."Currency Code");

        with CashDocumentHeader do begin
            "Cash Desk No." := ServiceCrMemoHeader."Cash Desk Code";
            "Cash Document Type" := "Cash Document Type"::Withdrawal;
            Insert(true);

            CopyFromServiceCrMemoHeader(ServiceCrMemoHeader);
            Modify(true);

            CreateCashDocumentLine(
              CashDocumentHeader,
              DummyCashDocumentLine."Account Type"::Customer, ServiceCrMemoHeader."Bill-to Customer No.",
              DummyCashDocumentLine."Applies-To Doc. Type"::"Credit Memo", ServiceCrMemoHeader."No.");

            RunCashDocumentAction(CashDocumentHeader, ServiceCrMemoHeader."Cash Document Status");
        end;
    end;

    local procedure CreateCashDocumentLine(CashDocumentHeader: Record "Cash Document Header"; AccountType: Option; AccountNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    var
        CashDocumentLine: Record "Cash Document Line";
    begin
        with CashDocumentLine do begin
            "Cash Desk No." := CashDocumentHeader."Cash Desk No.";
            "Cash Document No." := CashDocumentHeader."No.";
            "Line No." := 10000;
            Insert(true);

            SetHideValidationDialog(true);
            Validate("Account Type", AccountType);
            Validate("Account No.", AccountNo);
            Validate("Applies-To Doc. Type", AppliesToDocType);
            Validate("Applies-To Doc. No.", AppliesToDocNo);
            "Shortcut Dimension 1 Code" := CashDocumentHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := CashDocumentHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := CashDocumentHeader."Dimension Set ID";
            Modify(true);
        end;
    end;

    local procedure RunCashDocumentAction(CashDocumentHeader: Record "Cash Document Header"; ActionType: Option " ",Create,Release,Post,"Release and Print","Post and Print")
    var
        CashDocumentPostPrint: Codeunit "Cash Document-Post + Print";
    begin
        CashDocumentHeader.SetRecFilter;

        case ActionType of
            ActionType::Release:
                CODEUNIT.Run(CODEUNIT::"Cash Document-Release", CashDocumentHeader);
            ActionType::Post:
                CODEUNIT.Run(CODEUNIT::"Cash Document-Post", CashDocumentHeader);
            ActionType::"Release and Print":
                CODEUNIT.Run(CODEUNIT::"Cash Document-Release + Print", CashDocumentHeader);
            ActionType::"Post and Print":
                CashDocumentPostPrint.PostWithoutConfirmation(CashDocumentHeader);
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure CheckCashDocumentStatus(CashDeskCode: Code[20]; CashDocumentStatus: Option " ",Create,Release,Post,"Release and Print","Post and Print")
    var
        EETEntryManagement: Codeunit "EET Entry Management";
    begin
        if CashDeskCode = '' then
            exit;

        if (CashDocumentStatus in [CashDocumentStatus::Release, CashDocumentStatus::"Release and Print"]) and
           EETEntryManagement.IsEETCashRegister(CashDeskCode)
        then
            Error(EETDocReleaseDeniedErr, CashDeskCode);
    end;

    [TryFunction]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckUserRights(CashDeskNo: Code[20]; ActionType: Option " ",Create,Release,Post,"Release and Print","Post and Print"; EETTransaction: Boolean)
    var
        CashDeskUser: Record "Cash Desk User";
        CashDocHeader: Record "Cash Document Header";
        BankAcc: Record "Bank Account";
    begin
        if (CashDeskNo = '') or (ActionType = ActionType::" ") then
            exit;

        BankAcc.Get(CashDeskNo);

        CashDeskUser.SetRange("Cash Desk No.", CashDeskNo);
        if CashDeskUser.IsEmpty() then
            exit;
        CashDeskUser.SetRange("User ID", UserId);
        if CashDeskUser.IsEmpty() then
            CashDeskUser.SetRange("User ID", '');
        case ActionType of
            ActionType::Create:
                CashDeskUser.SetRange(Create, true);
            ActionType::Release, ActionType::"Release and Print":
                begin
                    CashDeskUser.SetRange(Issue, true);
                    if (BankAcc."Responsibility ID (Release)" <> '') and (BankAcc."Responsibility ID (Release)" <> UserId) then
                        Error(NotPermToIssueErr, CashDocHeader.TableCaption);
                end;
            ActionType::Post, ActionType::"Post and Print":
                begin
                    CashDeskUser.SetRange(Post, true);
                    if EETTransaction and CashDeskUser.IsEmpty() then begin
                        CashDeskUser.SetRange(Post);
                        CashDeskUser.SetRange("Post EET Only", true);
                    end;
                    if (BankAcc."Responsibility ID (Post)" <> '') and (BankAcc."Responsibility ID (Post)" <> UserId) then
                        Error(NotPermToPostErr, CashDocHeader.TableCaption);
                    if not CheckBankAccount(BankAcc."No.") then
                        Error(NotPermToPostToBankAccountErr, BankAcc."No.");
                end;
        end;
        if CashDeskUser.IsEmpty() then
            case ActionType of
                ActionType::Create:
                    Error(NotPermToCreateErr, CashDocHeader.TableCaption);
                ActionType::Release, ActionType::"Release and Print":
                    Error(NotPermToIssueErr, CashDocHeader.TableCaption);
                ActionType::Post, ActionType::"Post and Print":
                    Error(NotPermToPostErr, CashDocHeader.TableCaption);
            end;
    end;

    local procedure CheckBankAccount(BankAccountNo: Code[20]): Boolean
    begin
        if not UserSetupAdvMgt.IsCheckAllowed then
            exit(true);
        if not UserSetupAdvMgt.GetUserSetup then
            exit(true);
        exit(UserSetupAdvMgt.CheckBankAccount(BankAccountNo));
    end;

    [TryFunction]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckCashDesk(CashDeskNo: Code[20])
    begin
        CheckCashDesk2(CashDeskNo, UserId);
    end;

    [TryFunction]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckCashDesk2(CashDeskNo: Code[20]; UserCode: Code[50])
    begin
        if CashDeskNo = '' then
            exit;

        CheckCashDesks3(CashDeskNo, UserCode);
    end;

    [TryFunction]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckCashDesks()
    begin
        CheckCashDesks2(UserId);
    end;

    [TryFunction]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckCashDesks2(UserCode: Code[50])
    begin
        CheckCashDesks3('', UserCode);
    end;

    local procedure CheckCashDesks3(CashDeskNo: Code[20]; UserCode: Code[50])
    var
        User: Record User;
        TempBankAcc: Record "Bank Account" temporary;
        CashFilter: Code[10];
    begin
        if User.IsEmpty() then
            exit;

        GetCashDesksForCashDeskUser(UserCode, TempBankAcc);

        if CashDeskNo <> '' then
            TempBankAcc.SetRange("No.", CashDeskNo);

        if TempBankAcc.IsEmpty() then begin
            if CashDeskNo <> '' then
                Error(NotCashDeskUserOfCashDeskErr, UserCode, CashDeskNo);
            Error(NotCashDeskUserErr, UserCode);
        end;

        CashFilter := UserSetupMgt.GetCashFilter(UserCode);
        if CashFilter <> '' then
            TempBankAcc.SetRange("Responsibility Center", CashFilter);

        if TempBankAcc.IsEmpty() then begin
            if CashDeskNo <> '' then
                Error(NotCashDeskUserOfCashDeskInRespCenterErr, UserCode, CashDeskNo, CashFilter);
            Error(NotCashDeskUserInRespCenterErr, UserCode, CashFilter);
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetCashDesksFilter(): Text
    begin
        exit(GetCashDesksFilter2(UserId));
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetCashDesksFilter2(UserCode: Code[50]): Text
    var
        TempBankAcc: Record "Bank Account" temporary;
    begin
        GetCashDesks(UserCode, TempBankAcc);
        exit(GetCashDesksFilterFromBuffer(TempBankAcc));
    end;

    local procedure GetCashDesks(UserCode: Code[50]; var TempBankAcc: Record "Bank Account" temporary)
    var
        TempBankAcc2: Record "Bank Account" temporary;
        CashFilter: Code[10];
    begin
        GetCashDesksForCashDeskUser(UserCode, TempBankAcc2);
        CashFilter := UserSetupMgt.GetCashFilter(UserCode);
        if CashFilter <> '' then
            TempBankAcc2.SetRange("Responsibility Center", CashFilter);
        TempBankAcc.Copy(TempBankAcc2, true);
    end;

    local procedure GetCashDesksForCashDeskUser(UserCode: Code[50]; var TempBankAcc: Record "Bank Account" temporary)
    var
        BankAcc: Record "Bank Account";
        CashDeskUser: Record "Cash Desk User";
    begin
        TempBankAcc.DeleteAll();

        if CashDeskUser.IsEmpty() then begin
            BankAcc.SetRange("Account Type", BankAcc."Account Type"::"Cash Desk");
            if BankAcc.FindSet() then
                repeat
                    TempBankAcc.Init();
                    TempBankAcc := BankAcc;
                    TempBankAcc.Insert();
                until BankAcc.Next() = 0;
            exit;
        end;

        CashDeskUser.SetCurrentKey("User ID");
        CashDeskUser.SetFilter("User ID", '%1|%2', UserCode, '');
        if CashDeskUser.FindSet() then
            repeat
                BankAcc.Get(CashDeskUser."Cash Desk No.");
                TempBankAcc.Init();
                TempBankAcc := BankAcc;
                TempBankAcc.Insert();
            until CashDeskUser.Next() = 0;
    end;

    local procedure GetCashDesksFilterFromBuffer(var TempBankAcc: Record "Bank Account" temporary) CashDesksFilter: Text
    begin
        if TempBankAcc.FindSet then
            repeat
                CashDesksFilter += '|' + TempBankAcc."No.";
            until TempBankAcc.Next() = 0;

        CashDesksFilter := CopyStr(CashDesksFilter, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure CreateCashDocumentOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with SalesHeader do begin
            if ("Cash Desk Code" = '') or not Invoice then
                exit;

            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                SalesInvoiceHeader.Get(SalesInvHdrNo);
                CreateCashDocumentFromSalesInvoice(SalesInvoiceHeader);
            end else begin
                SalesCrMemoHeader.Get(SalesCrMemoHdrNo);
                CreateCashDocumentFromSalesCrMemo(SalesCrMemoHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure CreateCashDocumentOnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        with PurchaseHeader do begin
            if ("Cash Desk Code" = '') or not Invoice then
                exit;

            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                PurchInvHeader.Get(PurchInvHdrNo);
                CreateCashDocumentFromPurchaseInvoice(PurchInvHeader);
            end else begin
                PurchCrMemoHdr.Get(PurchCrMemoHdrNo);
                CreateCashDocumentFromPurchaseCrMemo(PurchCrMemoHdr);
            end;
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CreateCashDocumentOnAfterPostServiceDoc(var ServiceHeader: Record "Service Header"; Invoice: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedDocumentNo: Code[20];
    begin
        with ServiceHeader do begin
            if ("Cash Desk Code" = '') or not Invoice then
                exit;

            PostedDocumentNo := "Last Posting No.";
            if PostedDocumentNo = '' then
                PostedDocumentNo := "No.";

            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                ServiceInvoiceHeader.Get(PostedDocumentNo);
                CreateCashDocumentFromServiceInvoice(ServiceInvoiceHeader);
            end else begin
                ServiceCrMemoHeader.Get(PostedDocumentNo);
                CreateCashDocumentFromServiceCrMemo(ServiceCrMemoHeader);
            end;
        end;
    end;
}
#endif