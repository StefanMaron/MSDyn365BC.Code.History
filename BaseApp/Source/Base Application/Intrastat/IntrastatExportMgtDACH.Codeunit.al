#if not CLEAN22
codeunit 11002 "Intrastat - Export Mgt. DACH"
{

    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moving to Intrastat extension.';

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
        XMLDOMMgt: Codeunit "XML DOM Management";
        RegNoExcludeCharsTxt: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/-.+', Comment = 'Locked. Do not translate.';
        ExportTypeGlb: Option Receipt,Shipment;
        VATIDNo: Text;
        StartDate: Date;
        MessageID: Text;
        CreationDate: Date;
        CreationTime: Time;
        TestIndicator: Boolean;

    [Scope('OnPrem')]
    procedure Initialize(CreationDateTime: DateTime)
    begin
        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.");
        CompanyInformation.TestField(Area);
        CompanyInformation.TestField("Agency No.");
        CompanyInformation.TestField("Company No.");
        CompanyInformation.TestField(Address);
        CompanyInformation.TestField("Post Code");
        CompanyInformation.TestField(City);
        CompanyInformation.TestField("Country/Region Code");
        IntrastatSetup.Get();
        IntrastatSetup.TestField("Intrastat Contact Type");
        CheckIntrastatContactMandatoryFields();

        VATIDNo :=
          Format(CompanyInformation.Area, 2) +
          PadStr(CopyStr(DelChr(UpperCase(CompanyInformation."Registration No."), '=', RegNoExcludeCharsTxt), 1, 11), 11, '0') +
          Format(CompanyInformation."Agency No.", 3);

        CreationDate := DT2Date(CreationDateTime);
        CreationTime := DT2Time(CreationDateTime);
    end;

    procedure GetXMLFileName(): Text
    begin
        exit(MessageID + '.XML');
    end;

    [Scope('OnPrem')]
    procedure WriteXMLHeader(var XMLDocument: DotNet XmlDocument; var XMLNode: DotNet XmlNode; NewTestIndicator: Boolean; NewStartDate: Date)
    var
        XMLNode2: DotNet XmlNode;
    begin
        StartDate := NewStartDate;
        TestIndicator := NewTestIndicator;
        Clear(XMLDocument);

        XMLDocument := XMLDocument.XmlDocument();
        XMLDOMMgt.AddRootElement(XMLDocument, 'INSTAT', XMLNode);
        XMLDOMMgt.AddAttributeWithPrefix(
          XMLNode, 'noNamespaceSchemaLocation', 'xsi', 'http://www.w3.org/2001/XMLSchema-instance', 'instat62.xsd');
        XMLDOMMgt.AddDeclaration(XMLDocument, '1.0', 'ISO-8859-1', 'yes');
        XMLDOMMgt.AddElement(XMLNode, 'Envelope', '', '', XMLNode);
        MessageID := GetMessageID(StartDate);
        XMLDOMMgt.AddElement(XMLNode, 'envelopeId', MessageID, '', XMLNode2);
        WriteXMLDateTime(XMLNode);
        WriteXMLPartySender(XMLNode);
        WriteXMLPartyReceiver(XMLNode);
        if TestIndicator then
            XMLDOMMgt.AddElement(XMLNode, 'testIndicator', 'true', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode, 'softwareUsed', PRODUCTNAME.Full(), '', XMLNode2);
    end;

    [Scope('OnPrem')]
    procedure WriteXMLDeclaration(RootXMLNode: DotNet XmlNode; var DeclarationXMLNode: DotNet XmlNode; ExportType: Option; CurrencyCode: Code[10])
    var
        XMLNode2: DotNet XmlNode;
        FlowCode: Text;
    begin
        FlowCode := GetFlowCode(ExportType);
        XMLDOMMgt.AddElement(RootXMLNode, 'Declaration', '', '', DeclarationXMLNode);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'declarationId', MessageID, '', XMLNode2);
        WriteXMLDateTime(DeclarationXMLNode);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'referencePeriod', Format(StartDate, 0, '<Year4>-<Month,2>'), '', XMLNode2);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'PSIId', VATIDNo, '', XMLNode2);
        WriteXMLFunction(DeclarationXMLNode);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'flowCode', FlowCode, '', XMLNode2);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'currencyCode', CurrencyCode, '', XMLNode2);
    end;

    [Scope('OnPrem')]
    procedure WriteXMLDeclarationTotals(DeclarationXMLNode: DotNet XmlNode; IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'totalNetMass', FormatDecimal(IntrastatJnlLine."Total Weight"), '', XMLNode);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'totalInvoicedAmount', FormatDecimal(IntrastatJnlLine.Amount), '', XMLNode);
        XMLDOMMgt.AddElement(DeclarationXMLNode, 'totalStatisticalValue', FormatDecimal(IntrastatJnlLine."Statistical Value"), '', XMLNode);
    end;

    [Scope('OnPrem')]
    procedure WriteXMLItem(IntrastatJnlLine: Record "Intrastat Jnl. Line"; XMLNode: DotNet XmlNode)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
        CountryOfOriginCode: Code[10];
    begin
        XMLDOMMgt.AddElement(XMLNode, 'Item', '', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode2, 'itemNumber', IntrastatJnlLine."Internal Ref. No.", '', XMLNode3);
        WriteXMLCN8(XMLNode2, Format(DelChr(IntrastatJnlLine."Tariff No."), 8));
        XMLDOMMgt.AddElement(XMLNode2, 'goodsDescription', IntrastatJnlLine."Item Description", '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'MSConsDestCode', GetCountryCode(IntrastatJnlLine."Country/Region Code"), '', XMLNode3);

        if (IntrastatJnlLine.Type = IntrastatJnlLine.Type::Receipt) or (IntrastatJnlLine."Country/Region of Origin Code" <> '') then
            CountryOfOriginCode := GetOriginCountryCode(IntrastatJnlLine."Country/Region of Origin Code");
        XMLDOMMgt.AddElement(XMLNode2, 'countryOfOriginCode', CountryOfOriginCode, '', XMLNode3);

        XMLDOMMgt.AddElement(XMLNode2, 'netMass', FormatDecimal(IntrastatJnlLine."Total Weight"), '', XMLNode3);
        if IntrastatJnlLine."Supplementary Units" then
            XMLDOMMgt.AddElement(XMLNode2, 'quantityInSU', FormatDecimal(IntrastatJnlLine.Quantity), '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'invoicedAmount', FormatDecimal(IntrastatJnlLine.Amount), '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'statisticalValue', FormatDecimal(IntrastatJnlLine."Statistical Value"), '', XMLNode3);
        if IntrastatJnlLine."Document No." <> '' then
            XMLDOMMgt.AddElement(XMLNode2, 'invoiceNumber', IntrastatJnlLine."Document No.", '', XMLNode3);
        if IntrastatJnlLine."Partner VAT ID" <> '' then
            XMLDOMMgt.AddElement(XMLNode2, 'partnerId', IntrastatJnlLine."Partner VAT ID", '', XMLNode3);
        WriteXMLNatureOfTransaction(XMLNode2, IntrastatJnlLine."Transaction Type");
        XMLDOMMgt.AddElement(XMLNode2, 'modeOfTransportCode', IntrastatJnlLine."Transport Method", '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'regionCode', IntrastatJnlLine."Area", '', XMLNode3);
    end;

    local procedure WriteXMLPartySender(XMLNode: DotNet XmlNode)
    begin
        WriteXMLParty(
              XMLNode, 'PSI', 'sender', VATIDNo, CompanyInformation.Name, GetMaterialNumber(),
              CompanyInformation.Address, CompanyInformation."Post Code", CompanyInformation.City, GetCountryName(CompanyInformation."Country/Region Code"), CompanyInformation."Phone No.", CompanyInformation."Fax No.", CompanyInformation."E-Mail");
    end;

    local procedure WriteXMLPartyReceiver(XMLNode: DotNet XmlNode)
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
    begin
        case IntrastatSetup."Intrastat Contact Type" of
            IntrastatSetup."Intrastat Contact Type"::Contact:
                begin
                    Contact.Get(IntrastatSetup."Intrastat Contact No.");
                    WriteXMLParty(
                          XMLNode, 'CC', 'receiver', '00', Contact.Name, '',
                          Contact.Address, Contact."Post Code", Contact.City, GetCountryName(Contact."Country/Region Code"), Contact."Phone No.", Contact."Fax No.", Contact."E-Mail");
                end;
            IntrastatSetup."Intrastat Contact Type"::Vendor:
                begin
                    Vendor.Get(IntrastatSetup."Intrastat Contact No.");
                    WriteXMLParty(
                          XMLNode, 'CC', 'receiver', '00', Vendor.Name, '',
                          Vendor.Address, Vendor."Post Code", Vendor.City, GetCountryName(Vendor."Country/Region Code"), Vendor."Phone No.", Vendor."Fax No.", Vendor."E-Mail");
                end;
        end;
    end;

    local procedure WriteXMLDateTime(XMLNode: DotNet XmlNode)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, 'DateTime', '', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode2, 'date', Format(CreationDate, 0, '<Year4>-<Month,2>-<Day,2>'), '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'time', Format(CreationTime, 0, '<Hours2>:<Minutes>:<Seconds>'), '', XMLNode3);
    end;

    local procedure WriteXMLParty(XMLNode: DotNet XmlNode; PartyType: Text; PartyRole: Text; PartyId: Text; PartyName: Text; InterchangeAgreementId: Text; StreetName: Text; PostalCode: Text; CityName: Text; CountryName: Text; PhoneNumber: Text; FaxNumber: Text; Email: Text)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, 'Party', '', '', XMLNode2);
        XMLDOMMgt.AddAttribute(XMLNode2, 'partyType', PartyType);
        XMLDOMMgt.AddAttribute(XMLNode2, 'partyRole', PartyRole);
        XMLDOMMgt.AddElement(XMLNode2, 'partyId', PartyId, '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'partyName', PartyName, '', XMLNode3);
        if InterchangeAgreementId <> '' then
            XMLDOMMgt.AddElement(XMLNode2, 'interchangeAgreementId', InterchangeAgreementId, '', XMLNode3);
        WriteXMLAddress(XMLNode2, StreetName, PostalCode, CityName, CountryName, PhoneNumber, FaxNumber, Email);
    end;

    local procedure WriteXMLAddress(XMLNode: DotNet XmlNode; StreetName: Text; PostalCode: Text; CityName: Text; CountryName: Text; PhoneNumber: Text; FaxNumber: Text; Email: Text)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, 'Address', '', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode2, 'streetName', StreetName, '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'postalCode', PostalCode, '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'cityName', CityName, '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'countryName', CountryName, '', XMLNode3);

        if PhoneNumber <> '' then
            XMLDOMMgt.AddElement(XMLNode2, 'phoneNumber', PhoneNumber, '', XMLNode3);
        if FaxNumber <> '' then
            XMLDOMMgt.AddElement(XMLNode2, 'faxNumber', FaxNumber, '', XMLNode3);
        if Email <> '' then
            XMLDOMMgt.AddElement(XMLNode2, 'e-mail', Email, '', XMLNode3);
    end;

    local procedure WriteXMLFunction(XMLNode: DotNet XmlNode)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, 'Function', '', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode2, 'functionCode', 'O', '', XMLNode3);
    end;

    local procedure WriteXMLCN8(XMLNode: DotNet XmlNode; CNCode: Text)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, 'CN8', '', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode2, 'CN8Code', CNCode, '', XMLNode3);
    end;

    local procedure WriteXMLNatureOfTransaction(XMLNode: DotNet XmlNode; TransactionCode: Text)
    var
        XMLNode2: DotNet XmlNode;
        XMLNode3: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, 'NatureOfTransaction', '', '', XMLNode2);
        XMLDOMMgt.AddElement(XMLNode2, 'natureOfTransactionACode', Format(TransactionCode[1]), '', XMLNode3);
        XMLDOMMgt.AddElement(XMLNode2, 'natureOfTransactionBCode', Format(TransactionCode[2]), '', XMLNode3);
    end;

    local procedure GetCountryCode(CountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        CountryRegion.TestField("Intrastat Code");
        exit(CountryRegion."Intrastat Code");
    end;

    [Scope('OnPrem')]
    procedure GetOriginCountryCode(CountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        if CountryRegion."Intrastat Code" <> '' then
            exit(CountryRegion."Intrastat Code");
        exit(CountryRegionCode);
    end;

    local procedure GetMaterialNumber(): Text
    begin
        if TestIndicator then
            exit('XGTEST');
        exit(CompanyInformation."Company No.");
    end;

    local procedure GetMessageID(StartDate: Date): Text
    begin
        exit(
          GetMaterialNumber() + '-' +
          Format(StartDate, 0, '<Year4><Month,2>') + '-' +
          Format(CreationDate, 0, '<Year4><Month,2><Day,2>') + '-' +
          Format(CreationTime, 0, '<Hours2><Minutes>'));
    end;

    local procedure GetCountryName(CountryRegionCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion.Name);
    end;

    local procedure GetFlowCode(ExportType: Option): Text
    begin
        if ExportType = ExportTypeGlb::Shipment then
            exit('D');
        exit('A');
    end;

    local procedure FormatDecimal(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Precision,0><Standard Format,9>'));
    end;

    local procedure CheckIntrastatContactMandatoryFields()
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
    begin
        case IntrastatSetup."Intrastat Contact Type" of
            IntrastatSetup."Intrastat Contact Type"::Contact:
                begin
                    Contact.Get(IntrastatSetup."Intrastat Contact No.");
                    Contact.TestField(Name);
                    Contact.TestField(Address);
                    Contact.TestField("Post Code");
                    Contact.TestField(City);
                    Contact.TestField("Country/Region Code");
                end;
            IntrastatSetup."Intrastat Contact Type"::Vendor:
                begin
                    Vendor.Get(IntrastatSetup."Intrastat Contact No.");
                    Vendor.TestField(Name);
                    Vendor.TestField(Address);
                    Vendor.TestField("Post Code");
                    Vendor.TestField(City);
                    Vendor.TestField("Country/Region Code");
                end;
        end;
    end;
}

#endif