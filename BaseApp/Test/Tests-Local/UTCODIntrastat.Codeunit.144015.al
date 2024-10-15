codeunit 144015 "UT COD Intrastat"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConvertPhoneNumberWithoutCodeLocalFunctionalityMgt()
    begin
        // Purpose of the test is to validate ConvertPhoneNumber function of Codeunit ID -11400 Local Functionality Mgt.

        // Using blank for Phone Number Code, Blank space '-' to delete characters from Phone Number, 2 to copy from second digit of Phone Number on the basis of ConvertPhoneNumber function of Codeunit ID -11400 Local Functionality Mgt.
        ConvertPhoneNumberLocalFunctionalityMgt('', '-', 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConvertPhoneNumberWithCodeLocalFunctionalityMgt()
    begin
        // Purpose of the test is to validate ConvertPhoneNumber function of CodeUnit ID -11400 Local Functionality Mgt.

        // Using '0031' for Phone Number Code, Blank space and Zero '-,0' to delete characters from Phone Number, 5 to copy from second digit of Phone Number on the basis of ConvertPhoneNumber function of Codeunit ID -11400 Local Functionality Mgt.
        ConvertPhoneNumberLocalFunctionalityMgt('0031', '-,0', 5);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConvertPhoneNumberWithCodeIncludesZeroLocalFunctionalityMgt()
    begin
        // Purpose of the test is to validate ConvertPhoneNumber function of CodeUnit ID -11400 Local Functionality Mgt.

        // Using '+310' for Phone Number Code, Blank space '-' to delete characters from Phone Number, 5 to copy from second digit of Phone Number on the basis of ConvertPhoneNumber function of Codeunit ID -11400 Local Functionality Mgt.
        ConvertPhoneNumberLocalFunctionalityMgt('+310', '-', 5);
    end;

    local procedure ConvertPhoneNumberLocalFunctionalityMgt(RequiredStartingNumber: Text[4]; DeleteCharacter: Text[3]; CopyFrom: Integer)
    var
        CompanyInformation: Record "Company Information";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        PhoneNo: Text[20];
    begin
        // Setup.
        CompanyInformation.Get;

        // RequiredStartingNumber is of character length - 4 and DeleteCharacter is of character length - 3. Calculation is on the basis of ConvertPhoneNumber function Codeunit ID -11400 Local Functionality Mgt.
        PhoneNo := RequiredStartingNumber + DelChr(CompanyInformation."Phone No.", '=', DeleteCharacter);

        // Exercise & Verify:
        Assert.AreEqual('+31' + CopyStr(PhoneNo, CopyFrom), LocalFunctionalityMgt.ConvertPhoneNumber(PhoneNo), 'Value must be equal.');
    end;
}

