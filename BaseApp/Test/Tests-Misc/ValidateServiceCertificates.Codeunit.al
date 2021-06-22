codeunit 134295 "Validate Service Certificates"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service Certificate]
    end;

    var
        AddressIsReachableErr: Label 'The address %1 was possible to connect to without a certificate validation error.', Comment = 'The address https://www.example.com/ was possible to connect to without a certificate validation error.';
        AddressNotReachableErr: Label 'The address %1 was not possible to connect to.', Comment = 'The address https://www.example.com/ was not possible to connect to.';
        CertificateValidationErr: Label 'The remote certificate is invalid according to the validation procedure.';
        ExpiredCertificateAddressTxt: Label 'https://expired.badssl.com/', Locked = true;
        PinningTestAddressTxt: Label 'https://pinning-test.badssl.com/', Locked = true;
        RevokedCertificateAddressTxt: Label 'https://revoked.badssl.com/', Locked = true;
        SelfSignedCertificateAddressTxt: Label 'https://self-signed.badssl.com/', Locked = true;
        UntrustedRootAddressTxt: Label 'https://untrusted-root.badssl.com/', Locked = true;
        WrongHostAddressTxt: Label 'https://wrong.host.badssl.com/', Locked = true;
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure ExpiredCertificateAddress()
    var
        OutputError: Text;
        Result: Boolean;
    begin
        // Exercise
        Result := FailToConnect(ExpiredCertificateAddressTxt, OutputError);

        // Verify
        AssertCertificateValidationFails(ExpiredCertificateAddressTxt, Result, OutputError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PinningTestAddress()
    var
        Result: Boolean;
    begin
        // Exercise
        Result := TryConnect(PinningTestAddressTxt);

        // Verify
        Assert.IsTrue(Result, AddressNotReachableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevokedCertificateAddress()
    var
        OutputError: Text;
        Result: Boolean;
    begin
        // Exercise
        Result := FailToConnect(RevokedCertificateAddressTxt, OutputError);

        // Verify
        AssertCertificateValidationFails(RevokedCertificateAddressTxt, Result, OutputError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelfSignedCertificateAddress()
    var
        OutputError: Text;
        Result: Boolean;
    begin
        // Exercise
        Result := FailToConnect(SelfSignedCertificateAddressTxt, OutputError);

        // Verify
        AssertCertificateValidationFails(SelfSignedCertificateAddressTxt, Result, OutputError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UntrustedRootAddress()
    var
        OutputError: Text;
        Result: Boolean;
    begin
        // Exercise
        Result := FailToConnect(UntrustedRootAddressTxt, OutputError);

        // Verify
        AssertCertificateValidationFails(UntrustedRootAddressTxt, Result, OutputError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WrongHostAddress()
    var
        OutputError: Text;
        Result: Boolean;
    begin
        // Exercise
        Result := FailToConnect(WrongHostAddressTxt, OutputError);

        // Verify
        AssertCertificateValidationFails(WrongHostAddressTxt, Result, OutputError);
    end;

    local procedure FailToConnect(InputUri: Text; var OutputError: Text) Result: Boolean
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
    begin
        Result := TryConnect(InputUri);
        DotNetExceptionHandler.Collect;
        OutputError := StrSubstNo('Failed to reach %1 due to error: %2', InputUri, DotNetExceptionHandler.GetMessage);
    end;

    [TryFunction]
    local procedure TryConnect(InputUri: Text)
    var
        HttpWebRequest: DotNet HttpWebRequest;
        HttpWebResponse: DotNet HttpWebResponse;
        Uri: DotNet Uri;
    begin
        Uri := Uri.Uri(InputUri);
        HttpWebRequest := HttpWebRequest.CreateHttp(Uri);
        HttpWebResponse := HttpWebRequest.GetResponse;
    end;

    local procedure AssertCertificateValidationFails(Address: Text; ConnectionResult: Boolean; OutputError: Text)
    begin
        Assert.IsFalse(ConnectionResult, StrSubstNo(AddressIsReachableErr, Address));
        Assert.ExpectedMessage(CertificateValidationErr, OutputError);
    end;
}

