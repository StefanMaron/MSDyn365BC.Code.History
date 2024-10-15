codeunit 144061 "Test ESR Localized Features"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCH: Codeunit "Library - CH";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestIBANAndBankAccountFieldActivation()
    var
        VendorBankAccountCard: TestPage "Vendor Bank Account Card";
    begin
        Init;
        VendorBankAccountCard.OpenNew;
        VendorBankAccountCard.Code.SetValue('POST');
        VendorBankAccountCard."Payment Form".SetValue('Post Payment Domestic');
        VendorBankAccountCard."Giro Account No.".SetValue('60-010083-3');

        // If the bank account is set the IBAN field should not be editable.
        VendorBankAccountCard."Bank Account No.".SetValue('012-345678.009');
        Assert.IsFalse(VendorBankAccountCard.IBAN.Enabled, 'The IBAN field should be disabled when the bank account is set');

        // If the bank account is not set the IBAN field should be editable.
        VendorBankAccountCard."Bank Account No.".SetValue('');
        Assert.IsTrue(VendorBankAccountCard.IBAN.Enabled,
          'The IBAN field should be enabled when the bank account is not set');

        // If the IBAN field is set the bank account should be disabled.
        VendorBankAccountCard.IBAN.SetValue('CH5604835012345678009');
        Assert.IsFalse(VendorBankAccountCard."Bank Account No.".Enabled,
          'The Bank account No. field should be disabled when the IBAN field is set');

        // If the IBAN field is not set the bank account should be enabled.
        VendorBankAccountCard.IBAN.SetValue('');
        Assert.IsTrue(VendorBankAccountCard."Bank Account No.".Enabled,
          'The Bank account No. field should be enabled when the IBAN field is not set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateFromESRFromBankCodeIsNotAllowed()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Init;

        // Setup PostingSetup and VAT PostingSetup.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Create a new vendor
        LibraryCH.CreateVendor(Vendor, GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CreateVendorBankAccounts(Vendor."No.");

        // Open the new purchase orders page
        PurchaseOrder.OpenNew;
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        PurchaseOrder."Posting Date".SetValue(WorkDate);
        PurchaseOrder."Vendor Invoice No.".SetValue(Format(LibraryRandom.RandIntInRange(11111, 99999)));

        PurchaseOrder."ESR/ISR Coding Line".SetValue('0100000400689>331459012023430000000000001+010033140>');

        // We should get ESR and ESR Amount 400.68
        PurchaseOrder."Bank Code".AssertEquals('ESR');
        Assert.IsTrue(PurchaseOrder."ESR Amount".AsDEcimal = 400.68, 'Wrong value for the ESR Amount Field');

        // Now try to change ESR to Bank
        asserterror PurchaseOrder."Bank Code".SetValue('BANK');

        // We should get the expected error message containing the words ESR and ESR+ and the vendor no.
        Assert.IsTrue(
          (StrPos(GetLastErrorText, 'ESR') > 0) and
          (StrPos(GetLastErrorText, 'ESR+') > 0) and
          (StrPos(GetLastErrorText, Vendor."No.") > 0), 'Unexpected error message');
    end;

    local procedure Init()
    begin
        LibraryVariableStorage.Clear;

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        IsInitialized := true;
    end;

    [Normal]
    local procedure CreateVendorBankAccounts(VendorNumber: Code[20])
    var
        VendorBankAccount1: Record "Vendor Bank Account";
        VendorBankAccount2: Record "Vendor Bank Account";
    begin
        with VendorBankAccount1 do begin
            Validate("Vendor No.", VendorNumber);
            Validate(Code, 'BANK');
            Validate("Payment Form", "Payment Form"::"Bank Payment Domestic");
            Insert(true);
        end;

        with VendorBankAccount2 do begin
            Validate("Vendor No.", VendorNumber);
            Validate(Code, 'ESR');
            Validate("ESR Type", "ESR Type"::"9/27");
            Validate("Payment Form", "Payment Form"::ESR);
            Validate("ESR Account No.", '01-003314-0');
            Insert(true);
        end;
    end;
}

