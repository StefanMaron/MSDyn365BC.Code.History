page 31126 "EET Simple Registration"
{
    Caption = 'EET Simple Registration';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "EET Entry";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Entry No.")
                      WHERE("Entry No." = CONST(0));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Business Premises Code"; "Business Premises Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the business premises.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupBusinessPremises(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateBusinessPremises;
                    end;
                }
                field("Cash Register Code"; "Cash Register Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the EET cash register.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupCashRegister(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCashRegister;
                    end;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s document number.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the EET entry.';
                }
                field(TotalSalesAmount; TotalSalesAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Sales Amount';
                    ToolTip = 'Specifies the total amount of cash document.';

                    trigger OnValidate()
                    begin
                        ValidateTotalSalesAmount;
                    end;
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the source type of the entry.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType;
                    end;
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the source number of the entry.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceNo(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateSourceNo;
                    end;
                }
                field("Applied Document Type"; "Applied Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the type of the applied document.';

                    trigger OnValidate()
                    begin
                        ValidateAppliedDocType;
                    end;
                }
                field("Applied Document No."; "Applied Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the applied document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupAppliedDocNo(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateAppliedDocNo;
                    end;
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                grid(Control1220025)
                {
                    GridLayout = Rows;
                    ShowCaption = false;
                    group(Control1220024)
                    {
                        ShowCaption = false;
                        field("SalesAmount[1]"; SalesAmount[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales Amount (VAT Rate Basic)';
                            ToolTip = 'Specifies Sales Amount (VAT Rate Basic)';

                            trigger OnValidate()
                            begin
                                ValidateSalesAmount(1);
                            end;
                        }
                        field("VATBase[1]"; VATBase[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'VAT Base';
                            ToolTip = 'Specifies the VAT base amount for cash desk document.';

                            trigger OnValidate()
                            begin
                                ValidateVATBase(1);
                            end;
                        }
                        field("VATAmount[1]"; VATAmount[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            ToolTip = 'Specifies the base VAT amount.';

                            trigger OnValidate()
                            begin
                                ValidateVATAmount(1);
                            end;
                        }
                        field("VATRate[1]"; VATRate[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT %';
                            DecimalPlaces = 0 : 2;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies VAT %';

                            trigger OnValidate()
                            begin
                                ValidateVATRate(1);
                            end;
                        }
                    }
                    group(Control1220019)
                    {
                        ShowCaption = false;
                        field("SalesAmount[2]"; SalesAmount[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales Amount (VAT Rate Reduced)';
                            ToolTip = 'Specifies Sales Amount (VAT Rate Reduced)';

                            trigger OnValidate()
                            begin
                                ValidateSalesAmount(2);
                            end;
                        }
                        field("VATBase[2]"; VATBase[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'VAT Base';
                            ToolTip = 'Specifies the reduced VAT base amount for cash desk document.';

                            trigger OnValidate()
                            begin
                                ValidateVATBase(2);
                            end;
                        }
                        field("VATAmount[2]"; VATAmount[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            ToolTip = 'Specifies the reduced VAT amount.';

                            trigger OnValidate()
                            begin
                                ValidateVATAmount(2);
                            end;
                        }
                        field("VATRate[2]"; VATRate[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT %';
                            DecimalPlaces = 0 : 2;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies VAT %';

                            trigger OnValidate()
                            begin
                                ValidateVATRate(2);
                            end;
                        }
                    }
                    group(Control1220014)
                    {
                        ShowCaption = false;
                        field("SalesAmount[3]"; SalesAmount[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales Amount (VAT Rate Reduced 2)';
                            ToolTip = 'Specifies Sales Amount (VAT Rate Reduced 2)';

                            trigger OnValidate()
                            begin
                                ValidateSalesAmount(3);
                            end;
                        }
                        field("VATBase[3]"; VATBase[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'VAT Base';
                            ToolTip = 'Specifies the reduced VAT base amount for cash desk document.';

                            trigger OnValidate()
                            begin
                                ValidateVATBase(3);
                            end;
                        }
                        field("VATAmount[3]"; VATAmount[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            ToolTip = 'Specifies the reduced VAT amount 2.';

                            trigger OnValidate()
                            begin
                                ValidateVATAmount(3);
                            end;
                        }
                        field("VATRate[3]"; VATRate[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT %';
                            DecimalPlaces = 0 : 2;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies VAT %';

                            trigger OnValidate()
                            begin
                                ValidateVATRate(3);
                            end;
                        }
                    }
                    group(Control1220009)
                    {
                        ShowCaption = false;
                        field(AmountArt89; AmountArt89)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount - Art.89';
                            Importance = Additional;
                            ToolTip = 'Specifies the amount under paragraph 89th.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                    }
                    group(Control1220007)
                    {
                        ShowCaption = false;
                        field("AmountArt90[1]"; AmountArt90[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount - Art.90 (Basic)';
                            Importance = Additional;
                            ToolTip = 'Specifies the base amount under paragraph 90th.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                        field("AmountArt90[2]"; AmountArt90[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount - Art.90 (Reduced)';
                            Importance = Additional;
                            ToolTip = 'Specifies the reduced amount under paragraph 90th.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                        field("AmountArt90[3]"; AmountArt90[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount - Art.90 (Reduced 2)';
                            Importance = Additional;
                            ToolTip = 'Specifies the reduced VAT base amount for cash desk document.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                    }
                    group(Control1220003)
                    {
                        ShowCaption = false;
                        field(AmountExtFromVAT; AmountExtFromVAT)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount Exempted From VAT';
                            Importance = Additional;
                            ToolTip = 'Specifies the amount of cash document VAT-exempt.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                        field(AmtForSubseqDrawSettle; AmtForSubseqDrawSettle)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amt. For Subseq. Draw/Settle';
                            Importance = Additional;
                            ToolTip = 'Specifies the amount of the payments for subsequent drawdown or settlement.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                        field(AmtSubseqDrawnSettled; AmtSubseqDrawnSettled)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amt. Subseq. Drawn/Settled';
                            Importance = Additional;
                            ToolTip = 'Specifies the amount of the subsequent drawing or settlement.';

                            trigger OnValidate()
                            begin
                                UpdateTotalSalesAmount;
                            end;
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Send To Register")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send To Register';
                    Image = SendElectronicDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Sends the selected entry to the EET service to register.';

                    trigger OnAction()
                    begin
                        SendSimpleEntryToService;
                        CurrPage.Update;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Get then begin
            Init;
            Insert;
        end;

        GetSetup;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        EETServiceSetup: Record "EET Service Setup";
        EETBusinessPremises: Record "EET Business Premises";
        EETCashRegister: Record "EET Cash Register";
        TotalSalesAmount: Decimal;
        SalesAmount: array[3] of Decimal;
        VATRate: array[3] of Decimal;
        VATBase: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        AmountArt89: Decimal;
        AmountArt90: array[3] of Decimal;
        AmountExtFromVAT: Decimal;
        AmtForSubseqDrawSettle: Decimal;
        AmtSubseqDrawnSettled: Decimal;
        NoCashDeskErr: Label 'User %1 does not have access to any Cash Desk.', Comment = '%1 = User ID';
        CashDeskDeniedErr: Label 'User %1 does not have access to the Cash Desk %2.', Comment = '%1 = User ID;%2 = Cah Desk No.';
        SendToServiceQst: Label 'Do you want to send sales to EET service?';
        MustEnterErr: Label 'You must enter %1.', Comment = '%1 = Field Name';
        OpenNewEntryQst: Label 'The new entry %1 has been created. Do you want to open the new entry?', Comment = '%1 = New EET Entry No.';

    local procedure GetSetup()
    begin
        GLSetup.Get();
        EETServiceSetup.Get();
        InitVATRate;
    end;

    local procedure InitVATRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        i: Integer;
    begin
        for i := 1 to 3 do begin
            VATPostingSetup.SetRange("VAT Rate", i);
            if VATPostingSetup.FindFirst then
                VATRate[i] := VATPostingSetup."VAT %";
        end;
    end;

    local procedure LookupBusinessPremises(var Text: Text): Boolean
    begin
        EETBusinessPremises.Reset();
        EETBusinessPremises.Code := "Business Premises Code";
        if EETBusinessPremises.Find then;
        if PAGE.RunModal(0, EETBusinessPremises) = ACTION::LookupOK then begin
            "Business Premises Code" := EETBusinessPremises.Code;
            ValidateBusinessPremises;
            Text := EETBusinessPremises.Code;
            exit(true);
        end;
    end;

    local procedure ValidateBusinessPremises()
    begin
        if "Business Premises Code" <> '' then
            EETBusinessPremises.Get("Business Premises Code");

        Clear("Cash Register Code");
    end;

    local procedure LookupCashRegister(var Text: Text): Boolean
    begin
        EETCashRegister.Reset();
        EETCashRegister.SetRange("Business Premises Code", "Business Premises Code");
        EETCashRegister."Business Premises Code" := "Business Premises Code";
        EETCashRegister.Code := "Cash Register Code";
        if EETCashRegister.Find then;
        if PAGE.RunModal(0, EETCashRegister) = ACTION::LookupOK then begin
            Text := EETCashRegister.Code;
            exit(true);
        end;
    end;

    local procedure ValidateCashRegister()
    begin
        if "Cash Register Code" <> '' then
            EETCashRegister.Get("Business Premises Code", "Cash Register Code");
    end;

    local procedure ValidateSourceType()
    begin
        Clear("Source No.");
    end;

    local procedure LookupSourceNo(var Text: Text): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        case "Source Type" of
            "Source Type"::"Cash Desk":
                begin
                    BankAccount."No." := "Source No.";
                    if BankAccount.Find then;
                    if PAGE.RunModal(PAGE::"Cash Desk List", BankAccount) = ACTION::LookupOK then begin
                        "Source No." := BankAccount."No.";
                        ValidateSourceNo;
                        Text := BankAccount."No.";
                        exit(true);
                    end;
                end;
        end;
    end;

    local procedure ValidateSourceNo()
    var
        BankAccount: Record "Bank Account";
        User: Record User;
        UserSetupMgt: Codeunit "User Setup Management";
        CashDeskMgt: Codeunit CashDeskManagement;
        CashFilter: Text;
        CashDeskFilter: Text;
    begin
        if "Source No." <> '' then
            case "Source Type" of
                "Source Type"::"Cash Desk":
                    begin
                        CashFilter := UserSetupMgt.GetCashFilter;
                        CashDeskFilter := CashDeskMgt.GetCashDesksFilter;
                        if (CashDeskFilter = '') and not User.IsEmpty then
                            Error(NoCashDeskErr, UserId);

                        BankAccount.Get("Source No.");
                        BankAccount.TestField("Account Type", BankAccount."Account Type"::"Cash Desk");

                        BankAccount.FilterGroup(2);
                        if CashFilter <> '' then
                            BankAccount.SetRange("Responsibility Center", CashFilter);
                        if CashDeskFilter <> '' then
                            BankAccount.SetFilter("No.", CashDeskFilter);
                        BankAccount.FilterGroup(0);
                        if not BankAccount.Find then
                            Error(CashDeskDeniedErr, UserId, BankAccount."No.");
                    end;
            end;
    end;

    local procedure ValidateAppliedDocType()
    begin
        Clear("Applied Document No.");
    end;

    local procedure LookupAppliedDocNo(var Text: Text): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
    begin
        case "Applied Document Type" of
            "Applied Document Type"::Invoice:
                begin
                    SalesInvoiceHeader."No." := "Applied Document No.";
                    if SalesInvoiceHeader.Find then;
                    if PAGE.RunModal(0, SalesInvoiceHeader) = ACTION::LookupOK then begin
                        Text := SalesInvoiceHeader."No.";
                        exit(true);
                    end;
                end;
            "Applied Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader."No." := "Applied Document No.";
                    if SalesCrMemoHeader.Find then;
                    if PAGE.RunModal(0, SalesCrMemoHeader) = ACTION::LookupOK then begin
                        Text := SalesCrMemoHeader."No.";
                        exit(true);
                    end;
                end;
            "Applied Document Type"::Prepayment:
                begin
                    SalesAdvanceLetterHeader."No." := "Applied Document No.";
                    if SalesAdvanceLetterHeader.Find then;
                    if PAGE.RunModal(0, SalesAdvanceLetterHeader) = ACTION::LookupOK then begin
                        Text := SalesAdvanceLetterHeader."No.";
                        exit(true);
                    end;
                end;
        end;
    end;

    local procedure ValidateAppliedDocNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
    begin
        if "Applied Document No." <> '' then
            case "Applied Document Type" of
                "Applied Document Type"::Invoice:
                    SalesInvoiceHeader.Get("Applied Document No.");
                "Applied Document Type"::"Credit Memo":
                    SalesCrMemoHeader.Get("Applied Document No.");
                "Applied Document Type"::Prepayment:
                    SalesAdvanceLetterHeader.Get("Applied Document No.");
            end;
    end;

    local procedure ValidateSalesAmount(Index: Integer)
    begin
        VATBase[Index] := Round(SalesAmount[Index] / (1 + VATRate[Index] / 100), GLSetup."Amount Rounding Precision");
        VATAmount[Index] := SalesAmount[Index] - VATBase[Index];
        UpdateTotalSalesAmount;
    end;

    local procedure ValidateVATBase(Index: Integer)
    begin
        VATAmount[Index] := Round(VATBase[Index] * VATRate[Index] / 100, GLSetup."Amount Rounding Precision");
        SalesAmount[Index] := VATBase[Index] + VATAmount[Index];
        UpdateTotalSalesAmount;
    end;

    local procedure ValidateVATAmount(Index: Integer)
    begin
        SalesAmount[Index] := VATBase[Index] + VATAmount[Index];
        if VATBase[Index] <> 0 then
            VATRate[Index] := Round(VATAmount[Index] / VATBase[Index] * 100, 0.01);
        UpdateTotalSalesAmount;
    end;

    local procedure ValidateVATRate(Index: Integer)
    begin
        VATAmount[Index] := Round(VATBase[Index] * VATRate[Index] / 100, GLSetup."Amount Rounding Precision");
        SalesAmount[Index] := VATBase[Index] + VATAmount[Index];
        UpdateTotalSalesAmount;
    end;

    local procedure ValidateTotalSalesAmount()
    begin
        Clear(SalesAmount);
        Clear(VATBase);
        Clear(VATAmount);
        Clear(VATRate);
        Clear(AmountArt89);
        Clear(AmountArt90);
        Clear(AmountExtFromVAT);
        Clear(AmtForSubseqDrawSettle);
        Clear(AmtSubseqDrawnSettled);
        InitVATRate;

        SalesAmount[1] := TotalSalesAmount;
        ValidateSalesAmount(1);
    end;

    local procedure UpdateTotalSalesAmount()
    begin
        TotalSalesAmount :=
          SalesAmount[1] + SalesAmount[2] + SalesAmount[3] +
          AmountArt89 + AmountArt90[1] + AmountArt90[2] + AmountArt90[3] +
          AmountExtFromVAT + AmtForSubseqDrawSettle + AmtSubseqDrawnSettled;
    end;

    [Scope('OnPrem')]
    procedure SendSimpleEntryToService()
    var
        EETEntry: Record "EET Entry";
        EETEntryMgt: Codeunit "EET Entry Management";
        NewEETEntryNo: Integer;
    begin
        if "Business Premises Code" = '' then
            Error(MustEnterErr, FieldCaption("Business Premises Code"));
        if "Cash Register Code" = '' then
            Error(MustEnterErr, FieldCaption("Cash Register Code"));
        if TotalSalesAmount = 0 then
            Error(MustEnterErr, FieldCaption("Total Sales Amount"));

        if not Confirm(SendToServiceQst, false) then
            exit;

        EETEntry.Init();
        EETEntry.CopySourceInfoFromEntry(Rec, false);

        EETEntry."Total Sales Amount" := TotalSalesAmount;
        EETEntry."Amount Exempted From VAT" := AmountExtFromVAT;
        EETEntry."VAT Base (Basic)" := VATBase[1];
        EETEntry."VAT Amount (Basic)" := VATAmount[1];
        EETEntry."VAT Base (Reduced)" := VATBase[2];
        EETEntry."VAT Amount (Reduced)" := VATAmount[2];
        EETEntry."VAT Base (Reduced 2)" := VATBase[3];
        EETEntry."VAT Amount (Reduced 2)" := VATAmount[3];
        EETEntry."Amount - Art.89" := AmountArt89;
        EETEntry."Amount (Basic) - Art.90" := AmountArt90[1];
        EETEntry."Amount (Reduced) - Art.90" := AmountArt90[2];
        EETEntry."Amount (Reduced 2) - Art.90" := AmountArt90[3];
        EETEntry."Amt. For Subseq. Draw/Settle" := AmtForSubseqDrawSettle;
        EETEntry."Amt. Subseq. Drawn/Settled" := AmtSubseqDrawnSettled;

        EETEntry.TestField("Total Sales Amount", EETEntry.SumPartialAmounts);

        NewEETEntryNo := EETEntryMgt.CreateEETEntrySimple(EETEntry, true, false, true);
        Commit();

        EETEntryMgt.RegisterEntry(NewEETEntryNo);

        Init;
        CurrPage.Update;
        InitVATRate;
        Clear(TotalSalesAmount);
        ValidateTotalSalesAmount;

        Commit();
        if EETEntry.Get(NewEETEntryNo) then
            if Confirm(StrSubstNo(OpenNewEntryQst, EETEntry."Entry No."), true) then
                PAGE.Run(PAGE::"EET Entry Card", EETEntry);
    end;
}

