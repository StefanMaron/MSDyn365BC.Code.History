codeunit 17352 "Person\Vendor Update"
{
    Permissions = TableData Vendor = rimd;

    trigger OnRun()
    begin
    end;

    var
        Vendor: Record Vendor;
        HRSetup: Record "Human Resources Setup";

    [Scope('OnPrem')]
    procedure PersonToVendor(OldPerson: Record Person; Person: Record Person)
    begin
        if (Person."Vendor No." <> '') and
           ((OldPerson."Vendor No." <> Person."Vendor No.") or
            (OldPerson."First Name" <> Person."First Name") or
            (OldPerson."Middle Name" <> Person."Middle Name") or
            (OldPerson."Last Name" <> Person."Last Name"))
        then
            VendorUpdate(Person)
        else
            exit;
    end;

    [Scope('OnPrem')]
    procedure VendorUpdate(Person: Record Person)
    begin
        Vendor.Get(Person."Vendor No.");
        Vendor.Name := CopyStr(Person."Full Name", 1, MaxStrLen(Vendor.Name));
        Vendor.Modify
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Person: Record Person)
    var
        NewVendor: Record Vendor;
    begin
        HRSetup.Get();
        HRSetup.TestField("Person Vendor No. Series");

        Person.TestField("Vendor No.", '');

        NewVendor.Init();
        NewVendor."No. Series" := HRSetup."Person Vendor No. Series";
        NewVendor.Insert(true);
        NewVendor.Name := CopyStr(Person."Full Name", 1, MaxStrLen(NewVendor.Name));
        NewVendor."Vendor Type" := NewVendor."Vendor Type"::Person;
        NewVendor."Vendor Posting Group" := HRSetup."Person Vendor Posting Group";
        NewVendor."Gen. Bus. Posting Group" := HRSetup."Pers. Vend.Gen.Bus. Posting Gr";
        NewVendor."VAT Bus. Posting Group" := HRSetup."Pers. Vend.VAT Bus. Posting Gr";
        NewVendor."VAT Registration No." := Person."VAT Registration No.";
        NewVendor.Modify();

        Person."Vendor No." := NewVendor."No.";
        Person.Modify();
    end;
}

