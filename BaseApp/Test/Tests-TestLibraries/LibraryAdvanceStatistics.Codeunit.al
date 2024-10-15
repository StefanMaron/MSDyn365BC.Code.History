codeunit 143041 "Library - Advance Statistics"
{

    trigger OnRun()
    begin
    end;

    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterStatistics: TestPage "Purch. Adv. Letter Statistics";
        StatisticsValuesExist: Boolean;
        StatisticsValues: array[50] of Text;

    [Scope('OnPrem')]
    procedure GetGeneralAmount(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.ctrAmountGeneral.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountDeducted(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Deducted""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountIncludingVAT(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Including VAT""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountIncludingVATLCY(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.AmountInclVATLCY.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountInvoiced(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Invoiced""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountReceived(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmtReservedForJnlLine(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked To Journal Line""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountToDeduct(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Deduct""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountToInvoice(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Invoice""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralAmountToReceive(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Link""".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralNoOfVATLines(): Integer
    begin
        exit(TextToInteger(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."TempVATAmountLine1.COUNT".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralVATAmount(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""VAT Amount""".Value))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralVATAmountInvoiced(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.TotalVATInvoiced.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetGeneralVATAmountToInvoice(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.TotalVATToInvoice.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingAmount(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.InvoiceAmount.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingAmountIncludingVAT(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.InvoiceAmountIncludingVAT.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingAmountIncludingVATLCY(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.AmtIclVATLCY.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingNoOfVATLines(): Integer
    begin
        exit(TextToInteger(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."TempVATAmountLine2.COUNT".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingVATAmount(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.InvoiceVATAmount.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingVATAmountLCY(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics.VATAmtLCY.Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetInvoicingVATBaseLCY(): Decimal
    begin
        exit(TextToDecimal(GetFieldValue(GetFieldId(PurchAdvLetterStatistics."AmtIclVATLCY - VATAmtLCY".Caption))));
    end;

    [Scope('OnPrem')]
    procedure GetTemplateCode(): Code[10]
    begin
        exit(PurchAdvLetterHeader."Template Code");
    end;

    [Scope('OnPrem')]
    procedure SetPurchAdvLetter(var NewPurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    begin
        Initialize();
        PurchAdvLetterHeader := NewPurchAdvLetterHeader;
        OpenPurchAdvLetterStatistics;
    end;

    [Scope('OnPrem')]
    procedure SetPurchAdvLetterStatistics(var NewPurchAdvLetterStatistics: TestPage "Purch. Adv. Letter Statistics")
    begin
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.ctrAmountGeneral.Caption)] := NewPurchAdvLetterStatistics.ctrAmountGeneral.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""VAT Amount""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""VAT Amount""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Including VAT""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Including VAT""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.AmountInclVATLCY.Caption)] := NewPurchAdvLetterStatistics.AmountInclVATLCY.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Link""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Link""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked To Journal Line""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked To Journal Line""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Invoice""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Invoice""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.TotalVATToInvoice.Caption)] := NewPurchAdvLetterStatistics.TotalVATToInvoice.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Invoiced""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Invoiced""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.TotalVATInvoiced.Caption)] := NewPurchAdvLetterStatistics.TotalVATInvoiced.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Deduct""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Deduct""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Deducted""".Caption)] := NewPurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Deducted""".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."TempVATAmountLine1.COUNT".Caption)] := NewPurchAdvLetterStatistics."TempVATAmountLine1.COUNT".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.InvoiceAmount.Caption)] :=
          NewPurchAdvLetterStatistics.InvoiceAmount.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.InvoiceVATAmount.Caption)] :=
          NewPurchAdvLetterStatistics.InvoiceVATAmount.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.InvoiceAmountIncludingVAT.Caption)] :=
          NewPurchAdvLetterStatistics.InvoiceAmountIncludingVAT.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."AmtIclVATLCY - VATAmtLCY".Caption)] := NewPurchAdvLetterStatistics."AmtIclVATLCY - VATAmtLCY".Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.VATAmtLCY.Caption)] := NewPurchAdvLetterStatistics.VATAmtLCY.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics.AmtIclVATLCY.Caption)] := NewPurchAdvLetterStatistics.AmtIclVATLCY.Value;
        StatisticsValues[GetFieldId(PurchAdvLetterStatistics."TempVATAmountLine2.COUNT".Caption)] := NewPurchAdvLetterStatistics."TempVATAmountLine2.COUNT".Value;
        StatisticsValuesExist := true;
    end;

    local procedure GetFieldId(FieldCaption: Text): Integer
    begin
        case FieldCaption of
            PurchAdvLetterStatistics.ctrAmountGeneral.Caption:
                exit(1);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""VAT Amount""".Caption:
                exit(2);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Including VAT""".Caption:
                exit(3);
            PurchAdvLetterStatistics.AmountInclVATLCY.Caption:
                exit(4);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Link""".Caption:
                exit(5);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked""".Caption:
                exit(6);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Linked To Journal Line""".Caption:
                exit(7);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Invoice""".Caption:
                exit(8);
            PurchAdvLetterStatistics.TotalVATToInvoice.Caption:
                exit(9);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Invoiced""".Caption:
                exit(10);
            PurchAdvLetterStatistics.TotalVATInvoiced.Caption:
                exit(11);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount To Deduct""".Caption:
                exit(12);
            PurchAdvLetterStatistics."PurchAdvanceLetterLineGre.""Amount Deducted""".Caption:
                exit(13);
            PurchAdvLetterStatistics."TempVATAmountLine1.COUNT".Caption:
                exit(14);
            PurchAdvLetterStatistics.InvoiceAmount.Caption:
                exit(15);
            PurchAdvLetterStatistics.InvoiceVATAmount.Caption:
                exit(16);
            PurchAdvLetterStatistics.InvoiceAmountIncludingVAT.Caption:
                exit(17);
            PurchAdvLetterStatistics."AmtIclVATLCY - VATAmtLCY".Caption:
                exit(18);
            PurchAdvLetterStatistics.VATAmtLCY.Caption:
                exit(19);
            PurchAdvLetterStatistics.AmtIclVATLCY.Caption:
                exit(20);
            PurchAdvLetterStatistics."TempVATAmountLine2.COUNT".Caption:
                exit(21);
        end;
    end;

    local procedure GetFieldValue(FieldId: Integer): Text
    begin
        if not StatisticsValuesExist then
            OpenPurchAdvLetterStatistics;

        exit(StatisticsValues[FieldId]);
    end;

    local procedure Initialize()
    begin
        ClearAll;
        PurchAdvLetterStatistics.OpenView;
    end;

    local procedure OpenPurchAdvLetterStatistics()
    var
        PurchAdvLetter: TestPage "Purchase Advance Letter";
        PurchAdvLetters: TestPage "Purchase Advance Letters";
    begin
        if PurchAdvLetterHeader."No." = '' then
            exit;

        PurchAdvLetters.OpenView;
        PurchAdvLetters.GotoKey(PurchAdvLetterHeader."No.");
        PurchAdvLetter.Trap;
        PurchAdvLetters.View.Invoke;

        PurchAdvLetter.Statistics.Invoke;
        PurchAdvLetter.OK.Invoke;
        PurchAdvLetters.OK.Invoke;
    end;

    local procedure TextToDecimal(TextValue: Text): Decimal
    var
        DecValue: Decimal;
    begin
        Evaluate(DecValue, TextValue);
        exit(DecValue);
    end;

    [Scope('OnPrem')]
    procedure TextToInteger(TextValue: Text): Integer
    var
        IntValue: Integer;
    begin
        Evaluate(IntValue, TextValue);
        exit(IntValue);
    end;
}

