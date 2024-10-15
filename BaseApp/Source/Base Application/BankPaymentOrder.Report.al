report 12400 "Bank Payment Order"
{
    Caption = 'Bank Payment Order';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.") ORDER(Ascending);
            PrintOnlyIfDetail = false;

            trigger OnAfterGetRecord()
            begin
                TestField("Bank Payment Type", "Bank Payment Type"::"Computer Check");

                if Amount <= 0 then
                    FieldError(Amount, LessThanZeroErr);

                case PaymentDocType of
                    PaymentDocType::"Payment Order":
                        begin
                            TitleDoc := PayNoteTxt;
                            OKUD := '0401060';
                        end;
                    PaymentDocType::"Collection Payment Order":
                        begin
                            TitleDoc := InkPayNoteTxt;
                            OKUD := '0401060';
                        end;
                    PaymentDocType::"Payment Requisition":
                        begin
                            TitleDoc := PayingRequestTxt;
                            OKUD := '0401061';
                        end;
                    else
                        CurrReport.Break;
                end;

                if "Gen. Journal Line".KBK <> '' then
                    CompStat := CopyStr(Format("Gen. Journal Line"."Taxpayer Status"), 1, 2);

                StdRepMgt.CheckAttributes("Gen. Journal Line",
                  DocAmount, PayerCode, PayerText, BenefCode, BenefText);

                if Currency.Get("Currency Code") then
                    if Currency.Conventional then
                        DocAmount := "Amount (LCY)";

                TaxPeriod := "Tax Period";

                case PaymentDocType of
                    PaymentDocType::"Payment Order":
                        begin
                            if "Account Type" = "Account Type"::Vendor then begin
                                Vend.Get("Account No.");
                                if Vend."Control Tax Organ" <> '' then
                                    ContrTaxOrgan := '(' + Vend."Control Tax Organ" + ')';
                                if Vend."Tax Authority Code" <> '' then
                                    TaxPeriod := Vend."Tax Authority Code";
                            end;

                            if ("Payer Vendor No." <> '') and ("Payer Beneficiary Bank Code" <> '') then begin
                                VendorPayer.Get("Payer Vendor No.");
                                VendorBankPayer.Get("Payer Vendor No.", "Payer Beneficiary Bank Code");
                                BenefCode[1] := VendorPayer."VAT Registration No.";
                                BenefCode[2] := VendorBankPayer.BIC;
                                BenefCode[3] := VendorBankPayer."Bank Corresp. Account No.";
                                BenefCode[4] := VendorBankPayer."Bank Account No.";
                                BenefCode[4] := VendorPayer."KPP Code";
                                BenefText[1] := VendorPayer.Name;
                                BenefText[2] := VendorPayer."Name 2";
                                BenefText[3] := VendorBankPayer.Name;
                                BenefText[4] := VendorBankPayer."Name 2";
                                if VendorBankPayer.City <> '' then
                                    BenefText[5] := VendorBankPayer."Abbr. City" + '. ' + VendorBankPayer.City;
                                BenefText[6] := VendorBankPayer."Bank Branch No.";
                            end;
                        end;
                end;

                AmountInWords := LocMgt.Amount2Text(' ', Abs(DocAmount));

                if not "Check Printed" then
                    InsertCheckLedgerEntry("Gen. Journal Line");

                "Document No." := LocMgt.DigitalPartCode("Document No.");

                if PaymentDocType = PaymentDocType::"Payment Order" then
                    BankMark := ReceiverBankMarksTxt
                else
                    BankMark := BankMarksTxt;
            end;

            trigger OnPostDataItem()
            var
                LineValue: array[28] of Text;
            begin
                BankPaymentOrderHelper.FillHeader(OKUD);
                case PaymentDocType of
                    PaymentDocType::"Payment Order", PaymentDocType::"Collection Payment Order":
                        BankPaymentOrderHelper.FillTitle(
                          OKUD, StrSubstNo(TitleDoc, "Document No."), '', "Document Date", Format("Payment Method"), CompStat);
                    PaymentDocType::"Payment Requisition":
                        BankPaymentOrderHelper.FillRequestTitle(
                          OKUD, StrSubstNo(TitleDoc, "Document No."), '', "Document Date", Format("Payment Method"), CompStat);
                    else
                        CurrReport.Break;
                end;

                TransferLineValues(LineValue, "Gen. Journal Line");
                BankPaymentOrderHelper.FillBody(LineValue);
                BankPaymentOrderHelper.FillFooter(BankMark, "Payment Purpose");

                case PaymentDocType of
                    PaymentDocType::"Collection Payment Order", PaymentDocType::"Payment Requisition":
                        BankPaymentOrderHelper.FillMarks;
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get;
                BankPaymentOrderHelper.InitReportTemplate;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PaymentDocType; PaymentDocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Document Type';
                        OptionCaption = 'Payment Order,Collection Payment Order,Payment Requisition';
                        ToolTip = 'Specifies if the related document is for a payment or a refund.';
                    }
                    field(PrintTest; PrintTest)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Print';
                    }
                    field(SetPreview; Preview)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            BankPaymentOrderHelper.ExportDataFile(FileName)
        else
            BankPaymentOrderHelper.ExportData;
    end;

    var
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        DocumentNoTxt: Label 'XXXXXXXXXX', Locked = true;
        PrintQst: Label 'If %1 is not empty then it will be changed during posting %2\\Do you want to continue printing?';
        CanNotBeUsedErr: Label 'Cannot be used if %1 %2', Comment = '%1 - field caption, %2 - field value';
        BankMarksTxt: Label 'Bank marks', Comment = 'Must be translated: ÄÔ¼ÑÔ¬¿ íá¡¬á';
        CheckLedgEntry: Record "Check Ledger Entry";
        CompanyInfo: Record "Company Information";
        VendorPayer: Record Vendor;
        VendorBankPayer: Record "Vendor Bank Account";
        Currency: Record Currency;
        CheckManagement: Codeunit CheckManagement;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        BankPaymentOrderHelper: Codeunit "Bank Payment Order Helper";
        DocAmount: Decimal;
        PrintTest: Boolean;
        PaymentDocType: Option "Payment Order","Collection Payment Order","Payment Requisition";
        PayerCode: array[5] of Code[20];
        BenefCode: array[5] of Code[20];
        OKUD: Code[10];
        TitleDoc: Text;
        AmountInWords: Text;
        PayerText: array[6] of Text;
        BenefText: array[6] of Text;
        BankMark: Text;
        WrongDocumentNoErr: Label 'The number of the document %1 does not match the input mask %2 or greater than the last number.';
        LessThanZeroErr: Label 'Cannot be less than 0';
        LastNo: Code[20];
        ReceiverBankMarksTxt: Label 'Marks of the beneficiary bank', Comment = 'Must be translated: ÄÔ¼ÑÔ¬¿ íá¡¬á »«½ÒþáÔÑ½´';
        CompStat: Text;
        ContrTaxOrgan: Text;
        TaxPeriod: Text;
        FileName: Text;
        CodeIndex: Option ,INN,BIC,CorrAccNo,BankAccNo,KPP;
        TextIndex: Option ,Name,Name2,Bank,Bank2,City,Branch;
        PayNoteTxt: Label 'PAYMENT ORDER # %1', Comment = 'Must be translated: Å½áÔÑª¡«Ñ »«ÓÒþÑ¡¿Ñ';
        InkPayNoteTxt: Label 'COLLECTION\PAYMENT ORDER # %1', Comment = 'Must be translated: ê¡¬áßß«ó«Ñ\»½áÔÑª¡«Ñ »«ÓÒþÑ¡¿Ñ';
        PayingRequestTxt: Label 'PAYMENT REQUEST # %1', Comment = 'Must be translated: Å½áÔÑª¡«Ñ ÔÓÑí«óá¡¿Ñ';
        Preview: Boolean;

    [Scope('OnPrem')]
    procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        if Round(Amount, 1) = Amount then
            exit(Format(Amount, 0, 1) + '-00');
        if Round(Amount, 0.1) = Amount then
            exit(ConvertStr(Format(Amount, 0, 1) + '0', '.,', '--'));
        exit(ConvertStr(Format(Amount, 0, 1), '.,', '--'));
    end;

    local procedure InsertCheckLedgerEntry(GenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do
            if Preview or PrintTest then begin
                if "Document No." = '' then
                    "Document No." := DocumentNoTxt;

                BankAcc.Get("Bal. Account No.");
                if (("Account Type" = "Account Type"::"Bank Account") or
                    ("Bal. Account Type" = "Bal. Account Type"::"Bank Account")) and
                   ((Amount < 0) or (BankAcc."Account Type" = BankAcc."Account Type"::"Cash Account"))
                then
                    TestField("Bank Payment Type");
            end else
                if "Bank Payment Type" <> "Bank Payment Type"::"Computer Check" then begin
                    TestField("Document No.");
                    if "Posting No. Series" <> '' then
                        if not Confirm(PrintQst,
                             false, FieldCaption("Posting No. Series"), FieldCaption("Document No."))
                        then
                            Error('');
                end else begin
                    if "Posting No. Series" <> '' then
                        FieldError("Posting No. Series",
                          StrSubstNo(CanNotBeUsedErr,
                            FieldCaption("Bank Payment Type"), "Bank Payment Type"));
                    BankAcc.Get("Bal. Account No.");
                    case PaymentDocType of
                        PaymentDocType::"Payment Order":
                            begin
                                BankAcc.TestField("Bank Payment Order No. Series");
                                if "Document No." = '' then
                                    "Document No." := NoSeriesMgt.GetNextNo(BankAcc."Bank Payment Order No. Series", 0D, true)
                                else begin
                                    LastNo := NoSeriesMgt.GetNextNo(BankAcc."Bank Payment Order No. Series", 0D, false);
                                    Clear(NoSeriesMgt);
                                    if (DelChr("Document No.", '<>', '0123456789') <> DelChr(LastNo, '<>', '0123456789')) or
                                       ("Document No." > LastNo)
                                    then
                                        Error(WrongDocumentNoErr, "Document No.", LastNo);
                                    if "Document No." = LastNo then
                                        NoSeriesMgt.GetNextNo(BankAcc."Bank Payment Order No. Series", 0D, true);
                                end;
                                TestField("Document No.");
                            end;
                        PaymentDocType::"Collection Payment Order":
                            ;
                    end;
                    "Check Printed" := true;
                    Modify(true);
                    CheckLedgEntry.Init;
                    CheckLedgEntry."Bank Account No." := "Bal. Account No.";
                    CheckLedgEntry."Posting Date" := "Posting Date";
                    CheckLedgEntry."Check Date" := "Document Date";
                    CheckLedgEntry."Document Type" := "Document Type";
                    CheckLedgEntry."Document No." := "Document No.";
                    CheckLedgEntry.Description :=
                      CopyStr(Description, 1, MaxStrLen(CheckLedgEntry.Description));
                    CheckLedgEntry.Description :=
                      CopyStr(Description, 1, MaxStrLen(CheckLedgEntry.Description));
                    CheckLedgEntry.Amount := -DocAmount;
                    CheckLedgEntry.Positive := (CheckLedgEntry.Amount > 0);
                    if (CheckLedgEntry.Positive and (not Correction)) or
                       ((not CheckLedgEntry.Positive) and Correction)
                    then
                        CheckLedgEntry."Debit Amount" := CheckLedgEntry.Amount
                    else
                        CheckLedgEntry."Credit Amount" := -CheckLedgEntry.Amount;
                    CheckLedgEntry."Check No." := "Document No.";
                    CheckLedgEntry."Bank Payment Type" := "Bank Payment Type";
                    CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Printed;
                    CheckLedgEntry."Bal. Account Type" := "Account Type";
                    CheckLedgEntry."Bal. Account No." := "Account No.";
                    CheckLedgEntry."Beneficiary Bank Code" := "Beneficiary Bank Code";
                    CheckLedgEntry."Payment Purpose" := "Payment Purpose";
                    CheckLedgEntry."Payment Method" := "Payment Method";
                    CheckLedgEntry."Payment Before Date" := "Payment Date";
                    CheckLedgEntry."Payment Subsequence" := "Payment Subsequence";
                    CheckLedgEntry."Payment Code" := "Payment Code";
                    CheckLedgEntry."Payment Assignment" := "Payment Assignment";
                    CheckLedgEntry."Payment Type" := "Payment Type";
                    CheckLedgEntry."Payer BIC" := PayerCode[CodeIndex::BIC];
                    CheckLedgEntry."Payer Corr. Account No." := PayerCode[CodeIndex::CorrAccNo];
                    CheckLedgEntry."Payer Bank Account No." := PayerCode[CodeIndex::BankAccNo];
                    CheckLedgEntry."Payer Name" :=
                      CopyStr(PayerText[TextIndex::Name], 1, MaxStrLen(CheckLedgEntry."Payer Name"));
                    CheckLedgEntry."Payer Bank" :=
                      CopyStr(PayerText[TextIndex::Bank], 1, MaxStrLen(CheckLedgEntry."Payer Bank"));
                    CheckLedgEntry."Payer VAT Reg. No." := PayerCode[CodeIndex::INN];
                    CheckLedgEntry."Payer KPP" := PayerCode[CodeIndex::KPP];
                    CheckLedgEntry."Beneficiary BIC" := BenefCode[CodeIndex::BIC];
                    CheckLedgEntry."Beneficiary Corr. Acc. No." := BenefCode[CodeIndex::CorrAccNo];
                    CheckLedgEntry."Beneficiary Bank Acc. No." := BenefCode[CodeIndex::BankAccNo];
                    CheckLedgEntry."Beneficiary Name" :=
                      CopyStr(BenefText[TextIndex::Name], 1, MaxStrLen(CheckLedgEntry."Beneficiary Name"));
                    CheckLedgEntry."Beneficiary VAT Reg No." := BenefCode[CodeIndex::INN];
                    CheckLedgEntry."Beneficiary KPP" := BenefCode[CodeIndex::KPP];
                    CheckLedgEntry."Posting Group" := "Posting Group";
                    CheckLedgEntry.KBK := KBK;
                    CheckLedgEntry.OKATO := OKATO;
                    CheckLedgEntry."Period Code" := "Period Code";
                    CheckLedgEntry."Payment Reason Code" := "Payment Reason Code";
                    CheckLedgEntry."Reason Document No." := "Reason Document No.";
                    CheckLedgEntry."Reason Document Date" := "Reason Document Date";
                    CheckLedgEntry."Reason Document Type" := "Reason Document Type";
                    CheckLedgEntry."Tax Payment Type" := "Tax Payment Type";
                    CheckLedgEntry."Tax Period" := "Tax Period";
                    CheckLedgEntry."Taxpayer Status" := "Taxpayer Status";
                    CheckManagement.InsertCheck(CheckLedgEntry, RecordId);
                end;
    end;

    local procedure TransferLineValues(var LineValue: array[28] of Text; GenGnlLine: Record "Gen. Journal Line")
    begin
        LineValue[1] := AmountInWords;
        LineValue[2] := PayerCode[CodeIndex::INN];
        LineValue[3] := PayerCode[CodeIndex::KPP];
        LineValue[4] := PayerText[TextIndex::Name] + ' ' + PayerText[TextIndex::Name2] + '\' + PayerText[TextIndex::Branch];
        LineValue[5] := PayerText[TextIndex::Bank] + ' ' + PayerText[TextIndex::Bank2] + '\' + PayerText[TextIndex::City];
        LineValue[6] := BenefText[TextIndex::Bank] + ' ' + BenefText[TextIndex::Bank2] + '\' + BenefText[TextIndex::City];
        LineValue[7] := BenefCode[CodeIndex::INN];
        LineValue[8] := BenefCode[CodeIndex::KPP];
        LineValue[9] := BenefText[TextIndex::Name] + ' ' + BenefText[TextIndex::Name2] + '\' + BenefText[TextIndex::Branch];
        LineValue[10] := ContrTaxOrgan;
        LineValue[11] := FormatAmount(DocAmount);
        LineValue[12] := PayerCode[CodeIndex::BankAccNo];
        LineValue[13] := PayerCode[CodeIndex::BIC];
        LineValue[14] := PayerCode[CodeIndex::CorrAccNo];
        LineValue[15] := BenefCode[CodeIndex::BIC];
        LineValue[16] := BenefCode[CodeIndex::CorrAccNo];
        LineValue[17] := BenefCode[CodeIndex::BankAccNo];
        LineValue[18] := GenGnlLine."Payment Type";
        LineValue[19] := GenGnlLine."Payment Assignment";
        LineValue[20] := GenGnlLine."Payment Code";
        LineValue[21] := LocMgt.Date2Text(GenGnlLine."Payment Date");
        LineValue[22] := GenGnlLine."Payment Subsequence";
        LineValue[23] := GenGnlLine.KBK;
        LineValue[24] := GenGnlLine.OKATO;
        LineValue[25] := TaxPeriod;
        LineValue[26] := GenGnlLine."Reason Document No.";
        LineValue[27] := LocMgt.Date2Text(GenGnlLine."Reason Document Date");
        LineValue[28] := GenGnlLine."Tax Payment Type";
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

