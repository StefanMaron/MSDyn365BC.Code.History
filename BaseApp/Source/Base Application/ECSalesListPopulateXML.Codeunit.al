namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using System;
using System.Xml;

codeunit 141 "EC Sales List Populate XML"
{

    trigger OnRun()
    begin
    end;

    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        ECSLDeclarationNameSpaceTok: Label 'http://www.govtalk.gov.uk/taxation/vat/europeansalesdeclaration/1', Locked = true;
        ECSLSchemaLocationTok: Label 'http://www.govtalk.gov.uk/taxation/vat/europeansalesdeclaration/1 EuropeanSalesDeclarationRequest.xsd', Locked = true;
        ECSLCoreComponentParamTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CoreComponentParameters-1.0', Locked = true;
        ECSLVATCoreNameSpaceTok: Label 'http://www.govtalk.gov.uk/taxation/vat/core/1', Locked = true;
        XMLSchemaInstanceTok: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        GMSNameSpaceTok: Label 'http://www.govtalk.gov.uk/CM/gms-xs', Locked = true;
        ECSLCurrencyCodeListTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0', Locked = true;
        MonthsTok: Label 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';
        ContactPersonEmptyErr: Label 'A contact person is not specified for your company. This is the person the tax authority will contact. To continue, go to the Company Information page and choose a contact person, and then submit the report again.';
        LCYEmptyErr: Label 'The local currency (LCY) is not specified. To continue, go to the General Ledger Setup page, enter a currency in the LCY Code field, and then submit the report again.';
        GovTalkMessageManagement: Codeunit GovTalkMessageManagement;

    local procedure PopulateXMLHeader(var GovTalkMessageBodyXMLNode: DotNet XmlNode; var BodyNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        ECSLDeclarationRequestXMLNode: DotNet XmlNode;
        ECSLDeclarationHeaderXMLNode: DotNet XmlNode;
        DummyXMLNode: DotNet XmlNode;
    begin
        if not (CompanyInformation.Get() and GeneralLedgerSetup.Get()) then
            exit;

        if GeneralLedgerSetup."LCY Code" = '' then
            Error(LCYEmptyErr);

        if CompanyInformation."Contact Person" = '' then
            Error(ContactPersonEmptyErr);

        XMLDOMManagement.AddElement(GovTalkMessageBodyXMLNode, 'EuropeanSalesDeclarationRequest', '', '', ECSLDeclarationRequestXMLNode);
        AddGovTalkNamespaces(ECSLDeclarationRequestXMLNode);

        XMLDOMManagement.AddElement(ECSLDeclarationRequestXMLNode, 'Header', '', '', ECSLDeclarationHeaderXMLNode);
        XMLDOMManagement.AddElement(ECSLDeclarationRequestXMLNode, 'Body', '', '', BodyNode);

        XMLDOMManagement.AddElementWithPrefix(ECSLDeclarationHeaderXMLNode, 'SubmittersContactName',
          CompanyInformation."Contact Person", 'VATCore', ECSLVATCoreNameSpaceTok, DummyXMLNode);
        AddCurrencyElement(ECSLDeclarationHeaderXMLNode, GeneralLedgerSetup."LCY Code");
        AddPeriodElement(ECSLDeclarationHeaderXMLNode, VATReportHeader);

        XMLDOMManagement.AddElementWithPrefix(ECSLDeclarationHeaderXMLNode, 'ApplyStrictEuropeanSaleValidation',
          'true', 'VATCore', ECSLVATCoreNameSpaceTok, DummyXMLNode);
    end;

    local procedure InsertECSLDeclarationRequestDetails(var EuropeanSalesListBodyNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header"; PartId: Guid)
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        SaleElement: DotNet XmlNode;
        DummyElement: DotNet XmlNode;
        IndicatorVar: Integer;
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetRange("XML Part Id", PartId);
        if ECSLVATReportLine.FindSet() then begin
            repeat
                XMLDOMManagement.AddElement(EuropeanSalesListBodyNode, 'EuropeanSale', '', '', SaleElement);
                XMLDOMManagement.AddElementWithPrefix(SaleElement, 'SubmittersReference', Format(ECSLVATReportLine."Line No."),
                  'VATCore', ECSLVATCoreNameSpaceTok, DummyElement);
                XMLDOMManagement.AddElementWithPrefix(SaleElement, 'CountryCode', ECSLVATReportLine."Country Code", 'VATCore',
                  ECSLVATCoreNameSpaceTok, DummyElement);
                XMLDOMManagement.AddElementWithPrefix(SaleElement, 'CustomerVATRegistrationNumber',
                  GovTalkMessageManagement.FormatVATRegNo(ECSLVATReportLine."Country Code", ECSLVATReportLine."Customer VAT Reg. No."),
                  'VATCore', ECSLVATCoreNameSpaceTok, DummyElement);
                XMLDOMManagement.AddElementWithPrefix(SaleElement, 'TotalValueOfSupplies',
                  Format(ECSLVATReportLine."Total Value Of Supplies", 0, '<Sign><Integer>'), 'VATCore', ECSLVATCoreNameSpaceTok, DummyElement);
                IndicatorVar := ECSLVATReportLine."Transaction Indicator";
                XMLDOMManagement.AddElementWithPrefix(SaleElement, 'TransactionIndicator', Format(IndicatorVar),
                  'VATCore', ECSLVATCoreNameSpaceTok, DummyElement);
            until ECSLVATReportLine.Next() = 0;
        end
    end;

    local procedure GenerateEuropeanSalesDeclarationRequest(var EuropeanSalesListXML: DotNet XmlNode; VATReportHeader: Record "VAT Report Header"; PartId: Guid)
    var
        BodyNode: DotNet XmlNode;
    begin
        PopulateXMLHeader(EuropeanSalesListXML, BodyNode, VATReportHeader);
        InsertECSLDeclarationRequestDetails(BodyNode, VATReportHeader, PartId);
    end;

    local procedure GetMonthCode(MonthNo: Integer): Text
    begin
        exit(SelectStr(MonthNo, MonthsTok));
    end;

    local procedure AddGovTalkNamespaces(var ECSLDeclarationRequestXMLNode: DotNet XmlNode)
    begin
        with XMLDOMManagement do begin
            AddAttribute(ECSLDeclarationRequestXMLNode, 'SchemaVersion', '1.0');
            AddAttributeWithPrefix(ECSLDeclarationRequestXMLNode, 'schemaLocation', 'xsi', XMLSchemaInstanceTok, ECSLSchemaLocationTok);
            AddAttribute(ECSLDeclarationRequestXMLNode, 'xmlns:ccts', ECSLCoreComponentParamTok);
            AddAttribute(ECSLDeclarationRequestXMLNode, 'xmlns:VATCore', ECSLVATCoreNameSpaceTok);
            AddAttribute(ECSLDeclarationRequestXMLNode, 'xmlns', ECSLDeclarationNameSpaceTok);
            AddAttribute(ECSLDeclarationRequestXMLNode, 'xmlns:xsi', XMLSchemaInstanceTok);
            AddAttribute(ECSLDeclarationRequestXMLNode, 'xmlns:n1', GMSNameSpaceTok);
            AddAttribute(ECSLDeclarationRequestXMLNode, 'xmlns:UBLCurrencyCodelist', ECSLCurrencyCodeListTok);
        end;
    end;

    local procedure AddCurrencyElement(var ECSLDeclarationHeaderXMLNode: DotNet XmlNode; CurrencyCode: Code[10])
    var
        DummyXMLNode: DotNet XmlNode;
    begin
        with XMLDOMManagement do begin
            AddElementWithPrefix(ECSLDeclarationHeaderXMLNode, 'CurrencyCode', CurrencyCode, 'VATCore', ECSLVATCoreNameSpaceTok, DummyXMLNode);
            AddAttribute(DummyXMLNode, 'codeListName', 'Currency');
            AddAttribute(DummyXMLNode, 'codeListID', 'ISO 4217 Alpha');
            AddAttribute(DummyXMLNode, 'codeListAgencyName', 'United Nations Economic Commission for Europe');
            AddAttribute(DummyXMLNode, 'codeListSchemeURI', 'urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0');
            AddAttribute(DummyXMLNode, 'codeListURI',
              'http://www.bsi-global.com/Technical%2BInformation/Publications/_Publications/tig90x.doc');
            AddAttribute(DummyXMLNode, 'name', 'String');
            AddAttribute(DummyXMLNode, 'codeListAgencyID', '6');
            AddAttribute(DummyXMLNode, 'codeListVersionID', '0.3');
            AddAttribute(DummyXMLNode, 'languageID', 'en');
        end;
    end;

    local procedure AddPeriodElement(var ECSLDeclarationHeaderXMLNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header")
    var
        DummyXMLNode: DotNet XmlNode;
        ECSLPeriodXMLNode: DotNet XmlNode;
    begin
        with XMLDOMManagement do begin
            if VATReportHeader."Period Type" = VATReportHeader."Period Type"::Month then begin
                AddElementWithPrefix(ECSLDeclarationHeaderXMLNode, 'TaxMonthlyPeriod', '', 'VATCore', ECSLVATCoreNameSpaceTok, ECSLPeriodXMLNode);
                AddElementWithPrefix(ECSLPeriodXMLNode, 'TaxMonth', GetMonthCode(VATReportHeader."Period No."),
                  'VATCore', ECSLVATCoreNameSpaceTok, DummyXMLNode);
                AddElementWithPrefix(ECSLPeriodXMLNode, 'TaxMonthPeriodYear', Format(VATReportHeader."Period Year"),
                  'VATCore', ECSLVATCoreNameSpaceTok, DummyXMLNode);
                exit;
            end;
            if VATReportHeader."Period Type" = VATReportHeader."Period Type"::Quarter then begin
                AddElementWithPrefix(ECSLDeclarationHeaderXMLNode, 'TaxQuarter', '', 'VATCore', ECSLVATCoreNameSpaceTok, ECSLPeriodXMLNode);
                AddElementWithPrefix(ECSLPeriodXMLNode, 'TaxQuarterNumber', Format(VATReportHeader."Period No."), 'VATCore',
                  ECSLVATCoreNameSpaceTok, DummyXMLNode);
                AddElementWithPrefix(ECSLPeriodXMLNode, 'TaxQuarterYear', Format(VATReportHeader."Period Year"), 'VATCore',
                  ECSLVATCoreNameSpaceTok, DummyXMLNode);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetECSLDeclarationRequestMessage(var GovTalkRequestXMLNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header"; PartId: Guid): Boolean
    var
        GovTalkMessageManagement: Codeunit GovTalkMessageManagement;
        BodyXMLNode: DotNet XmlNode;
    begin
        if not GovTalkMessageManagement.CreateBlankGovTalkXmlMessage(
             GovTalkRequestXMLNode, BodyXMLNode, VATReportHeader, 'request', 'submit', true)
        then
            exit(false);
        GenerateEuropeanSalesDeclarationRequest(BodyXMLNode, VATReportHeader, PartId);
        exit(true);
    end;
}

