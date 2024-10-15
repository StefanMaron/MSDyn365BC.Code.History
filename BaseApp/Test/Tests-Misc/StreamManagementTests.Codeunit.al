codeunit 132592 "Stream Management Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Mtom] [XML] [Stream] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestMtomStreamToXmlStream()
    var
        TempBlob: Codeunit "Temp Blob";
        StreamManagement: Codeunit "Stream Management";
        TypeHelper: Codeunit "Type Helper";
        MtomInStream: InStream;
        XmlInStream: InStream;
        MtomOutStream: OutStream;
        XmlDocumentResponse: DotNet XmlDocument;
        MtomString: Text;
        Result: Text;
        Content: Text;
        StreamContent: Text;
    begin
        // [SCENARIO] Unit test of function MtomStreamToXmlStream - convert Mtom to XML

        // [GIVEN] An XML document
        Content := '<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">';
        Content += '<env:Header />';
        Content += '<env:Body>';
        Content += '<ns2:test xmlns:ns2="https://ns2" />';
        Content += '</env:Body>';
        Content += '</env:Envelope>';

        // [GIVEN] An Mtom String embedding the xml document
        MtomString := '------=_Part_170043_1574782596.1513784534431' + TypeHelper.NewLine();
        MtomString += 'Content-Type: application/xop+xml; charset=utf-8; type="application/soap+xml"' + TypeHelper.NewLine();
        MtomString += '' + TypeHelper.NewLine();
        MtomString += Content + TypeHelper.NewLine();
        MtomString += '------=_Part_170043_1574782596.1513784534431--';

        // [WHEN] The Mtom String is processed by the MtomStreamToXmlStream function
        TempBlob.CreateOutStream(MtomOutStream);
        MtomOutStream.WriteText(MtomString);
        TempBlob.CreateInStream(MtomInStream);
        StreamManagement.MtomStreamToXmlStream(MtomInStream, XmlInStream, 'Multipart/Related; boundary="----=_Part_170043_1574782596.1513784534431"; type="application/xop+xml"; start-info="application/soap+xml"');

        // [THEN] The XML document is returned
        XmlDocumentResponse := XmlDocumentResponse.XmlDocument();
        XmlDocumentResponse.PreserveWhitespace := true;
        XmlInStream.ReadText(StreamContent);
        XmlDocumentResponse.LoadXml(StreamContent);
        Result := XmlDocumentResponse.InnerXml;
        Assert.AreEqual(Content, Result, 'XmlStreamUtils.MtomStreamToXmlStream returned the wrong value');
    end;
}

