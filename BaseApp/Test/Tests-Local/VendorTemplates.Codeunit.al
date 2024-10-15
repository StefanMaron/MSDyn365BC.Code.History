codeunit 145012 "Vendor Templates"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatingVendorFromContactWithVendorTemplate()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Vendor: Record Vendor;
        VendorTemplate: Record "Vendor Template";
    begin
        // 1. Setup
        Initialize;

        CreateVendorTemplate(VendorTemplate);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise
        Contact.CreateVendor(VendorTemplate.Code);

        // 3. Verify
        ContactBusinessRelation.SetRange(
          "Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.FindFirst;

        Vendor.Get(ContactBusinessRelation."No.");

        Vendor.TestField("Gen. Bus. Posting Group", VendorTemplate."Gen. Bus. Posting Group");
        Vendor.TestField("VAT Bus. Posting Group", VendorTemplate."VAT Bus. Posting Group");
        Vendor.TestField("Vendor Posting Group", VendorTemplate."Vendor Posting Group");
        Vendor.TestField("Payment Method Code", VendorTemplate."Payment Method Code");
        Vendor.TestField("No. Series", VendorTemplate."No. Series");
    end;

    local procedure CreateVendorTemplate(var VendorTemplate: Record "Vendor Template")
    var
        CountryRegion: Record "Country/Region";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        PaymentMethod: Record "Payment Method";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.FindCountryRegion(CountryRegion);
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryPurchase.CreateVendorTemplate(VendorTemplate);
        VendorTemplate.Validate("Country/Region Code", CountryRegion.Code);
        VendorTemplate.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        VendorTemplate.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        VendorTemplate.Validate("Vendor Posting Group", LibraryPurchase.FindVendorPostingGroup);
        VendorTemplate.Validate("Payment Method Code", PaymentMethod.Code);
        VendorTemplate.Validate("No. Series", LibraryERM.CreateNoSeriesCode);
        VendorTemplate.Modify();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler
    end;
}

