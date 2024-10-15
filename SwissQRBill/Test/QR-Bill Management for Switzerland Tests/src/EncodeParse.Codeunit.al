codeunit 148094 "Swiss QR-Bill Test EncodeParse"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Swiss QR-Bill] [UT]
    end;

    var
        Mgt: Codeunit "Swiss QR-Bill Mgt.";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        Library: Codeunit "Swiss QR-Bill Test Library";
        Encode: Codeunit "Swiss QR-Bill Encode";
        ReferenceType: Enum "Swiss QR-Bill Payment Reference Type";
        AddressType: Enum "Swiss QR-Bill Address Type";

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_AllowedCurrencyCode()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".AllowedCurrencyCode()
        Assert.IsTrue(Mgt.AllowedCurrencyCode(''), '');
        Assert.IsTrue(Mgt.AllowedCurrencyCode('EUR'), '');
        Assert.IsTrue(Mgt.AllowedCurrencyCode(Library.CreateCurrency('CHF')), '');
        Assert.IsTrue(Mgt.AllowedCurrencyCode(Library.CreateCurrency('EUR')), '');

        Assert.IsFalse(Mgt.AllowedCurrencyCode('USD'), '');
        Assert.IsFalse(Mgt.AllowedCurrencyCode('qwerty'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_CheckDigitForQRReference()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".CheckDigitForQRReference()
        Assert.IsFalse(Mgt.CheckDigitForQRReference(''), '');
        Assert.IsFalse(Mgt.CheckDigitForQRReference('000000000000000000000000025'), '');
        Assert.IsTrue(Mgt.CheckDigitForQRReference('000000000000000000000000026'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_CheckDigitForCreditorReference()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".CheckDigitForCreditorReference()
        Assert.IsFalse(Mgt.CheckDigitForCreditorReference(''), '');
        Assert.IsFalse(Mgt.CheckDigitForCreditorReference('RF462'), '');
        Assert.IsTrue(Mgt.CheckDigitForCreditorReference('RF472'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_GetNextReferenceNo_QRRef()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".GetNextReferenceNo() in case of QR-Reference
        UpdateLastReferenceNo(12345);
        Assert.AreEqual(
            '000000000000000000000123465',
            Mgt.GetNextReferenceNo(ReferenceType::"QR Reference", false), '');

        VerifyLastReferenceNo(12345);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_GetNextReferenceNo_UpdateLastNo_QRRef()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".GetNextReferenceNo() in case of QR-Reference, update last reference no.
        UpdateLastReferenceNo(12345);
        Assert.AreEqual(
            '000000000000000000000123465',
            Mgt.GetNextReferenceNo(ReferenceType::"QR Reference", true), '');

        VerifyLastReferenceNo(12346);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_GetNextReferenceNo_CRRef()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".GetNextReferenceNo() in case of Creditor-Reference
        UpdateLastReferenceNo(12345);
        Assert.AreEqual(
            'RF5112346',
            Mgt.GetNextReferenceNo(ReferenceType::"Creditor Reference (ISO 11649)", false), '');

        VerifyLastReferenceNo(12345);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_GetNextReferenceNo_UpdateLastNo_CRRef()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".GetNextReferenceNo() in case of Creditor-Reference, update last reference no.
        UpdateLastReferenceNo(12345);
        Assert.AreEqual(
            'RF5112346',
            Mgt.GetNextReferenceNo(ReferenceType::"Creditor Reference (ISO 11649)", true), '');

        VerifyLastReferenceNo(12346);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_FormatPaymentReference_QRRef()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".FormatPaymentReference() in case of QR-Reference
        Assert.AreEqual(
            '12 34567 89012 34567 89012 34567',
            Mgt.FormatPaymentReference(ReferenceType::"QR Reference", '123456789012345678901234567'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Mgt_FormatPaymentReference_CRRef()
    begin
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Mgt.".FormatPaymentReference() in case of Creditor-Reference
        Assert.AreEqual(
            'RF12 34',
            Mgt.FormatPaymentReference(ReferenceType::"Creditor Reference (ISO 11649)", 'RF1234'), '');

        Assert.AreEqual(
            'RF12 3456 7890 1235 4678 9012 3',
            Mgt.FormatPaymentReference(ReferenceType::"Creditor Reference (ISO 11649)", 'RF12345678901235467890123'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_CreditorInfo_Structured()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), creditor info, structured
        AddCreditorInfo(Buffer, Buffer."Creditor Address Type"::Structured);

        Assert.AreEqual(
            'SPC\0200\1\\S\CR Name\CR A1\CR A2\CR POST\CR CITY\C1\\\\\\\\\\\\\\\\\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_CreditorInfo_Combined()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), creditor info, combined
        AddCreditorInfo(Buffer, Buffer."Creditor Address Type"::Combined);

        Assert.AreEqual(
            'SPC\0200\1\\K\CR Name\CR A1 CR A2\CR POST CR CITY\\\C1\\\\\\\\\\\\\\\\\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_UCreditorInfo_Structured()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), ultimate creditor info, structured
        AddUCreditorInfo(Buffer, Buffer."Creditor Address Type"::Structured);

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\S\UCR Name\UCR A1\UCR A2\UCR POST\UCR CITY\C2\\\\\\\\\\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_UCreditorInfo_Combined()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), ultimate creditor info, combined
        AddUCreditorInfo(Buffer, Buffer."Creditor Address Type"::Combined);

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\K\UCR Name\UCR A1 UCR A2\UCR POST UCR CITY\\\C2\\\\\\\\\\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_DebitorInfo_Structured()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), debitor info, structured
        AddDebitorInfo(Buffer, Buffer."UDebtor Address Type"::Structured);

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\S\UD Name\UD A1\UD A2\UD POST\UD CITY\C3\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_DebitorInfo_Combined()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), debitor info, combined
        AddDebitorInfo(Buffer, Buffer."UDebtor Address Type"::Combined);

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\K\UD Name\UD A1 UD A2\UD POST UD CITY\\\C3\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_PaymentInfo_WithoutReference()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), payment info without reference
        AddBasicInfo(Buffer, 'IBAN123', 'AAA', 123.45, ReferenceType::"Without Reference", '');

        Assert.AreEqual(
            'SPC\0200\1\IBAN123\S\\\\\\\\\\\\\\123.45\AAA\\\\\\\\NON\\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_PaymentInfo_QRReference()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), payment info, QR-reference
        AddBasicInfo(Buffer, 'IBAN123', 'AAA', 123.45, ReferenceType::"QR Reference", 'QR-REF-123');

        Assert.AreEqual(
            'SPC\0200\1\IBAN123\S\\\\\\\\\\\\\\123.45\AAA\\\\\\\\QRR\QR-REF-123\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_PaymentInfo_CreditorReference()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), payment info, Creditor-reference
        AddBasicInfo(Buffer, 'IBAN123', 'AAA', 123.45, ReferenceType::"Creditor Reference (ISO 11649)", 'CR-REF-123');

        Assert.AreEqual(
            'SPC\0200\1\IBAN123\S\\\\\\\\\\\\\\123.45\AAA\\\\\\\\SCOR\CR-REF-123\\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_UnstrMsg()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), only unstructured message
        AddAddInfo(Buffer, 'Unstr Msg', '', '', '', '', '');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\Unstr Msg\EPD',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_BillInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), only billing information
        AddAddInfo(Buffer, '', 'Bill Info', '', '', '', '');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\\EPD\Bill Info',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_AltProc1()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), only alternative procedure 1
        AddAddInfo(Buffer, '', '', 'Alt Name 1', 'Alt Value 1', '', '');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\\EPD\\Alt Name 1: Alt Value 1',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_AltProc2()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), only alternative procedure 2
        AddAddInfo(Buffer, '', '', '', '', 'Alt Name 2', 'Alt Value 2');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\\EPD\\\Alt Name 2: Alt Value 2',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_BothAltValues()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), both alternative procedures
        AddAddInfo(Buffer, '', '', 'Alt Name 1', 'Alt Value 1', 'Alt Name 2', 'Alt Value 2');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\\EPD\\Alt Name 1: Alt Value 1\Alt Name 2: Alt Value 2',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_UnstrMsgAndBillInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), unstructured message and billing information
        AddAddInfo(Buffer, 'Unstr Msg', 'Bill Info', '', '', '', '');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\Unstr Msg\EPD\Bill Info',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_AllAdditionalInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), unstructured message and billing information
        AddAddInfo(Buffer, 'Unstr Msg', 'Bill Info', 'Alt Name 1', 'Alt Value 1', 'Alt Name 2', 'Alt Value 2');

        Assert.AreEqual(
            'SPC\0200\1\\S\\\\\\\\\\\\\\\\\\\\\\\NON\\Unstr Msg\EPD\Bill Info\Alt Name 1: Alt Value 1\Alt Name 2: Alt Value 2',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateQRCodeText_QRPmt_Cred_Deb_AddInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
    begin
        // [FEATURE] [Encode]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Encode".GenerateQRCodeText(), creditor, debitor, QR-reference, unstructured message, billing info
        AddCreditorInfo(Buffer, Buffer."Creditor Address Type"::Structured);
        AddDebitorInfo(Buffer, Buffer."UDebtor Address Type"::Structured);
        AddBasicInfo(Buffer, 'IBAN123', 'AAA', 123.45, ReferenceType::"QR Reference", 'QR-REF-123');
        AddAddInfo(Buffer, 'Unstr Msg', 'Bill Info', '', '', '', '');

        Assert.AreEqual(
            'SPC\0200\1\IBAN123\S\CR Name\CR A1\CR A2\CR POST\CR CITY\C1\\\\\\\\123.45\AAA\S\UD Name\UD A1\UD A2\UD POST\UD CITY\C3\QRR\QR-REF-123\Unstr Msg\EPD\Bill Info',
            Library.ReplaceLineBreakWithBackSlash(Encode.GenerateQRCodeText(Buffer)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_NoAmt_NoRef()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, IBAN, no amount, no reference
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferPmtInfo(Buffer, 'CH5800791123000889012', 'CHF', 0, ReferenceType::"Without Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_Amt_NoRef()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, IBAN, amount, no reference
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\123.45\CHF\\\\\\\\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferPmtInfo(Buffer, 'CH5800791123000889012', 'CHF', 123.45, ReferenceType::"Without Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_Amt_QRRef()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, IBAN, amount, QR-reference
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\123.45\CHF\\\\\\\\QRR\000000000000000000000000095\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferPmtInfo(Buffer, 'CH5800791123000889012', 'CHF', 123.45, ReferenceType::"QR Reference", '000000000000000000000000095');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_Amt_QRRef_EUR()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, IBAN, EUR amount, QR-reference
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\123.45\EUR\\\\\\\\QRR\000000000000000000000000095\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferPmtInfo(Buffer, 'CH5800791123000889012', 'EUR', 123.45, ReferenceType::"QR Reference", '000000000000000000000000095');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_Amt_CRRef()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, IBAN, amount, Creditor-reference
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\123.45\CHF\\\\\\\\SCOR\RF5112346\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferPmtInfo(Buffer, 'CH5800791123000889012', 'CHF', 123.45, ReferenceType::"Creditor Reference (ISO 11649)", 'RF5112346');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_CreditorInfo_Structured()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, creditor info, structured
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\CR A1\CR A2\CR POST\CR CITY\C1\\\\\\\\\CHF\\\\\\\\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferCreditorInfo(Buffer, AddressType::Structured, 'CR Name', 'CR A1', 'CR A2', 'CR POST', 'CR CITY', 'C1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_CreditorInfo_Combined()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, creditor info, combined
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\K\CR Name\CR A1 CR A2\CR POST CR CITY\\\C1\\\\\\\\\CHF\\\\\\\\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferCreditorInfo(Buffer, AddressType::Combined, 'CR Name', 'CR A1 CR A2', 'CR POST CR CITY', '', '', 'C1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_UCreditorInfo_Structured()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, ultimate creditor info, structured
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\S\UCR Name\UCR A1\UCR A2\UCR POST\UCR CITY\C2\\CHF\\\\\\\\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferUCreditorInfo(Buffer, AddressType::Structured, 'UCR Name', 'UCR A1', 'UCR A2', 'UCR POST', 'UCR CITY', 'C2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_UCreditorInfo_Combined()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, ultimate creditor info, combined
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\S\UCR Name\UCR A1 UCR A2\UCR POST UCR CITY\\\C2\\CHF\\\\\\\\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferUCreditorInfo(Buffer, AddressType::Structured, 'UCR Name', 'UCR A1 UCR A2', 'UCR POST UCR CITY', '', '', 'C2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_DebitorInfo_Structured()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, ultimate debitor info, structured
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\S\UD Name\UD A1\UD A2\UD POST\UD CITY\C3\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferUDebitorInfo(Buffer, AddressType::Structured, 'UD Name', 'UD A1', 'UD A2', 'UD POST', 'UD CITY', 'C3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_DebitorInfo_Combined()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, ultimate debitor info, combined
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\K\UD Name\UD A1 UD A2\UD POST UD CITY\\\C3\NON\\\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferUDebitorInfo(Buffer, AddressType::Combined, 'UD Name', 'UD A1 UD A2', 'UD POST UD CITY', '', '', 'C3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_UnstrMsg()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, unstructured message
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\Unstr Msg\EPD';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyAddInfo(Buffer, 'Unstr Msg', '', '', '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_BillInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, billing info
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD\Bill Info';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyAddInfo(Buffer, '', 'Bill Info', '', '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_AltProc1()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, alternative procedure 1
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD\\Alt Name 1: Alt Value 1';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyAddInfo(Buffer, '', '', 'Alt Name 1', 'Alt Value 1', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_AltProc2()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, alternative procedure 1
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD\\\Alt Name 2: Alt Value 2';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyAddInfo(Buffer, '', '', '', '', 'Alt Name 2', 'Alt Value 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_AllAddInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, alternative procedure 1
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\' +
            '\\\\\\\NON\\Unstr Msg\EPD\Bill Info\Alt Name 1: Alt Value 1\Alt Name 2: Alt Value 2';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyAddInfo(Buffer, 'Unstr Msg', 'Bill Info', 'Alt Name 1', 'Alt Value 1', 'Alt Name 2', 'Alt Value 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Positive_QRPmt_Cred_Deb_AddInfo()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), positive, creditor, debitor, QR-Reference, unstructured message, billing info
        QRCodeString :=
            'SPC\0200\1\CH5800791123000889012\S\CR Name\CR A1\CR A2\CR POST\CR CITY\C1\\\\\\\\123.45\CHF\' +
            'S\UD Name\UD A1\UD A2\UD POST\UD CITY\C3\QRR\000000000000000000000000026\Unstr Msg\EPD\Bill Info';

        DecodeScenario(Buffer, QRCodeString, true, false, 0);

        VerifyBufferPmtInfo(Buffer, 'CH5800791123000889012', 'CHF', 123.45, ReferenceType::"QR Reference", '000000000000000000000000026');
        VerifyBufferCreditorInfo(Buffer, AddressType::Structured, 'CR Name', 'CR A1', 'CR A2', 'CR POST', 'CR CITY', 'C1');
        VerifyBufferUDebitorInfo(Buffer, AddressType::Structured, 'UD Name', 'UD A1', 'UD A2', 'UD POST', 'UD CITY', 'C3');
        VerifyAddInfo(Buffer, 'Unstr Msg', 'Bill Info', '', '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_IBAN_DE()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, IBAN country 'DE...'
        QRCodeString := 'SPC\0200\1\DE5800791123000889012\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_IBAN_Length()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, IBAN not 21 chars length
        QRCodeString := 'SPC\0200\1\CH580079112300088901\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_CRName()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, blanked creditor name
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_WrongCurrency()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, wrong currency
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\ZZZ\\\\\\\\NON\\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_BlankedCurrency()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, blanked currency
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\\\\\\\\\NON\\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_BlankedQRRef()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, blanked QR-reference
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\\\\\\\\\QRR\\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_WrongQRRefLength()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, blanked QR-reference
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\\\\\\\\\QRR\12345\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Decode_Negative_WrongQRRefCheckDigit()
    var
        Buffer: Record "Swiss QR-Bill Buffer" temporary;
        QRCodeString: Text;
    begin
        // [FEATURE] [Parse]
        // [SCENARIO 259169] Codeunit "Swiss QR-Bill Decode".DecodeQRCodeText(), negative, blanked QR-reference
        QRCodeString := 'SPC\0200\1\CH5800791123000889012\S\CR Name\\\\\\\\\\\\\\\\\\\\\\QRR\12345\\EPD';
        DecodeScenario(Buffer, QRCodeString, false, true, 3);
    end;

    local procedure DecodeScenario(var Buffer: Record "Swiss QR-Bill Buffer"; QRCodeString: Text; ExpectedDecode: Boolean; ExpectedErrorLog: Boolean; ExpectedErrorCount: Integer)
    var
        IncomingDocument: Record "Incoming Document";
        Decode: Codeunit "Swiss QR-Bill Decode";
    begin
        MockIncomingDocument(IncomingDocument);
        Decode.SetContextRecordId(IncomingDocument.RecordId());

        QRCodeString := Library.ReplaceBackSlashWithLineBreak(QRCodeString);
        Assert.AreEqual(ExpectedDecode, Decode.DecodeQRCodeText(Buffer, QRCodeString), 'decode result');
        Assert.AreEqual(ExpectedErrorLog, Decode.AnyErrorLogged(), 'any error logged');

        VerifyErrorLogCountByContext(IncomingDocument, ExpectedErrorCount);
    end;

    local procedure MockIncomingDocument(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            "Entry No." := LibraryUtility.GetNewRecNo(IncomingDocument, FieldNo("Entry No."));
            Insert();
        end;
    end;

    local procedure AddBasicInfo(var Buffer: Record "Swiss QR-Bill Buffer"; NewIBAN: Code[50]; NewCurrency: Code[10]; NewAmount: Decimal; NewReferenceType: Enum "Swiss QR-Bill Payment Reference Type"; NewReferenceNo: Code[50])
    begin
        with Buffer do begin
            IBAN := NewIBAN;
            Currency := NewCurrency;
            Amount := NewAmount;
            "Payment Reference Type" := NewReferenceType;
            "Payment Reference" := NewReferenceNo;
        end;
    end;

    local procedure AddAddInfo(var Buffer: Record "Swiss QR-Bill Buffer"; UnstrMsg: Text[140]; BillInfo: Text[140]; AltName1: Text[10]; AltValue1: Text[100]; AltName2: Text[10]; AltValue2: Text[100])
    begin
        with Buffer do begin
            "Unstructured Message" := UnstrMsg;
            "Billing Information" := BillInfo;
            "Alt. Procedure Name 1" := AltName1;
            "Alt. Procedure Value 1" := AltValue1;
            "Alt. Procedure Name 2" := AltName2;
            "Alt. Procedure Value 2" := AltValue2;
        end;
    end;

    local procedure AddCreditorInfo(var Buffer: Record "Swiss QR-Bill Buffer"; AddressType: Enum "Swiss QR-Bill Address Type")
    begin
        with Buffer do begin
            "Creditor Address Type" := AddressType;
            "Creditor Name" := 'CR Name';
            "Creditor Street Or AddrLine1" := 'CR A1';
            "Creditor BuildNo Or AddrLine2" := 'CR A2';
            "Creditor Postal Code" := 'CR POST';
            "Creditor City" := 'CR CITY';
            "Creditor Country" := 'C1';
        end;
    end;

    local procedure AddUCreditorInfo(var Buffer: Record "Swiss QR-Bill Buffer"; AddressType: Enum "Swiss QR-Bill Address Type")
    begin
        with Buffer do begin
            "UCreditor Address Type" := AddressType;
            "UCreditor Name" := 'UCR Name';
            "UCreditor Street Or AddrLine1" := 'UCR A1';
            "UCreditor BuildNo Or AddrLine2" := 'UCR A2';
            "UCreditor Postal Code" := 'UCR POST';
            "UCreditor City" := 'UCR CITY';
            "UCreditor Country" := 'C2';
        end;
    end;

    local procedure AddDebitorInfo(var Buffer: Record "Swiss QR-Bill Buffer"; AddressType: Enum "Swiss QR-Bill Address Type")
    begin
        with Buffer do begin
            "UDebtor Address Type" := AddressType;
            "UDebtor Name" := 'UD Name';
            "UDebtor Street Or AddrLine1" := 'UD A1';
            "UDebtor BuildNo Or AddrLine2" := 'UD A2';
            "UDebtor Postal Code" := 'UD POST';
            "UDebtor City" := 'UD CITY';
            "UDebtor Country" := 'C3';
        end;
    end;

    local procedure UpdateLastReferenceNo(NewValue: BigInteger)
    var
        QRBillSetup: Record "Swiss QR-Bill Setup";
    begin
        with QRBillSetup do begin
            Get();
            Validate("Last Used Reference No.", NewValue);
            Modify();
        end;
    end;

    local procedure ClearErrorLogByContext(Context: Variant)
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(Context);
        ErrorMessage.ClearLog();
    end;

    local procedure VerifyErrorLogCountByContext(Context: Variant; ExpectedCount: Integer)
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(Context);
        Assert.RecordCount(ErrorMessage, ExpectedCount);
        ClearErrorLogByContext(Context);
    end;

    local procedure VerifyLastReferenceNo(ExpectedValue: BigInteger)
    var
        QRBillSetup: Record "Swiss QR-Bill Setup";
    begin
        with QRBillSetup do begin
            Get();
            Assert.AreEqual(ExpectedValue, "Last Used Reference No.", '');
            Modify();
        end;
    end;

    local procedure VerifyBufferPmtInfo(Buffer: Record "Swiss QR-Bill Buffer"; ExpIBAN: Code[50]; ExpCurrency: Code[10]; ExpAmount: Decimal; ExpPmtRefType: Enum "Swiss QR-Bill Payment Reference Type"; ExpPmtRef: Code[50])
    begin
        with Buffer do begin
            TestField(IBAN, ExpIBAN);
            TestField(Currency, ExpCurrency);
            TestField(Amount, ExpAmount);
            TestField("Payment Reference Type", ExpPmtRefType);
            TestField("Payment Reference", ExpPmtRef);
        end;
    end;

    local procedure VerifyBufferCreditorInfo(Buffer: Record "Swiss QR-Bill Buffer"; ExpAddressType: Enum "Swiss QR-Bill Address Type"; ExpName: Text[70]; ExpAddr1: Text[70]; ExpAddr2: Text[70]; ExpPostal: Text[30]; ExpCity: Text[30]; ExpCountry: Code[2])
    begin
        with Buffer do begin
            TestField("Creditor Address Type", ExpAddressType);
            TestField("Creditor Name", ExpName);
            TestField("Creditor Street Or AddrLine1", ExpAddr1);
            TestField("Creditor BuildNo Or AddrLine2", ExpAddr2);
            TestField("Creditor Postal Code", ExpPostal);
            TestField("Creditor City", ExpCity);
            TestField("Creditor Country", ExpCountry);
        end;
    end;

    local procedure VerifyBufferUCreditorInfo(Buffer: Record "Swiss QR-Bill Buffer"; ExpAddressType: Enum "Swiss QR-Bill Address Type"; ExpName: Text[70]; ExpAddr1: Text[70]; ExpAddr2: Text[70]; ExpPostal: Text[30]; ExpCity: Text[30]; ExpCountry: Code[2])
    begin
        with Buffer do begin
            TestField("UCreditor Address Type", ExpAddressType);
            TestField("UCreditor Name", ExpName);
            TestField("UCreditor Street Or AddrLine1", ExpAddr1);
            TestField("UCreditor BuildNo Or AddrLine2", ExpAddr2);
            TestField("UCreditor Postal Code", ExpPostal);
            TestField("UCreditor City", ExpCity);
            TestField("UCreditor Country", ExpCountry);
        end;
    end;

    local procedure VerifyBufferUDebitorInfo(Buffer: Record "Swiss QR-Bill Buffer"; ExpAddressType: Enum "Swiss QR-Bill Address Type"; ExpName: Text[70]; ExpAddr1: Text[70]; ExpAddr2: Text[70]; ExpPostal: Text[30]; ExpCity: Text[30]; ExpCountry: Code[2])
    begin
        with Buffer do begin
            TestField("UDebtor Address Type", ExpAddressType);
            TestField("UDebtor Name", ExpName);
            TestField("UDebtor Street Or AddrLine1", ExpAddr1);
            TestField("UDebtor BuildNo Or AddrLine2", ExpAddr2);
            TestField("UDebtor Postal Code", ExpPostal);
            TestField("UDebtor City", ExpCity);
            TestField("UDebtor Country", ExpCountry);
        end;
    end;

    local procedure VerifyAddInfo(Buffer: Record "Swiss QR-Bill Buffer"; ExpUnstr: Text[140]; ExpBillInfo: Text[140]; ExpAltName1: Text[10]; ExpAltValue1: Text[100]; ExpAltName2: Text[10]; ExpAltValue2: Text[100])
    begin
        with Buffer do begin
            TestField("Unstructured Message", ExpUnstr);
            TestField("Billing Information", ExpBillInfo);
            TestField("Alt. Procedure Name 1", ExpAltName1);
            TestField("Alt. Procedure Value 1", ExpAltValue1);
            TestField("Alt. Procedure Name 2", ExpAltName2);
            TestField("Alt. Procedure Value 2", ExpAltValue2);
        end;
    end;
}
