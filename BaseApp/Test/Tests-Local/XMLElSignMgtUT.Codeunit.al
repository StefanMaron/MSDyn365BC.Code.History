codeunit 145018 "XML El. Sign Mgt. UT"
{
    // // [FEATURE] [Cryptography] [UT]

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCertificateCZ: Codeunit "Library - Certificate CZ";
        IsInitialized: Boolean;
        SignatureNotValidErr: Label 'Signature is not valid.';

    [Test]
    [Scope('OnPrem')]
    procedure SignXMLDocumentWithoutReference()
    begin
        // [SCENARIO] Sign XML document without reference
        SignXMLDocument(GetRootElementURI);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SignXMLDocumentWithReference()
    begin
        // [SCENARIO] Sign XML document with reference
        SignXMLDocument(GetElement1URI);
    end;

    [Scope('OnPrem')]
    procedure SignXMLDocument(URI: Text)
    var
        XMLElectronicSignManagement: Codeunit "XML Electronic Sign Management";
        XmlDoc: DotNet XmlDocument;
        Signature: DotNet XmlElement;
        "Key": DotNet AsymmetricAlgorithm;
        ReferenceIndex: Integer;
    begin
        Initialize;

        // [GIVEN] Get test private key
        LibraryCertificateCZ.GetCertificatePrivateKey(Key);

        // [GIVEN] Generate test xml document
        GenerateXMLDocument(XmlDoc);

        // [GIVEN] Setup XML Electronic Sign Management
        ReferenceIndex := XMLElectronicSignManagement.AddReference(URI, '');
        XMLElectronicSignManagement.AddReferenceTransformWithInclusiveNamespacesPrefixList(
          ReferenceIndex, 'XmlDsigEnvelopedSignatureTransform', '');

        // [WHEN] Get signature
        XMLElectronicSignManagement.GetSignature(XmlDoc, Key, Signature);

        // [THEN] Signature is valid
        Assert.AreEqual(GetSignature(URI), Signature.InnerText, SignatureNotValidErr);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit;
    end;

    local procedure GenerateXMLDocument(var XmlDoc: DotNet XmlDocument)
    begin
        XmlDoc := XmlDoc.XmlDocument;
        XmlDoc.PreserveWhitespace(true);
        XmlDoc.LoadXml(
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<RootElement xmlns="namespaceURI">' +
          '<SelfClosingElement attribute="attributeValue" />' +
          '  <Element1 id="element1">' +
          '    <Element11 attribute="" Attribute2="test">' +
          '      <Element111 attribute="" Attribute2="test" />' +
          '      <Element112>Value</Element112>' +
          '    </Element11>' +
          '  </Element1>' +
          '</RootElement>');
    end;

    local procedure GetSignature(URI: Text): Text
    begin
        case URI of
            GetElement1URI:
                exit(GetElement1Signature);
            GetRootElementURI:
                exit(GetRootElementSignature);
        end;
    end;

    local procedure GetElement1URI(): Text
    begin
        exit('element1');
    end;

    local procedure GetRootElementURI(): Text
    begin
        exit('');
    end;

    local procedure GetElement1Signature(): Text
    begin
        exit(
          '78KgVAv1N6A5JkudtYwvaJrUuWuVOT7QW/oYNBTRp5A=X5kNBu' +
          'zXuhmhfPkX+wmP8WCOrCM2l+OJpLyIFY5QKZufOQHMD3RTUa9E' +
          'nSFFxjMYauPZYQJW6Duv21GeGBNRdQ+YJSvfehfE76r+h1UTSR' +
          'cAtZmnPbJMf56Bq9fcmIes/Kx3xdQgG3yjhJmX7J++E1B3l/7M' +
          'Bgx6NEWYKBmeeOkug1TtYfJSOamA30Oj8NbdaJ2z8ZpGfpxasD' +
          'Vywsa76yQW39izlX5AQFJl4yD0yW5SGwO8gS9TfcF+tXnTj4ub' +
          'Lh9IYs34T8bQCgfuu3atVZig8jJFeK0qcMSALceXejjcL+FV7y' +
          '7FRLu/qkDkicd1Ev/bhnDwtda8ou4FoSmmJg==');
    end;

    local procedure GetRootElementSignature(): Text
    begin
        exit(
          'CrEXm8CjhJr9WkB4w5TiEdaxr+0TRsPzqNU1auYnGQQ=VEIzjm' +
          '91Bsf2FKsTqSD1Du1wrkzJY0vY9sP6/Lk9W3/ZXdQEwMkCiWcz' +
          'NjYDJYCH2l5r+IK9GcJk/MMNmebHA5U0Btrr0JnEz5xWr+T1XF' +
          'LsrH6cjHPBDo42ER+c9+O+Ue4z3X6mgKERRlNbv/V2GvDODrn0' +
          'WyzFONRUSaa/THCtRCfWB4rSO051X296bv1sDYAdj+e7bnczvw' +
          'AckjK3/WB4b9oQep/b2e36/LNT14+AGg9iU8zi+KnOZdRA86O0' +
          '8Fw0mWn8fb995V6OQ+IlQjh+WUtOns5MCSsEOFdL++GU7pqIfM' +
          '9g9bdycdoEWT0VdHaipy22oqdsXrIcowS2Cg==');
    end;
}

